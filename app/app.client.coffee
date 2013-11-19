# Client-side entry point
# This gets processed with browserify to find straggling dependencies.
App = require('./app.coffee')
Models = require('../models')

Views = require('../views')
_ = require('underscore')
state = require('state')

env = window.NODE_ENV or 'development'
config = require('../config')

# figure out config for the current environment
App.config = ->
  _.extend {}, config.defaults, config[env]

# Anchor libraries.
# We finally include jquery from bower here.
Backbone      = require("backbone")
Marionette    = require("backbone.marionette")
Backbone.$    = Marionette.$ = require("jquery")

if env != 'development'
  require('../voice')

# Load up the state instances
State = require('../state')
App.addInitializer (opts) ->
  @trigger 'before:state', opts
  # We initialize this separately because
  # we don't want it to run just when included
  State.start(opts)
  @trigger 'state', opts

# Load up the state instances
Socket = require('../socket')

$body = $('body')


state App,
  lobby: state 'initial',
    arrive: ->
      $body.addClass('in-lobby')
    exit: ->
      $body.removeClass('in-lobby')
  game:
    arrive: ->
      @gameView.render()
      $body.addClass('in-game')
    exit: ->
      $body.removeClass('in-game')
    admit: ->
      worldState = State.world?.state()?.path()?
      myPlayer = State.world?.session?.player?

      true if myPlayer or (worldState is 'gameplay')


App.addInitializer ->
  @listenTo State, "state", (url, state) ->
    @state().change 'game' if State.isWorld(url)

  # what happens when we join
  @listenTo State, "data", (event, coll, url, state) ->
    @state().change 'game' if (event is 'add') and (coll is 'player')

  @addRegions game: '#game'

  $('.play-now').click -> App.State.joinGame()
  @gameView = new Views.Game el: $('#game')



App.bootstrap = (world) ->
  App.start App.config()
  State.load world
  Socket.start App.config()

  # won't happen if the guards dont admit it
  @state().change('game')

window.App = App
