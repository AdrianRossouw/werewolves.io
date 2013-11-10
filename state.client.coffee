# Client-side application state
#
# Inherits and decorates the shared application state

App = require('./app.coffee')
State = require('./state.coffee')
Models = require('./models.coffee')
Backbone = require('backbone')

# TODO: set the world state based on a dump given to us
# TODO: provide mechanisms to apply partial state updates

State.load = (data) ->
  console.log(JSON.stringify(data, null, 2))
  @world ?= new Models.World()
  @world.game = new Models.Game data.game
  @world.game.players = new Models.Players data.game.players
  @world.game.rounds = new Backbone.Collection data.game.rounds,
    model: Models.Round

  @world.game.player = @world.game.players.at(0)

  @trigger 'load', data

  

module.exports = State
