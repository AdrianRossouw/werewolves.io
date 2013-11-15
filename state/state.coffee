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
_ = require('underscore')

State    = App.module "State",
  startWithParent: false

# singleton map of models to url()
# used for syncing to clients.
State.models = {}

Models.BaseModel::publish = ->
  url = _.result @, 'url'
  State.models[url] = @
  listener = (model) ->
    State.trigger('data', url, model.toJSON())

  State.listenTo @, 'change'

Models.BaseModel::unpublish = ->
  State.stopListening @
  url = _.result @, 'url'
  delete State.models[url]



State.addInitializer (opts) ->
  @world ?= new Models.World()

State.getPlayer = (player) ->
  @world?.game?.players?.get(player)

# Noop implementations of some methods.
State.load = (data = {}) ->
  @world ?= new Models.World(data)
  @trigger 'load', @

State.on 'stop', ->
  # TODO: destroy, not delete
  State.world.destroy()
  delete State.world


module.exports = State
