App           = require('../app')
Socket        = App.module "Socket",
  startWithParent: false
State         = require('../state')
debug         = require('debug')('werewolves:state:client')
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
      if coll
        record = coll.add data
        record.state().change(data._state) if data._state
        record.trigger('state', data._state)

        debug "added #{mUrl} to #{url}"

    if event is 'remove'
      [mUrl, data] = args
      coll = State.models[url]
      if coll
        coll.remove coll.get url
        debug "removes #{mUrl} from #{url}"

    if event is 'change'
      [data] = args
      model = State.models[url]
      if model
        model.set data if model
        debug "received new data for #{url}"

  @io.on 'state', (url, state) ->
    debug "received new state #{state} for #{url}"
    model = State.models[url]
    model.state().change(state) if model
    model.trigger('state', state) if model

module.exports = Socket
