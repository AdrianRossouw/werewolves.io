App       = require('../app')
State     = require('../state')
express   = require('express')
socketio  = require("socket.io")
SessionIo = require("session.socket.io")
debug     = require('debug')('werewolves:socket:server')
_         = require('underscore')
Models    = App.module "Models"

Socket    = App.module "Socket",
  startWithParent: false

Models.Sessions::findSocket = (id) ->
  State.world.sessions.findWhere socket:id

Models.Sessions::touchSocket = (socket, sess) ->
  session = @touchSession(sess) if sess
  session ?= @findSocket(socket.id)
  session ?= @add {}
  session.socket = socket.id
  session


# Initialize the socket.io library, with the
# session handler wrapper.
Socket.addInitializer (opts) ->
  @listenTo App, 'listen', (opts = {}) ->
    cookieParser = new express.cookieParser(opts.secret)
    opts.socket ?=
      log: false

    @io = socketio.listen(App.server, opts.socket)
    @io.set("destroy upgrade",false)

    @sio = new SessionIo @io, State.sessionStore, cookieParser
    @sio.on 'connection', (err, socket, sess) =>
      state = State.world.sessions.touchSocket socket, sess
      @trigger 'connection', socket, state

      socket.on 'disconnect', =>
        if state.socket is socket.id
          state.voice = false
          state.sip = false
          state.socket = false

Socket.formatUrl = (opts) ->
  return opts.socketUrl if opts.socketUrl
  url   = require('url')
  parts = _.pick(opts, 'hostname', 'protocol', 'port')
  _.defaults parts,
    hostname: 'localhost'
    protocol: 'http'
    port: 8000
    
  url.format parts


# Incoming requests from the client
Socket.addInitializer (opts) ->

  # when a new socket connection is made
  @listenTo @, 'connection', (socket, state) ->

    #Straight forward data query by the client.
    # TODO: remove this now that we bootstrap?
    # it's still useful for bots though...
    socket.on 'data', (url, cb = ->) ->
      debug "request #{url}"
      model = State.models[url]
      return cb(404, {message: 'not found'}) unless model
      cb(null, model.mask(state))
   

    # a modification of data from the client.
    socket.on 'update', (url, data, cb = ->) ->
      debug "update", url, data
      model = State.models[url]
      return cb(404, {message: 'not found'}) unless model
      model.set data
      cb(null, data)


    # allow players to join
    socket.on 'game:join', (cb=->) ->
      player = State.world.game.addPlayer(id: state.id)
      return cb(500, {message: 'unknown error'}) if not player
      cb(null, player)

    # allow players to pick one of the currently active players.
    socket.on 'round:action', (target, cb=->) ->
      round = State.world.game.currentRound()
      result = round?.choose(state.id, target)
      return cb(403, {message: 'denied'}) if not result
      return cb(null, 'ok')

    # remove all the listeners on this socket
    socket.on 'disconnect', =>
      socket.removeAllListeners 'data'
      socket.removeAllListeners 'update'
      socket.removeAllListeners 'game:join'
      socket.removeAllListeners 'round:action'



# outgoing broadcasts from the server to the client
Socket.addInitializer (opts) ->
  @stateMask = (url, state, session) ->
    true unless State.isSession(url) and (session.getUrl() != url)

  # when a new socket connection is made
  @listenTo @, 'connection', (socket, session) ->

    @listenTo State, 'data', (event, args...) =>
      if event is 'change'
        [url, model] = args
        mask = model.mask(session)
        debug('data:change', url, mask)
        socket.emit 'data', 'change', url, mask if mask

      else if event is 'add'
        [cUrl, url, model] = args
        mask = model.mask(session)
        debug('data:add', cUrl, url, mask)
        socket.emit 'data', 'add', cUrl, url, mask if mask

      else if event is 'reset'
        [url, collection] = args
        mask = collection.mask(session)
        debug('data:reset', url, mask)
        socket.emit 'data', 'reset', url, mask if mask

      else if event is 'remove'
        [cUrl, url, model] = args
        mask = model.mask(session)
        debug('data:remove', cUrl, url, mask)
        socket.emit 'data', 'remove', cUrl, url if mask

    @listenTo State, 'state', (url, newState) ->
      allow = @stateMask url, newState, session

      socket.emit 'state', url, newState if allow


Socket.addFinalizer (opts) ->
  @off()

module.exports = Socket
