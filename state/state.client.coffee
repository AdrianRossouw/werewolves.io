# Client-side application state
#
# Inherits and decorates the shared application state

App = require('../app')
State = require('./state.coffee')
Models = require('../models')
Backbone = require('backbone')

Picky = require('backbone.picky')

Models.Player::initialize = (data={}, opts={}) ->
  selectable = new Backbone.Picky.Selectable @
  _.extend @, selectable

Models.Players::initialize = (data={}, opts={}) ->
  selectOne = new Backbone.Picky.SingleSelect @
  _.extend @, selectOne


State.playerId = window.PLAYER_ID

State.addInitializer (opts) ->
  @session = new Models.Session id: State.playerId

State.getPlayer = ->
  @world?.game?.players?.get(State.playerId)


# TODO: set the world state based on a dump given to us
# TODO: provide mechanisms to apply partial state updates
State.load = (data) ->
  @world = new Models.World(data)
  @trigger 'load', data

###
  @listenTo @world.game.players, 'select:one', (model) =>
    id = @world.game.player.id
    round = @world.game.rounds.last()
    console.log id, model, arguments
    round.choose id, 'lynch', model.id
    console.log id, model
###
module.exports = State
