# Server side state
App    = require('../app')
State  = require('./state.coffee')
Models = require('../models')
Backbone = require('backbone')
_ = require('underscore')

# generates useful 'random' values
Nonsense     = require('Nonsense')
ns           = new Nonsense()

Models.Round::_getActions = -> @padVotes()

# Session middleware
express = require('express')

MemoryStore = express.session.MemoryStore

State.addInitializer (opts = {}) ->
  State.sessionStore = new MemoryStore(secret: opts.secret or 'secret')

  @world ?= new Models.World()

  App.listenTo App, 'middleware', (opts) ->
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


module.exports = State
