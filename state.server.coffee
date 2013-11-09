# Server side state
App    = require('./app.coffee')
State  = require('./state.coffee')
Models = require('./models.coffee')

#todo: load/save to redis.
#todo: keep track of sessions.



State.addInitializer (opts) ->
  @world = new Models.World()
  @world.game = new Models.Game()
  @world.sessions = new Models.Sessions()
  

# generates useful 'random' values
Nonsense     = require('Nonsense')
ns           = new Nonsense()


# handle a request (from wherever) for a specific
# connect session id.
#
# Create sessions record if it doesn't exist,
# and merge changes if it does.
State.refreshSession = (sessionId) ->
  session = @callers.findWhere
    session: sessionId

  session ?=
    session: sessionId
    id: ns.uuid()
    name: ns.name()

  @world.sessions.add session,
    merge: true


# Session middleware
express = require('express')
RedisStore   = require('connect-redis')(express)
State.sessionStore = new RedisStore

State.initMiddleware = (opts) ->
  @use new express.cookieParser(opts.secret)
  @use new express.session
    store: State.sessionStore
    secret:opts.secret

  # Register with the sessions collection
  @use (req, res, next) ->
    State.refreshSession req.session.id if req.session


App.on 'middleware', State.initMiddleware, App






module.exports = State
