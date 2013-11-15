App           = require('../app')
Socket        = App.module "Socket"
State         = require('../state')
_             = require('underscore')
url           = require('url')

socketio            = require("socket.io-client")
registerHandlers = (opts) ->
  ###
  @round = null

  publishAction = (model) ->
    action = _(model).pick 'id', 'action', 'target'
    @io.emit 'round:action', action

  subscribeActions = (newRound) =>
    @stopListening @round.actions if @round

    @round = newRound

    @listenTo @round.actions, 'add', publishAction
    @listenTo @round.actions, 'change', publishAction

  @listenTo State.world.game.rounds, 'add', subscribeActions
  subscribeActions State.world.game.rounds.last()

  @io.on 'round:action', (data) =>
    @round.choose data.id, data.action, data.target

  ###

  State.world.game.on 'game:join', =>
    @io.emit 'game:join'

  @io.on 'player:add', (player) =>
    State.world.game.players.add player
  @io.on 'game:state', (state) ->
    State.world.game.toState(state)


  ###
  @io.on 'player:state', (id, state) ->
    State.world.game.players.get(id).toState(state)
  ###

State.on 'load', registerHandlers, Socket


Socket.addInitializer (opts) ->
  socketio.transports = ["websocket"]
  socketUrl = url.format _.pick(opts, 'hostname', 'protocol', 'port')

  if opts.protocol == 'https'
    @io = socketio.connect(socketUrl, { secure: true })
  else
    @io = socketio.connect(socketUrl)


  sessionUrl = _.result State.session, 'url'

  @io.emit 'data', sessionUrl, (err, data) ->
    console.log 'got session data'
    State.session.set data, silent: true

  @io.emit 'data', 'world', (err, data) ->
    console.log 'got world data'
    State.load(data)
  
  State.on 'data', (url, model) =>
    console.log 'update session'
    @io.emit 'update', url, model if url is sessionUrl



module.exports = Socket
