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

State.addInitializer (opts) ->
  State.load()

# hide sensitive information from client
Models.World::mask = (session) -> _.pick(@toJSON(), 'id', 'game', '_state')

# hide roles from players, unless they were seen
Models.Player::mask = (session) ->
  result = @toJSON()
  
  # dead roles are known
  return result if @state().is('dead')

  # your own role is known
  player = session.player
  return result if session.id is player?.id

  # otherwise villager is what you get
  result.role = 'villager'

  result


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
