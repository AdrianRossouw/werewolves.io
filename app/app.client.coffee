# Client-side entry point
# This gets processed with browserify to find straggling dependencies.
App = require('./app.coffee')
Models = require('../models')
Views = require('../views')
debug = require('debug')('werewolves:client')
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
{Filtered}    = require("backbone.projections")

#if window.NODE_ENV != 'development'
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


App.addInitializer ->
  # pity we don't have ui: in the app itself
  @$body = $('body')
  
  @addRegions
    'overlay': '#overlay'
    'game': '#game-area'
    'status': '#status-area'

  @overlay.on 'close', (view) ->
    @$el.removeClass('active')

  @overlay.on 'show', (view) ->
    @$el.addClass('active')
    view.on 'close', ->  App.overlay.close()


  state App,
    lobby: state 'initial',
      arrive: ->
        @$body.addClass('in-lobby')
      exit: ->
        @$body.removeClass('in-lobby')

    game:
      arrive: ->
        player = State.getPlayer()
        players = State.world.game.players
        opponents = new Filtered(players, filter: (p) -> p.id != player.id)
       
        # TODO: dont send things when you are observing
        @listenTo players, 'select:one', (model) ->
          State.choose(player.id, model.id)

        @game.show new Views.Game
          game: State.world.game
          world: State.world
          player: player
          opponents: opponents

        @$body.addClass('in-game')

      exit: ->
        @stopListening State.world.game.players
        @game.close()
        @$body.removeClass('in-game')

      admit:
        '*': ->
          worldState = State.world?.state()?.path()?
          myPlayer = State.world?.session?.player?

          true if myPlayer or (worldState is 'gameplay')

  @activateJoin = ->
    _state = State.world.session.state().path()
    if _state is 'online.call'
      $('.play-now').addClass('active')


  @listenTo State, "state", (url, state) ->
    @activateJoin()

    if State.isWorld(url)
      return @state().change 'lobby' if state == 'attract'
      @state().change 'game'

  # what happens when we join
  @listenTo State, "data", (event, coll, url, state) ->
    @state().change 'game' if (event is 'add') and (coll is 'player')

  $('.play-now').click ->
    session = State.world.session

    return null unless session.state().is 'online.call'

    return App.State.joinGame() if session.name

    App.overlay.show new Views.Session(model:session)


#if env is 'development'
require('../wolfbots')

App.bootstrap = (world) ->
  config = App.config()

  App.start config
  State.load world
  Socket.start config

  @status.show new Views.Status model: State.world

  @trigger 'bootstrap'
  @state().change('game')

  @activateJoin()
window.App = App
