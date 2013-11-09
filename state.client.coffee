# Client-side application state
#
# Inherits and decorates the shared application state

App = require('./app.coffee')
State = require('./state.coffee')
Models = require('./models.coffee')

# TODO: set the world state based on a dump given to us
# TODO: provide mechanisms to apply partial state updates

App.addInitializer (opts) ->
  @world = new Models.World()

module.exports = State
