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
sessionInit = (opts) ->
  cookieParser = new express.cookieParser(opts.secret)

  @io = socketio.listen(App.server)
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
    model = State.models[url]

    return cb(404, {message: 'not found'}) unless model

    model.set data
    cb(null, data)

  socket.on 'update', updateHandler



  socket.on 'disconnect', =>
    if sModel.socket is socket.id
      sModel.voice = false
      sModel.sip = false
      sModel.socket = false

    socket.removeListener 'data', dataHandler
    socket.removeListener 'update', updateHandler

    @trigger 'disconnect', socket, session

Socket.on "connection", onConnection, Socket

###
clientDataStream = (socket, session) ->

joinGame = (socket, session) ->

  listener = (playerId) ->
    State.world.game.addPlayer id: playerId
    debug 'added player'

  socket.on 'game:join', listener
  socket.on 'disconnect', =>
    socket.removeListener 'game:join', listener

  addPlayer = (model) ->
    debug 'emit player added'
    socket.emit 'player:add', model
  State.world.game.players.on 'add', addPlayer

Socket.on "connection", joinGame, Socket

roundListener = (socket, session) ->
  @round = null

  publishAction = (model) ->
    action = _(model).pick 'id', 'action', 'target'
    socket.broadcast.emit 'round:action', action

  subscribeActions = (newRound) =>
    @stopListening @round.actions if @round

    @round = newRound

    @listenTo @round.actions, 'add', publishAction
    @listenTo @round.actions, 'change', publishAction

  @listenTo State.world.game.rounds, 'add', subscribeActions
  subscribeActions State.world.game.rounds.last()

  socket.on 'round:action', (data) =>
    @round.choose data.id, data.action, data.target,
      silent: true

  @on 'disconnect', (socket, session) =>
    socket.removeListener 'round:action', publishAction
Socket.on "connection", roundListener, Socket

###

module.exports = Socket
