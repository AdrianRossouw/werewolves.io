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


# hide sensitive information from client
Models.World::mask = (session) ->
  world = _.pick(@toJSON(), 'id', 'game', '_state', 'sessions', 'timer')
  world.sessions = _(world.sessions).where id: session.id
  world

# hide roles from players, unless they were seen
Models.Player::mask = (session) ->
  result = @toJSON()

  # dead players roles are known
  return result if @state().is('dead')

  # your own role is known
  player = State.getPlayer(session.id)
  return result if player?.id == @id

  # werewolves get other wolves
  if player?.role == 'werewolf'
    return result if @role == 'werewolf'

  # seers get anyone they have seen before.
  if (player?.role == 'seer')
    seen = player?.seen or []
    return result if @id in seen

  # villagers get nothing else.
  result.role = 'villager'
  return result



Models.Sessions::mask = (session) ->
  _(@toJSON()).where id: session.id

Models.Session::mask = (session) ->
  @toJSON() if @id is session.id

# Session middleware
express              = require('express')
#CouchStore           = require('connect-couchdb')(express)
#State.sessionStore   = new CouchStore
#  name: "werewolves-sessions"
#  reapInterval: 600000
#  compactInterval: 300000
#  setThrottle: 60000

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
