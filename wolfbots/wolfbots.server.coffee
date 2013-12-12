Debug = require('debug')
debug = Debug('werewolves:wolfbots:server')
_ = require('underscore')
Backbone = require('backbone')
socketio = require("socket.io-client")

App = require('../app')
State = App.module "State"
Models = App.module "Models"
Socket = App.module "Socket"
Wolfbots = App.module "Wolfbots",
  startWithParent: false

class Models.Bot extends Models.BaseModel
  urlRoot: 'wolfbot'

  initialize: (data, options = {}) ->
    @options ?= options
    @socket = @start()
    @
  
  stop: ->
    @io.disconnect()
 
  destroy: ->
    @stop()
    super

  start: (cb = ->) ->
    dfr = new _.Deferred()
    dfr.then(cb.bind(null, null), cb)


    @io = socketio.connect Wolfbots.socketUrl, 'force new connection': true
    @io.on 'connect', ->
      dfr.resolve()

    dfr.promise()

  command: (command, args..., cb = ->) ->
    debug "bot #{@id} command", command
    dfr = new _.Deferred()
    dfr.then(cb.bind(null, null), cb)

    emitFn = (err, result) ->
      return dfr.reject(err) if err
      dfr.resolve(result)

    _.when(@socket).then =>
      @io.emit(command, args..., emitFn)

    dfr.promise()

class Models.Bots extends Models.BaseCollection
  url: 'wolfbot'
  model: Models.Bot
  publish: ->

Wolfbots.addInitializer (config) ->
  @bots = new Models.Bots []

  @socketUrl = Socket.formatUrl(config)

  @listenTo Socket, 'connection', (socket, state) ->
    socket.on 'wolfbot:add', (id, cb = ->) =>
      debug('add', id)
      bot = @bots.add id: id
      cb(null, bot.id)

    socket.on 'wolfbot:remove', (id, cb = ->) =>
      debug('remove', id)
      bot = @bots.get(id)
      @bots.remove(bot) if bot
      cb(null)

    socket.on 'wolfbot:command', (id, args..., cb = ->) =>
      debug('command', id, args...)
      bot = @bots.get(id)
      return cb(403, {message: 'no such bot'}) if !bot
      bot.command(args..., cb)

    socket.on 'wolfbot:command:all', (args..., cb = ->) =>
      debug('command:all', args...)
      _.when(@bots.invoke('command', args...)).then(cb.bind(null, null), cb)
      cb(null)

    socket.on 'disconnect', ->
      socket.removeAllListeners('wolfbot:add')
      socket.removeAllListeners('wolfbot:remove')
      socket.removeAllListeners('wolfbot:command')
      socket.removeAllListeners('wolfbot:command:all')

Wolfbots.addFinalizer ->
  debug('finalizer')
  @bots.destroy()
  delete @bots
  @stopListening()
  @off()

module.exports = Wolfbots

