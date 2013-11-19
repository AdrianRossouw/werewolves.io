# Client-side application state
#
# Inherits and decorates the shared application state

App = require('../app')
State = require('./state.coffee')
Models = require('../models')
Backbone = require('backbone')

Picky = require('backbone.picky')


Models.Player::initialize = (data={}, opts={}) ->
  @initState()
  @publish()
  selectable = new Backbone.Picky.Selectable @
  _.extend @, selectable

Models.Players::initialize = (data={}, opts={}) ->
  @publish()
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
  @world?.game?.players?.get(window.PLAYER_ID)

State.load = (data) ->
  @world = new Models.World(data)
  @trigger 'load', data

State.joinGame = ->
  @trigger 'game:join'

###
  @listenTo @world.game.players, 'select:one', (model) =>
    id = @world.game.player.id
    round = @world.game.rounds.last()
    console.log id, model, arguments
    round.choose id, 'lynch', model.id
    console.log id, model
###
module.exports = State
