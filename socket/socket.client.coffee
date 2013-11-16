App           = require('../app')
Socket        = App.module "Socket"
State         = require('../state')
debug         = require('debug')('werewolves:state:client')
_             = require('underscore')
url           = require('url')

socketio            = require("socket.io-client")
registerHandlers = (opts) ->
  State.on 'game:join', =>
    @io.emit 'game:join'

# on the client side we only care about our session
State.isSession = (url) ->
  url is _.result State.session, 'url'

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
  
  State.on 'data', (event, url, model) =>
    debug 'update session'

    @io.emit 'update', url, model if State.isSession(url)

  @io.on 'data', (event, url, args...) ->
    debug 'data', arguments
    if event is 'add'
      [mUrl, data] = args
      coll = State.model[url]
      coll.add data
      debug "added #{mUrl} to #{url}"

    if event is 'remove'
      [mUrl, data] = args
      coll = State.model[url]
      coll.remove coll.get url
      debug "removes #{mUrl} from #{url}"

    if event is 'change'
      [data] = args
      model = State.models[url]
      model.set data if model
      debug "received new data for #{url}"

  @io.on 'state', (url, state) ->
    model = State.models[url]
    model.state().change(state) if model
    debug "received new state #{state} for #{url}"

module.exports = Socket
