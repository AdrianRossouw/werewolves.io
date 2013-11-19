debug = require('debug')('werewolves:wolfbots:client')
_ = require('underscore')
Backbone = require('backbone')

App = require('../app')
State = App.module "State"
Models = App.module "Models"
Socket = App.module "Socket"
Wolfbots = App.module "Wolfbots",
  startWithParent: false

class Models.Bot extends Models.BaseModel
  urlRoot: 'wolfbot'
  @attribute 'stateId'
  initialize: (data, options) ->
    @id = data.id if data.id
    @publish()

  debug: (args...) ->
    if @mode is 'master'
      debug(args...)
    else
      debugStr = "werewolves:wolfbots:#{@id}" 
      @io('wolfbot:debug', debugStr, args...)

  io: (args...) -> Socket.io.emit(args...)

  command: (args...) ->
    dfr = new _.Deferred()
    
    dfr.fail (err, msg) => @debug 'error', err, msg
    dfr.then (results...) => @debug 'command', results...

    @_command args..., (err, results...) =>
      dfr.reject(err, results...) if err
      dfr.resolve(results...) if not err

    dfr.promise()

  _command: (cmd, args...) ->
    @debug 'running command', cmd
    if @mode is 'master'
      @io 'wolfbot:command', @id, cmd, args...
    else
      @io args...

class Models.Bots extends Models.BaseCollection
  url: 'wolfbot'
  model: Models.Bot

Wolfbots.addInitializer (conf = {}) ->
  State.bots = new Models.Bots []

  @isWolfbot = (url) -> /wolfbot\/.*$/.test(url)

  @mode = conf.mode or 'master'
  
  if @mode is 'master'
     console.log "starting in master mode"

     @io = (args...) -> Socket.io.emit args...

     # catch all botst log messages
     Socket.io.emit 'data', 'wolfbot', (err, data) ->
       State.bots.reset data, silent: true


     @listenTo State, 'data', (event, url, model, data, args...) ->

       if event is 'change' and @isWolfbot(url)
         @io 'update', url, model, args...

       else if url is 'wolfbot'
         @io 'wolfbot:add', data.id if event is 'add'
         @io 'wolfbot:remove', data.id if event is 'remove'

     @listenTo Socket, 'wolfbot:debug', debug

  else
    console.log "starting in slave mode"
    @id = conf.id
    @me = State.bots.add

    @listenTo Socket, 'wolfbot:command', (id, args...) ->
      @me.command(args...) if id is @id
  

module.exports = Wolfbots
