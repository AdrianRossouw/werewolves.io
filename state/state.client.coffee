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

# TODO: set the world state based on a dump given to us
# TODO: provide mechanisms to apply partial state updates

State.load = (data) ->
  @world ?= new Models.World(data)
 
  @world.playerId = data.playerId

  @world.game.player = @world.game.players.first()

  @listenTo @world.game.players, 'select:one', (model) =>
    id = @world.game.player.id
    round = @world.game.rounds.last()
    console.log id, model, arguments
    round.choose id, 'lynch', model.id
    console.log id, model

  @trigger 'load', data

module.exports = State
