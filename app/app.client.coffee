# Client-side entry point
# This gets processed with browserify to find straggling dependencies.
App = require('./app.coffee')
Models = require('../models')

Views = require('../views')
_ = require('underscore')

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

App.showGame = ->
  # we must have a good reason to show it, right?
  @gameView.render()
  $body.removeClass('in-lobby').addClass('in-game')

App.hideGame = ->
  $body.addClass('in-lobby').removeClass('in-game')

App.worldHandler =  ->
  state = State.world.state().path()
  if (state is 'gameplay') or State.session.player
    @showGame()
  else
    @hideGame()

App.listenTo State, "state", (url, state) ->
  @worldHandler() if State.isWorld(url)

App.listenTo State, 'load', ->
  @addRegions
    game: '#game'

  playNow = ->
    App.showGame()
    App.State.joinGame()

  $('.play-now').click playNow

  @gameView = new Views.Game el: $('#game')

  @worldHandler()

App.bootstrap = (world) ->
  App.start App.config()
  State.load world

window.App = App
