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
    @debug 'initialized'
    @publish()

  io: (args...) -> Socket.io.emit(args...)

  debug: (args...) ->
    debugStr = "werewolves:wolfbots:#{@id}"
    @io('wolfbot:debug', debugStr, args...)

  _command: (cmd, args...) ->
    @debug "doing slave command #{cmd}"
    @io cmd, args...


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
  @io = (args...) -> Socket.io.emit args...

  @isWolfbot = (url) -> /wolfbot\/.*$/.test(url)

  # initialize the module in master state
  arriveMaster = =>
    console.log "starting in master mode"

    @getAll (err, data) ->
      State.bots.reset data, silent: true

    @listenTo Socket, 'wolfbot:debug', debug

  # initialize the module in slave state
  arriveSlave = =>
    console.log "starting in slave mode"
    @id = conf.id
    @me = State.bots.add id: @id

    @listenTo Socket.io, 'wolfbot:command', (id, args...) =>
      @me.command(args...) if id is @id

  # attach a state machine to the module
  state @,
    slave:
      arrive: arriveSlave

    master:
      arrive: arriveMaster
      getAll: (cb) ->
        @io 'data', 'wolfbot', cb

      add: (names...) ->
        _(names).each (n) =>
          @io 'wolfbot:add', n

      command: (name, args...) ->
        name = [name] if !_.isArray(name)
        console.log name
        _(name).map (n) =>
          @io 'wolfbot:command', n, args...

      commandAll: (args...) ->
        @getAll (err, bots) =>
          names = _(bots).pluck('id')
          debug 'command all', names, args...
          @command names, args...

  @mode = conf.mode or 'master'
  @state().change(@mode)



module.exports = Wolfbots
