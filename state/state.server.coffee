# Server side state
App    = require('../app')
State  = require('./state.coffee')
Models = require('../models')
Backbone = require('backbone')
_ = require('underscore')

# generates useful 'random' values
Nonsense     = require('Nonsense')
ns           = new Nonsense()


#todo: load/save to redis.
#todo: keep track of sessions.

fixture = require('../test/fixture/game1.coffee')
State.addInitializer (opts) ->
  # just for now
  @world ?= new Models.World()
  

# hide sensitive information from client
Models.World::mask = ->
  _.pick(@toJSON(), 'game', '_state')



# Session middleware
express              = require('express')
RedisStore           = require('connect-redis')(express)
State.sessionStore   = new RedisStore

State.initMiddleware = (opts) ->
  @use new express.cookieParser(opts.secret)
  @use new express.session
    store: State.sessionStore
    secret: opts.secret
  @use (req, res, next) =>
    return next() if req.url != '/'
    session = State.world.sessions.findWhere session:req.session.id
    session = State.world.sessions.add {} if not session
   
    session.setIdentifier 'session', req.session.id
    req.state =
      session: session
    next()


App.on 'middleware', State.initMiddleware, App

module.exports = State
