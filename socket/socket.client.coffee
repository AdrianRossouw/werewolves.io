App           = require('../app')
Socket        = App.module "Socket",
  startWithParent: false
State         = require('../state')
debug         = require('debug')('werewolves:socket:client')
_             = require('underscore')
url           = require('url')

socketio            = require("socket.io-client")
registerHandlers = (opts) ->
  State.on 'game:join', =>
    @io.emit 'game:join'


State.on 'load', registerHandlers, Socket
Socket.addInitializer (opts) ->
  @isSession = (url) -> url is State.world.session.getUrl()

  socketio.transports = ["websocket"]
  socketUrl = window.SOCKET_URL

  if opts.protocol == 'https'
    @io = socketio.connect(socketUrl, { secure: true })
  else
    @io = socketio.connect(socketUrl)

  sessionUrl = _.result State.session, 'url'
  
  State.on 'data', (event, url, model) =>
    debug 'update session'
    @io.emit 'update', url, model.toJSON() if @isSession(url)

  State.on 'choose', (id, target) =>
    @io.emit 'round:action', target

  @io.on 'data', (event, url, args...) ->
    debug 'data', arguments
    if event is 'add'
      [mUrl, data] = args
      coll = State.models[url]
      return debug 'collection not found', url if !coll

      debug "adding #{mUrl} to #{url}"
      record = coll.add data
      record.state().change(data._state) if data._state
      record.trigger('state', data._state)


    if event is 'remove'
      [mUrl] = args
      coll = State.models[url]
      return debug 'collection not found', url if !coll

      debug "data:remove", url, mUrl
      coll.remove coll.get url

    if event is 'change'
      [data] = args
      model = State.models[url]
      return debug 'model not found', url if !model

      debug "data:change", url, data
      model.set data if model

    if event is 'reset'
      [data] = args
      coll = State.models[url]
      debug "data:reset", url, data
      return debug 'collection not found', url if !coll

      debug "removes #{mUrl} from #{url}"
      coll.reset data


  @io.on 'state', (url, state) ->
    debug "received new state #{state} for #{url}"
    model = State.models[url]
    model.state().change(state) if model
    model.trigger('state', state) if model

module.exports = Socket
