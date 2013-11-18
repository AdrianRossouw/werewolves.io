phantom = require("node-phantom")
debug = require('debug')('werewolves:wolfbots:server')
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
  @attribute 'owner'
  @attribute 'stateId'

  initialize: (data, options) ->
    @owner = data.owner if data.owner
    @phantom = new _.Deferred()
    @session = new _.Deferred()
    @start (err, playerId, ph) =>
      debug 'wolfbot response', err, playerId

      return @phantom.reject(err) if (err)
      @stateId = playerId
      @phantom.resolve(ph)
  
  stop: ->
    @phantom.then (ph) -> ph.exit()
    
  start: (cb) ->
    phantom.create (err, ph) ->
      ph.createPage (err, page) ->
        page.open "http://localhost:8000", (err, status) ->
            work = -> return window.App
            error = (err, result) -> cb(err, result, ph)
            page.evaluate work, error

class Models.Bots extends Backbone.Collection
  model: Models.Bot

Wolfbots.addInitializer (bots) ->
  @listenTo Socket, 'connection', (socket, state) ->
    # add a bots collection for us to control them via
    state.bots ?= new Models.Bots []
    socket.on 'wolfbot:add', (id, cb = ->) ->

      bot = state.bots.add
        id: id
        owner: state.id
      cb(null, bot.id)

    socket.on 'wolfbot:remove', (id, cb = ->) ->
      state.bots.remove(state.bots.get(id))
      cb(null)


    socket.on 'disconnect', ->
      socket.removeAllListeners('wolfbot:add')


module.exports = Wolfbots
