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
  socketio.transports = ["websocket"]
  socketUrl = window.SOCKET_URL

  if opts.protocol == 'https'
    @io = socketio.connect(socketUrl, { secure: true })
  else
    @io = socketio.connect(socketUrl)

  sessionUrl = _.result State.session, 'url'
  
  State.on 'choose', (id, target) =>
    @io.emit 'round:action', target

  State.on 'session:sip', (id) =>
    @io.emit 'session:sip', id

  @io.on 'data', (event, url, args...) ->

    data = switch event
      when 'add' then _(args).first(2)
      when 'remove' then _(args).first()
      when 'reset' then _(args).first()
      when 'merge' then _(args).first()
      when 'change' then _(args).first()
      else null

    return null unless data

    # model is always the last argument
    model = State.models[url]
    return null unless model

    switch event
      when 'add'
        model.add _(data).last()
      when 'remove'
        model.remove model.get data
      when 'reset'
        model.reset data
      when 'merge'
        model.set data, merge: true
      when 'change'
        model.set data

    debug "data:#{url}", data...


  @io.on 'state', (url, state) ->
    debug "received new state #{state} for #{url}"
    model = State.models[url]
    model.state().change(state) if model
    model.trigger('state', state) if model

module.exports = Socket
