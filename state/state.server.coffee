# Server side state
App    = require('../app')
State  = require('./state.coffee')
Models = require('../models')
Backbone = require('backbone')

# generates useful 'random' values
Nonsense     = require('Nonsense')
ns           = new Nonsense()


#todo: load/save to redis.
#todo: keep track of sessions.

fixture = require('../test/fixture/game1.coffee')
State.addInitializer (opts) ->
  # just for now
  @world = new Models.World(fixture)
  


# Session middleware
express              = require('express')
RedisStore           = require('connect-redis')(express)
State.sessionStore   = new RedisStore

State.initMiddleware = (opts) ->
  @use new express.cookieParser(opts.secret)
  @use new express.session
    store: State.sessionStore
    secret: opts.secret

App.on 'middleware', State.initMiddleware, App

module.exports = State
