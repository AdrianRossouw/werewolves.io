# Client-side entry point
# This gets processed with browserify to find straggling dependencies.
App = require('./app.coffee')
Models = require('./models.coffee')


Views = require('./views.coffee')
_             = require('underscore')


# figure out config for the current environment
_conf = require('./config.client.coffee')
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


if env != 'development'
  require('./voice.client.coffee')


# Load up the state instances
State = require('./state.client.coffee')
App.addInitializer (opts) ->
  @trigger 'before:state', opts
  # We initialize this separately because
  # we don't want it to run just when included
  State.start(opts)

# Load up the state instances
Socket = require('./socket.client.coffee')

loader = (opts) ->
  @addRegions
    game: '#game'

  $body = $('body')

  playNow = ->
    $body.removeClass('in-lobby').addClass('in-game')
    App.State.world.game.joinGame(App.State.world.playerId)

  $('.play-now').click playNow

  #$body.addClass 'in-lobby'

  @gameView = new Views.Game el: $('#game')
  @gameView.render()
 
State.on 'load', loader, App

App.start(conf)
