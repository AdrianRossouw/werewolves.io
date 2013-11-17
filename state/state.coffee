# State machine instances
#
# This module will manage the instances of the
# data models in the game world.
#
# The IO layer will listen for changes from
# this module, and views will manipulate it
# from the interface.
App      = require("../app")
Backbone = require('backbone')
Models   = require('../models')
debug    = require('debug')('werewolves:state')
_ = require('underscore')

State    = App.module "State",
  startWithParent: false

# Test functions to determine what to sync
State.isPlayer = (url) -> /player\/.*$/.test(url)
State.isSession = (url) -> /session\/.*$/.test(url)
State.isAction = (url) -> /action\/.*$/.test(url)
State.isGame = (url) -> /game\/.*$/.test(url)
State.isRound = (url) -> /round\/.*$/.test(url)

# singleton map of models to url()
# used for syncing to clients.
State.models = {}

Models.BaseModel::publish = ->
  url = _.result @, 'url'
  State.models[url] = @
  debug "model",  url
  #State.trigger('data', 'model', url, @toJSON())

  listener = (model) ->
    debug "change", url
    State.trigger('data', 'change', url, model)

  State.listenTo @, 'change', listener

  ## the state listeners
  listenState = (state) ->
    path = state.path().replace(/\.$/, '')
    debug path, url
    State.trigger('state', url, path)

  if @state
    states = @state('**')
    _(states).each (s) -> s.on 'arrive', listenState

Models.BaseCollection::publish = ->
  url = _.result @, 'url'

  State.models[url] = @
  debug "collection",  url
  State.trigger('data', 'collection', url, @toJSON())

  addListener = (model) ->
    mUrl = _.result model, 'url'
    debug "add", url, mUrl
    State.trigger('data', 'add', url, mUrl, model)

  removeListener = (model) ->
    mUrl = _.result model, 'url'
    debug "remove", url, mUrl
    State.trigger('data', 'remove', url, mUrl, model)

  resetListener = (collection) ->
    debug "reset", url
    State.trigger('data', 'reset', url, collection)


  State.listenTo @, 'add', addListener
  State.listenTo @, 'remove', removeListener
  State.listenTo @, 'reset', resetListener



Models.BaseModel::unpublish = ->
  State.stopListening @
  url = _.result @, 'url'

  states = @state('**')
  #_(states).each (s) -> s.off 'arrive'

  delete State.models[url]


State.getPlayer = (player) ->
  @world?.game?.players?.get(player)

State.getSession = (session) ->
  @world?.sessions?.get(session)


# Noop implementations of some methods.
State.load = (data = {}) ->
  @world = new Models.World(data)
  @trigger 'load', @

State.addFinalizer ->
  @off()
  State.world.destroy()
  delete State.world
  State.models = {}



module.exports = State
