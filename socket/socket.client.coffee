App           = require('../app')
Socket        = App.module "Socket"
State         = require('../state')
debug         = require('debug')('werewolves:state:client')
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
    debug 'got session data'
    State.session.set data, silent: true

  @io.emit 'data', 'world', (err, data) ->
    debug 'got world data'
    State.load(data)
  
  State.on 'data', (url, model) =>
    debug 'update session'
    @io.emit 'update', url, model if url is sessionUrl

  @io.on 'data', (url, data) ->
    model = State.models[url]
    model.set data if model
    debug "received new data for #{url}"

  @io.on 'state', (url, state) ->
    model = State.models[url]
    model.state().change(state) if model
    debug "received new state #{state} for #{url}"

module.exports = Socket
