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


State.addInitializer (opts) ->
    
  @world ?= new Models.World()
  @world.sessions ?= new Models.Sessions()
  @world.game = new Models.Game
  @world.game.players = new Models.Players [{id: 'narrator'}]
  @world.game.rounds = new Backbone.Collection [{}],
    model: Models.Round

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
