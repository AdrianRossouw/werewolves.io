# Client-side application state
#
# Inherits and decorates the shared application state

App = require('./app.coffee')
State = require('./state.coffee')
Models = require('./models.coffee')

# TODO: set the world state based on a dump given to us
# TODO: provide mechanisms to apply partial state updates

State.load = (data) ->
   
  @world ?= new Models.World()
  @world.sessions ?= new Models.Sessions()
  @world.game = new Models.Game data.startup
  @world.game.players = new Models.Players data.startup.players

  @player = @world.game.players.at(0)
  @trigger 'load', data

  

module.exports = State
