phantom = require("node-phantom")
Debug = require('debug')
debug = Debug('werewolves:wolfbots:server')
_ = require('underscore')
Backbone = require('backbone')

App = require('../app')
State = App.module "State"
Models = App.module "Models"
Socket = App.module "Socket"
Wolfbots = App.module "Wolfbots",
  startWithParent: false

#require('./bots.client.coffee')
class Models.Bot extends Models.BaseModel
  urlRoot: 'wolfbot'
  @attribute 'stateId'

  initialize: (data, options = {}) ->
    @id = data.id if data.id
    @publish()
    @options ?= options

    @debug = Debug("werewolves:wolfbots:#{@id}")

    @phantom = @start()
    this
  
  stop: ->
    debug 'phantom', 'stopping'
    _.when(@phantom)
      .done( (ph) -> ph.exit() )
      .fail( (err, ph, msg) =>
        debug("#{@id}:phantom:error", msg)
        ph.exit() )
 
  destroy: ->
    @stop()
    super

  _start: (id) ->
    Socket = App.Socket
    
    App.Socket.io.emit('wolfbot:debug', "hello, #{id} here.")
    App.Wolfbots.start
      id: id
      mode: 'slave'



  start: (cb = ->) ->
    debug "starting #{@id}"
    url = Socket.formatUrl(App.config())
    dfr = new _.Deferred()

    dfr.then(cb.bind(null, null), cb)

    id = @id
    _start = @options.start or @_start
    phantom.create (err, ph) ->
      ph.createPage (err, page) ->
        page.onError = (msg, trace) ->
          msgStack = [msg]
          if trace and trace.length
            msgStack.push "TRACE:"
            c.forEach (t) ->
              msg = " -> #{t.file}: #{t.line} "
              msg += " (in function \"#{t.function}\")" if t.function
              msgStack.push msg

          dfr.reject('error', ph, msgStack.join("\n"))

        page.onCallback = (args) ->
          [err, msg] = args
          dfr.reject(err, ph, msg) if err
          dfr.resolve(ph, msg) unless err

        page.onLoadFinished = (status) ->
          err = status != 'success'
          error = (err, result) ->
          page.evaluateAsync _start, error, 0, id

        page.open url, (err, status) ->




    return dfr.promise()

class Models.Bots extends Models.BaseCollection
  url: 'wolfbot'
  model: Models.Bot

Wolfbots.addInitializer (bots) ->
  debug 'starting up'
  State.bots ?= new Models.Bots []

  @listenTo Socket, 'connection', (socket, state) ->

    # re-emit debug messages
    socket.on 'wolfbot:debug', (args...) ->
      debug args...
      socket.volatile.emit('wolfbot:debug', args...)


    socket.on 'wolfbot:command', (id, args..., cb = ->) ->
      debug "wolfbot:command:#{id}", args
      socket.broadcast.emit('wolfbot:command', id, args..., cb)

    socket.on 'wolfbot:add', (id, cb = ->) ->
      debug 'wolfbot:add', id

      bot = State.bots.add
        id: id

      cb(null, bot.id)

    socket.on 'wolfbot:remove', (id, cb = ->) ->
      debug 'wolfbot:remove', id
      bot = State.bots.get(id)

      bot.stop().then ->
        State.bots.remove(bot)
        cb(null)

    socket.on 'disconnect', ->
      socket.removeAllListeners('wolfbot:add')
      socket.removeAllListeners('wolfbot:remove')
      socket.removeAllListeners('wolfbot:debug')
      socket.removeAllListeners('wolfbot:command')


module.exports = Wolfbots
