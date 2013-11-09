# Client side state
State = require('./state.coffee')

# Model definitions
Models = require('./models.coffee')

#todo: load/save to redis.
#todo: keep track of sessions.

State.addInitializer (opts) ->
  @world = new Models.World()

module.exports = State
