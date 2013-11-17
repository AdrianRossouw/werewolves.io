App       = require('../app')
State     = require('../state')
express   = require('express')
socketio  = require("socket.io")
SessionIo = require("session.socket.io")
debug     = require('debug')('werewolves:state:server')
_         = require('underscore')
Socket    = App.module "Socket"
Models    = App.module "Models"

Models.Sessions::findSocket = (id) ->
  State.world.sessions.findWhere socket:id

Models.Sessions::touchSocket = (socket, sess) ->
  session = @touchSession(sess) if sess
  session ?= @findSocket(socket.id)
  session ?= @add {}
  session.socket ?= socket.id
  session


# Initialize the socket.io library, with the
# session handler wrapper.
sessionInit = (opts = {}) ->
  cookieParser = new express.cookieParser(opts.secret)

  opts.socket ?= {}

  @io = socketio.listen(App.server, opts.socket)
  @io.set("destroy upgrade",false)

  @sio = new SessionIo @io, State.sessionStore, cookieParser
  @sio.on 'connection', (err, socket, sess) =>
    state = State.world.sessions.touchSocket socket, sess

    @trigger 'connection', socket, state

App.on "listen", sessionInit, Socket


onConnection = (socket, state) ->

  #Straight forward data query by the client.
  dataHandler = (url, cb = ->) ->
    debug "request #{url}"
    model = State.models[url]

    return cb(404, {message: 'not found'}) unless model

    cb(null, model.mask(state))
 
  socket.on 'data', dataHandler

  # a modification of data from the client.
  updateHandler = (url, data, cb = ->) ->
    debug "update #{url}"
    model = State.models[url]

    return cb(404, {message: 'not found'}) unless model

    model.set data
    cb(null, data)

  socket.on 'update', updateHandler

  Socket.listenTo State, 'data', (event, args...) =>
    if event is 'change'
      [url, model] = args

      socket.emit 'data', 'change', url, model.mask(state)
    else if event is 'add'
      [cUrl, url, model] = args
      socket.emit 'data', 'add', cUrl, url, model.mask(state)
    else
      socket.emit 'data', args...

  Socket.listenTo State, 'state', (args...) =>
    socket.emit 'state', args...

  socket.on 'disconnect', =>
    if sModel.socket is socket.id
      sModel.voice = false
      sModel.sip = false
      sModel.socket = false

    socket.removeListener 'data', dataHandler
    socket.removeListener 'update', updateHandler

    @trigger 'disconnect', socket, session

Socket.on "connection", onConnection, Socket

joinGame = (socket, session) ->

  listener = (cb=->) ->
    player = State.world.game.addPlayer(id: session.id)

    return cb(500, {message: 'unknown error'}) if not player

    cb(null, player)


  socket.on 'game:join', listener
  socket.on 'disconnect', =>
    socket.removeListener 'game:join', listener

Socket.on "connection", joinGame, Socket

module.exports = Socket
