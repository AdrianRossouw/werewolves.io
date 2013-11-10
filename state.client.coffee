# Client-side application state
#
# Inherits and decorates the shared application state

App = require('./app.coffee')
State = require('./state.coffee')
Models = require('./models.coffee')
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
  @world ?= new Models.World()
  @world.game = new Models.Game data.game
  @world.game.players = new Models.Players data.game.players
  @world.game.rounds = new Backbone.Collection data.game.rounds,
    model: Models.Round

  @world.game.player = @world.game.players.at(0)

  @listenTo @world.game.players, 'select:one', (model) =>
    id = @world.game.player.id
    round = @world.game.rounds.last()
    console.log id, model, arguments
    round.choose id, 'lynch', model.id
    console.log id, model

  @trigger 'load', data


module.exports = State
