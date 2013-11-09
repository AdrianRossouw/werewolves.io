# Client-side application state
#
# Inherits and decorates the shared application state

App = require('./app.coffee')
State = require('./state.coffee')

# TODO: set the world state based on a dump given to us
# TODO: provide mechanisms to apply partial state updates

module.exports = State
