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

  initialize: (data, options) ->
    @id = data.id if data.id
    @publish()
    @debug = Debug("werewolves:bots:#{@id}")

    @phantom = new _.Deferred()
    @start (err, playerId, ph) =>
      @debug 'wolfbot response', err, playerId

      return @phantom.reject(err) if (err)
      @stateId = playerId
      @phantom.resolve(ph)
  
  stop: ->
    @phantom.then (ph) -> ph.exit()
 
  destroy: ->
    @stop()
    super

  start: (cb) ->
    id = @id
    phantom.create (err, ph) ->
      ph.createPage (err, page) ->
        page.open "http://localhost:8000", (err, status) ->
            work = ->
              App.Wolfbot.start
                id: id
                mode: 'slave'
            error = (err, result) -> cb(err, result, ph)
            page.evaluate work, error

class Models.Bots extends Models.BaseCollection
  url: 'wolfbot'
  model: Models.Bot

Wolfbots.addInitializer (bots) ->
  State.bots ?= new Models.Bots []

  @listenTo Socket, 'connection', (socket, state) ->

    # re-emit debug messages
    socket.on 'wolfbot:debug', (args...) ->
      socket.volatile.emit(args...)

    # re-emit command messages
    # TODO: emit only to a specific bot
    socket.on 'wolfbot:command', (id, args..., cb = ->) ->
      socket.emit(id, args..., cb)

    socket.on 'wolfbot:add', (id, cb = ->) ->
      console.log 'new bot added'
      bot = State.bots.add
        id: id

      cb(null, bot.id)

    socket.on 'wolfbot:remove', (id, cb = ->) ->
      bot = State.bots.get(id)

      state.bots.remove(bots)
      cb(null)

    socket.on 'disconnect', ->
      socket.removeAllListeners('wolfbot:add')
      socket.removeAllListeners('wolfbot:remove')
      socket.removeAllListeners('wolfbot:debug')
      socket.removeAllListeners('wolfbot:command')


module.exports = Wolfbots
