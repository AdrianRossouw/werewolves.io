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

    @listenTo @, 'change:session', -> @state().change('session')
    @listenTo @, 'change:socket', -> @state().change('socket')
    @listenTo @, 'change:sip', -> @state().change('sip')
    @listenTo @, 'change:voice', -> @state().change('voice')

    Object.defineProperty @, 'player',
      get: -> State.getPlayer()
      set: (value) ->
        player = State.getPlayer()
        player = value
        player

  destroy: ->
    @stopListening @

  setIdentifier: (type, id) ->
    @[type] = id
    # escalate to a higher level
    # guards should make it fall
    # where it can

  initState: -> state @,
    offline: state 'initial'
    online: state 'abstract',
      session: state 'default'
      socket: {}
      sip: {}
      voice: {}

class Models.Sessions extends Backbone.Collection
  model: Models.Session
  defaultSession: -> id: App.ns.uuid()

