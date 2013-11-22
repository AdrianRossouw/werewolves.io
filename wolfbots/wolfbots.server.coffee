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
    console.log 'stopping phantom'
    _.when(@phantom)
      .done( (ph) -> ph.exit() )
      .fail( (err, ph) -> ph.exit() )
 
  destroy: ->
    @stop()
    super

  _start: (id) ->
    App.Wolfbot.start
      id: id
      mode: 'slave'

    fn = -> App.Socket.io.emit('wolfbot:debug', "hello, #{id} here.")
 
    setInterval fn, 1500

  start: (cb = ->) ->
    url = Socket.formatUrl(App.config())
    dfr = new _.Deferred()

    dfr.then(cb.bind(null, null), cb)

    id = @id
    _start = @options.start or @_start
    phantom.create (err, ph) ->
      ph.createPage (err, page) ->
        page.onError = (msg, trace) ->
          msgStack = ["ERROR: " + msg]
          if trace and trace.length
            msgStack.push "TRACE:"
            c.forEach (t) ->
              msg = " -> #{t.file}: #{t.line} "
              msg += " (in function \"#{t.function}\")" if t.function
              msgStack.push msg

          dfr.reject('error', ph, msgStack.join("\n"))

        page.onCallback = (args) ->
          console.log args
          [err, msg] = args
          dfr.reject(err, ph, msg) if err
          dfr.resolve(ph, msg) unless err
        page.onLoadFinished = (status) ->
          err = status != 'success'
          error = (err, result) -> cb(err, result, ph)
          page.evaluateAsync _start, error, id
        console.log url
        page.open url, (err, status) ->
          console.log err, status




    return dfr.promise()

class Models.Bots extends Models.BaseCollection
  url: 'wolfbot'
  model: Models.Bot

Wolfbots.addInitializer (bots) ->
  State.bots ?= new Models.Bots []

  @listenTo Socket, 'connection', (socket, state) ->

    # re-emit debug messages
    socket.on 'wolfbot:debug', (args...) ->
      socket.volatile.emit(args...)
    socket.on 'wolfbot:ping', (args...) ->
      console.log arguments

    socket.on 'wolfbot:command', (id, args..., cb = ->) ->
      socket.broadcast.emit('wolfbot:command', id, args..., cb)

    socket.on 'wolfbot:add', (id, cb = ->) ->
      bot = State.bots.add
        id: id

      cb(null, bot.id)

    socket.on 'wolfbot:remove', (id, cb = ->) ->
      bot = State.bots.get(id)

      State.bots.remove(bots)
      cb(null)

    socket.on 'disconnect', ->
      socket.removeAllListeners('wolfbot:add')
      socket.removeAllListeners('wolfbot:remove')
      socket.removeAllListeners('wolfbot:debug')
      socket.removeAllListeners('wolfbot:command')


module.exports = Wolfbots
