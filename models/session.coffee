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

class Models.Session extends Models.BaseModel
  # session identifiers
  @attribute 'session'
  @attribute 'socket'
  @attribute 'sip'
  @attribute 'voice'
  initialize: ->
    super
    Object.defineProperty @, 'player',
      get: -> State.getPlayer()
      set: (value) ->
        player = State.getPlayer()
        player = value
        player

  initState: -> state @,
    offline: state 'initial'
    online: state 'abstract',
      session: {}
      socket: {}
      sip: {}
      voice: {}

class Models.Sessions extends Backbone.Collection
  model: Models.Session
  defaultSession: -> id: App.ns.uuid()

  findBySessionId: (sessionId) ->
    @findWhere session: sessionId
  findBySocketId: (socketId) ->
    @findWhere socket: socketId
  findBySipID: (sipId) ->
    @findWhere sip: sipId

  refreshSession: (sessionId) ->
    model = @findBySessionId sessionId
    if not model
      model = @defaultSession()
      model = @add model, merge: true

    model.state('-> online.session')
    model.session = sessionId
    return model

  refreshSocket: (socketId) ->
    model = @findBySocketId socketId
    if not model
      model = @defaultSession()
      model = @add model, merge: true

    model.state('-> online.socket')
    model.socket = socketId
    return model

  refreshSip: (sipId) ->
    model = @findBySipId sipId
    if not model
      model = @defaultSession()
      model = @add model, merge: true

    model.state('-> online.sip')
    model.sip = sipId
    return model
