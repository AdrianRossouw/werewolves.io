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

# Initialize the socket.io library, with the
# session handler wrapper.
Socket.addInitializer (opts) ->
  @listenTo App, 'listen', (opts = {}) ->
    sessions = State.world?.sessions

    cookieParser = new express.cookieParser(opts.secret)
    opts.socket ?= log: true

    @io = socketio.listen(App.server, opts.socket)
    @io.set("destroy upgrade",false)

    @sio = new SessionIo @io, State.sessionStore, cookieParser
    @sio.on 'connection', (err, socket, _session) =>
      session = sessions.touchSocket socket, _session
      socket.join('game')

      @trigger 'connection', socket, session

      socket.on 'disconnect', ->
        session.removeSocket socket.id

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
      cb(null, model.maskJSON(state))

    # a modification of data from the client.
    socket.on 'update', (url, data, cb = ->) ->
      debug "update", url, data
      model = State.models[url]
      return cb(404, {message: 'not found'}) unless model
      model.set data
      cb(null, data)

    # add a sip address registered against this socket
    socket.on 'session:sip', (id, cb = ->) ->
      state.addSip(socket.id, id)
      cb(null)

    # add a sip address registered against this socket
    socket.on 'session:call', (cb = ->) ->
      state.addCall(socket.id)
      cb(null)

    # set the username to use for the whole session 
    socket.on 'session:name', (name, cb = ->) ->
      state.name = name
      cb(null, state.name)

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
      socket.removeAllListeners 'session:sip'
      socket.removeAllListeners 'game:join'
      socket.removeAllListeners 'round:action'

# outgoing broadcasts from the server to the client
Socket.addInitializer (opts) ->
  @listenTo State, 'state', (url, _state) ->
    sessions = State.world.sessions
    return null unless sessions

    _(@io.sockets.clients('game')).each (socket) ->
      session = sessions.findSocket socket.id
      return null unless session

      model = State.models[url]
      return null unless model

      mask = model.maskState(session, _state)
      return null unless mask

      socket.emit 'state', url, mask
      debug "state:#{socket.id}", url, mask

Socket.addInitializer (opts) ->
  @listenTo State, 'data', (event, args...) ->
    sessions = State.world?.sessions
    return null unless sessions

    _(@io.sockets.clients('game')).each (socket) ->
      session = sessions.findSocket socket.id
      return null unless session

      applyArgs = switch event
        when 'add' then _(args).first(3)
        when 'remove' then _(args).first(2)
        when 'reset' then _(args).first(2)
        when 'merge' then _(args).first(2)
        when 'change' then _(args).first(2)
        else null

      # not a handled event
      return null unless applyArgs

      # model is always the last argument
      model = applyArgs.pop()
      return null unless model

      # conditionally filter out data events
      return null if model.filterData(session, event)

      # mask the JSON being sent to the client
      maskJSON = model.maskJSON(session)
      return null unless maskJSON
      applyArgs.push(maskJSON)

      socket.emit 'data', event, applyArgs...
      debug "data:#{event}:#{socket.id}", applyArgs...

Socket.addFinalizer (opts) ->
  @off()

module.exports = Socket
