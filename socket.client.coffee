App           = require('./app.coffee')
Socket        = App.module "Socket"
State         = require('./state.client.coffee')
_             = require('underscore')
url           = require('url')

# SocketIO library (browserified.. yay)
socketio            = require("socket.io-client")

Socket.addInitializer (opts) ->
  socketio.transports = ["websocket"]
  socketUrl = url.format _.pick(opts, 'hostname', 'protocol', 'port')

  if opts.protocol == 'https'
    @io = socketio.connect(socketUrl, { secure: true })
  else
    @io = socketio.connect(socketUrl)
  @io.on 'world:state', (data) =>
    State.load data

registerHandlers = (opts) ->
  @round = null

  publishAction = (model) ->
    action = _(model).pick 'player', 'action', 'target'
    @io.emit 'round:action', action

  @listenTo State.world.game.rounds, 'add', (newRound) =>
    @stopListening @round.actions if @round

    @round = newRound

    @listenTo @round.actions, 'add', publishAction
    @listenTo @round.actions, 'change', publishAction

  @io.on 'round:action', (data) =>
    @round.choose data.player, data.action, data.target

State.on 'load', registerHandlers, Socket

module.exports = Socket
