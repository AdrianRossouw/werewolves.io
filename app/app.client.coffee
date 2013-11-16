# Client-side entry point
# This gets processed with browserify to find straggling dependencies.
App = require('./app.coffee')
Models = require('../models')


Views = require('../views')
_ = require('underscore')


# figure out config for the current environment
_conf = require('../config')
conf    = {}
env     = window.NODE_ENV
env    ?= 'development'

_.defaults conf, _conf[env], _conf.defaults

window.App = App

# Anchor libraries.
# We finally include jquery from bower here.
Backbone      = require("backbone")
Marionette    = require("backbone.marionette")
Backbone.$    = Marionette.$ = require("jquery")


#if env != 'development'
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
  $body.removeClass('in-lobby').addClass('in-game')

App.hideGame = ->
  $body.addClass('in-lobby').removeClass('in-game')

App.listenTo State, "state", (url, state) ->
  if url is world
    if (state is 'gameplay') or State.session.player
      @showGame()
    else
      @hideGame()

loader = (opts) ->
  @addRegions
    game: '#game'

  playNow = ->
    App.showGame()
    App.State.joinGame()

  $('.play-now').click playNow

  #$body.addClass 'in-lobby'

  @gameView = new Views.Game el: $('#game')
  @gameView.render()
 
State.on 'load', loader, App

App.start(conf)
