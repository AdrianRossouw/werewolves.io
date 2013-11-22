debug = require('debug')('werewolves:wolfbots:client')
state = require('state')
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
  initialize: (data, options) ->
    @id = data.id if data.id
    @_state = data._state if data._state

    @initState()
    @state().change(@_state or 'master')

    @publish()

  initState: ->
    state @,
      master:
        debug: (args...) ->
          debug(args...)
        _command: (cmd, args...) ->
          @io 'wolfbot:command', @id, cmd, args...

      slave:
        debug: (args...) ->
          debugStr = "werewolves:wolfbots:#{@id}"
          @io('wolfbot:debug', debugStr, args...)
        _command: (cmd, args...) ->
          @io cmd, args...

  io: (args...) -> Socket.io.emit(args...)

  command: (args...) ->
    dfr = new _.Deferred()
    
    dfr.fail (err, msg) => @debug 'error', err, msg
    dfr.then (results...) => @debug 'command', results...

    @_command args..., (err, results...) =>
      dfr.reject(err, results...) if err
      dfr.resolve(results...) if not err

    dfr.promise()

class Models.Bots extends Models.BaseCollection
  url: 'wolfbot'
  model: Models.Bot



Wolfbots.addInitializer (conf = {}) ->
  State.bots = new Models.Bots []

  @isWolfbot = (url) -> /wolfbot\/.*$/.test(url)

  # initialize the module in master state
  arriveMaster = =>
    console.log "starting in master mode"

    @io = (args...) -> Socket.io.emit args...

    Socket.io.emit 'data', 'wolfbot', (err, data) ->
      State.bots.reset data, silent: true

    @listenTo State, 'data', (event, url, model, data, args...) ->
      if event is 'change' and @isWolfbot(url)
        @io 'update', url, model, args...

      else if url is 'wolfbot'
        @io 'wolfbot:add', data.id if event is 'add'
        @io 'wolfbot:remove', data.id if event is 'remove'

    @listenTo Socket, 'wolfbot:debug', debug

  # initialize the module in slave state
  arriveSlave = =>
    console.log "starting in slave mode"
    @id = conf.id
    @me = State.bots.add id: @id, _state:'slave'

    @listenTo Socket.io, 'wolfbot:command', (id, args...) =>
      @me.command(args...) if id is @id

  # attach a state machine to the module
  state @,
    master:
      arrive: arriveMaster
    slave:
      arrive: arriveSlave

  @mode = conf.mode or 'master'
  @state().change(@mode)



module.exports = Wolfbots
