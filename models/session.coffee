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
  urlRoot: 'session'
  @attribute 'session'
  @attribute 'socket'
  @attribute 'sip'
  @attribute 'voice'
  initialize: (data={}, opts={}) ->
    @id = data.id or App.ns.uuid()

    super
    @state().change(data._state or 'offline')

    @publish()
    @listenTo @, 'change:session', -> @state().change('session')
    @listenTo @, 'change:socket', -> @state().change('socket')
    @listenTo @, 'change:sip', -> @state().change('sip')
    @listenTo @, 'change:voice', -> @state().change('voice')

    Object.defineProperty @, 'player',
      get: -> State.getPlayer(@id)
      set: (value) ->
        player = State.getPlayer(@id)
        player = value
        player

  destroy: ->
    @stopListening @

  setIdentifier: (type, id) ->
    @[type] = id

  initState: -> state @,
    offline: state 'initial'
    online: state 'abstract',
      session: state 'default',
        release:
          offline: -> !@owner.session
          socket: -> @owner.session
      socket:
        admit:
          offline: -> @owner.socket
          session: -> @owner.socket
          sip: -> @owner.socket
        release:
          sip: -> @owner.socket
          session: -> !@owner.socket
      sip:
        admit:
          socket: -> @owner.sip
          voice: -> @owner.sip
        release:
          voice: -> @owner.sip
          socket: -> !@owner.sip
      voice:
        admit:
          sip: -> @owner.voice
        release:
          sip: -> !@owner.voice

class Models.Sessions extends Models.BaseCollection
  url: 'session'
  model: Models.Session

