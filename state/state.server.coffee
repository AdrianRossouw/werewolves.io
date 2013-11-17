# Server side state
App    = require('../app')
State  = require('./state.coffee')
Models = require('../models')
Backbone = require('backbone')
_ = require('underscore')

# generates useful 'random' values
Nonsense     = require('Nonsense')
ns           = new Nonsense()

Models.Sessions::findSession = (id) ->
  State.world.sessions.findWhere session:id

Models.Sessions::touchSession = (sess) ->
  session = @findSession(sess.id)
  session ?= @add {}
  session.session = sess.id
  session

fixture = require('../test/fixture/game1.coffee')
State.addInitializer (opts) ->  @world ?= new Models.World()

# hide sensitive information from client
Models.World::mask = (session) -> _.pick(@toJSON(), 'id', 'game', '_state')


# Session middleware
express              = require('express')
RedisStore           = require('connect-redis')(express)
State.sessionStore   = new RedisStore

State.initMiddleware = (opts) ->
  @use new express.cookieParser(opts.secret)
  @use new express.session
    store: State.sessionStore
    secret: opts.secret

  # finds the state instance for this sentence
  # and attaches it to the middleware so we can
  # print it in the layout.
  @use (req, res, next) =>
    return next() if req.url != '/'

    _sessions = State.world.sessions
    session = _sessions.touchSession(req.session)
    req.state = session: session
    next()


App.on 'middleware', State.initMiddleware, App

module.exports = State
