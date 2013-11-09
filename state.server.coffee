# Server side state
App    = require('./app.coffee')
State  = require('./state.coffee')
Models = require('./models.coffee')

# generates useful 'random' values
Nonsense     = require('Nonsense')
ns           = new Nonsense()


#todo: load/save to redis.
#todo: keep track of sessions.

fixture = require('./test/fixture/game1.coffee')

State.addInitializer (opts) ->
  State.load(fixture)
  @trigger 'load', opts, @

# Session middleware
express              = require('express')
RedisStore           = require('connect-redis')(express)
State.sessionStore   = new RedisStore

State.initMiddleware = (opts) ->
  @use new express.cookieParser(opts.secret)
  @use new express.session
    store: State.sessionStore
    secret: opts.secret

  # Register with the sessions collection
  @use (req, res, next) ->
    State.world.sessions.refreshSession req.session.id if req.session
    next()


App.on 'middleware', State.initMiddleware, App


module.exports = State
