App       = require('../app')
State     = require('../state')
express   = require('express')
socketio  = require("socket.io")
SessionIo = require("session.socket.io")
debug     = require('debug')('werewolves:state:server')
_         = require('underscore')
Socket    = App.module "Socket"

# Initialize the socket.io library, with the
# session handler wrapper.
sessionInit = (opts = {}) ->
  cookieParser = new express.cookieParser(opts.secret)

  opts.socket ?= {}

  @io = socketio.listen(App.server, opts.socket)
  @io.set("destroy upgrade",false)

  @sio = new SessionIo @io, State.sessionStore, cookieParser
  @sio.on 'connection', (err, args...) =>
    if err
      return @trigger 'error', err

    @trigger 'connection', args...

App.on "listen", sessionInit, Socket


onConnection = (socket, session) ->
  sModel = State.world.sessions.findWhere session:session.id
  sModel = State.world.sessions.add {} if not sModel
 
  sModel.setIdentifier 'session', session.id
  if not sModel.socket
    sModel.setIdentifier 'socket', socket.id


  #Straight forward data query by the client.
  dataHandler = (url, cb = ->) ->
    debug "request #{url}"
    model = State.models[url]

    return cb(404, {message: 'not found'}) unless model

    cb(null, model.mask())
 
  socket.on 'data', dataHandler

  # a modification of data from the client.
  updateHandler = (url, data, cb = ->) ->
    debug "update #{url}"
    console.log arguments
    model = State.models[url]

    return cb(404, {message: 'not found'}) unless model

    model.set data
    cb(null, data)

  socket.on 'update', updateHandler

  Socket.listenTo State, 'data', (args...) =>
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
  sModel = State.world.sessions.findWhere session:session.id
  sModel = State.world.sessions.add {} if not sModel

  listener = (cb=->) ->
    debug 'added player'
    State.world.game.addPlayer(id: sModel.id)
    cb(null, sModel)

  socket.on 'game:join', listener
  socket.on 'disconnect', =>
    socket.removeListener 'game:join', listener

Socket.on "connection", joinGame, Socket

module.exports = Socket
