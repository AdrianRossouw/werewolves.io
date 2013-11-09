# Server side state
App    = require('./app.coffee')
State  = require('./state.coffee')
Models = require('./models.coffee')

#todo: load/save to redis.
#todo: keep track of sessions.

State.addInitializer (opts) ->
  @world = new Models.World()

# Loading up and populating the initial game world
express = require('express')
RedisStore   = require('connect-redis')(express)
State.sessionStore = new RedisStore

State.initMiddleware = (opts) ->
  @use new express.cookieParser(opts.secret)
  @use new express.session
    store: State.sessionStore
    secret:opts.secret

App.on 'middleware', State.initMiddleware, App

module.exports = State
