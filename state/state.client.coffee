# Client-side application state
#
# Inherits and decorates the shared application state

App = require('../app')
State = require('./state.coffee')
Models = require('../models')
Backbone = require('backbone')

Picky = require('backbone.picky')


Models.Player::initClient = (data={}, opts={}) ->
  selectable = new Backbone.Picky.Selectable @
  _.extend @, selectable

Models.Players::initClient = (data={}, opts={}) ->
  selectOne = new Backbone.Picky.SingleSelect @
  _.extend @, selectOne


class Models.World extends Models.World
  initialize: ->
    super

    Object.defineProperty @, 'session',
      get: -> State.getSession(window.PLAYER_ID)
      set: (value) ->
        session = State.getSession(window.PLAYER_ID)
        session.set(value)
        session


State.playerId = window.PLAYER_ID

State.getPlayer = ->
  player = @world?.game?.players?.get(window.PLAYER_ID)

  # fallback for spectators
  if @world.state().is('gameplay')
    player ?= @world.game?.players?.first()
 
  player

State.load = (data) ->
  @world = new Models.World(data)
  @trigger 'load', data

State.joinGame = ->
  @trigger 'game:join'

State.choose = (id, target) ->
  @trigger 'choose', id, target

State.addSip = (id) ->
  @trigger 'session:sip', id

module.exports = State
