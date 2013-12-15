# Singular representation of all the various
# contact mechanisms available.
#
# We are multi-plexed over REST/WSS/SIP/Tropo,
# so we need to handle cases like multiple tabs etc.
#
# Sessions might or might not be listening in to the
# current game.

App      = require('../app')
state    = require('state')
Backbone = require('backbone')
Models   = App.module "Models"
State    = App.module "State"
_ = require('underscore')

class Models.Session extends Models.BaseModel
  # session identifiers
  urlRoot: 'session'
  @attribute 'session'
  @attribute 'socket'
  @attribute 'sip'
  @attribute 'voice'
  initialize: (data={}, opts={}) ->
    @id = data.id or App.ns.uuid()
    super

    @socket = data.socket or []
    @sip = data.sip or {}

    @state().change(data._state or 'offline')
    @publish()
    @trigger('state', @state().path())
    @listenTo @, 'change', @updateState

    Object.defineProperty @, 'player',
      get: -> State.getPlayer(@id)
      set: (value) ->
        player = State.getPlayer(@id)
        player = value
        player

  # adds a connection to the session object
  addSession: (id) ->
    @session ?= id

  removeSession: (id) ->
    @session = false if @session is id

  # each session can only have one active voice
  addVoice: (id) ->
    @voice ?= id

  removeVoice: (id) ->
    @voice = false if @voice is id

  # each session can have multiple sockets
  hasSocket: -> _(@socket).size()
  addSocket: (id) ->
    return null if id in @socket

    socket = _(@socket).clone()
    socket.push(id)
    @socket = socket

  removeSocket: (id) ->
    return null unless id in @socket

    socket = _(@socket).clone()
    @socket = _(socket).without id

  # each socket can only have one sip id
  hasSip: -> _(@sip).size()
  addSip: (socket, sip) ->
    return null if @sip[socket]

    _sip = _(@sip).clone()
    _sip[socket] = sip
    @sip = _sip

  removeSip: (socket) ->
    return null unless @sip[socket]

    _sip = _(@sip).clone()
    delete _sip[socket]
    @sip = _sip


  toJSON: (session) ->
    json = super
    return json unless session

    json if @id is session.id

  maskState: (session, _state) ->
    return _state unless session

    _state if @id is session.id

  destroy: ->
    @stopListening @

  updateState: -> @upgrade() or @downgrade()
  initState: ->
    state @,
      downgrade: ->
      upgrade: ->
      offline: state 'initial',
        upgrade: ->
          if @socket.length
            @go 'socket'
          else if @session
            @go 'session'

      online: state 'abstract',
        session: state
          arrive: -> @updateState()
          upgrade: -> @go 'socket' if @socket.length
          downgrade: -> @go 'offline' if !@session
        socket:
          arrive: -> @updateState()
          upgrade: -> @go 'sip' if _(@sip).size()
          downgrade: -> @go 'session' if !@socket.length
        sip:
          arrive: -> @updateState()
          upgrade: -> @go 'voice' if @voice
          downgrade: -> @go 'socket' if !_(@sip).size()
        voice:
          arrive: -> @updateState()
          downgrade: -> @go 'sip' if !@voice

class Models.Sessions extends Models.BaseCollection
  url: 'session'
  model: Models.Session
  toJSON: (session) ->
    json = super
    return json unless session

    _(json).chain()
        .compact()
        .where(id: session.id)
        .value()
