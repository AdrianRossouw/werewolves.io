App       = require('./app.coffee')
State     = require('./state.server.coffee')
express   = require('express')
socketio  = require("socket.io")
SessionIo = require("session.socket.io")
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

    console.log('whores')
    @trigger 'connection', args...

App.on "listen", sessionInit, Socket

onConnection = (socket, session) ->
  model = State.world.sessions.refreshSocket socket.id
 
  obj = State.world.toJSON()
  obj.playerId = model.id

  socket.emit('world:state', _(obj).pick 'game', 'playerId')

  socket.on 'disconnect', =>

    @trigger 'disconnect', socket, session

joinGame = (socket, session) ->
  model = State.world.sessions.findBySocketId(socket)
  listener = ->
    State.world.game.players.add id:model.id

  socket.on 'game:join', listener
  socket.on 'disconnect', =>
    socket.removeListener 'game:join', listener

  addPlayer = (model) -> socket.emit 'player:add', model


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

Socket.on "connection", onConnection, Socket
Socket.on "connection", joinGame, Socket
Socket.on "connection", roundListener, Socket

module.exports = Socket
