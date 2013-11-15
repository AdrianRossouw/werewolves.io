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

    Object.defineProperty @, 'player',
      get: -> State.getPlayer()
      set: (value) ->
        player = State.getPlayer()
        player = value
        player

  setIdentifier: (type, id) ->
    @[type] = id
    # escalate to a higher level
    # guards should make it fall
    # where it can
    @state().change(type)

  initState: -> state @,
    offline: state 'initial'
    online: state 'abstract',
      session: state 'default',
        admit:
          offline: true
          socket: true
      socket:
        admit:
          session: true
          sip: true
      sip:
        admit:
          socket: true
          voice: true
      voice:
        admit:
          sip: true

class Models.Sessions extends Backbone.Collection
  model: Models.Session
  defaultSession: -> id: App.ns.uuid()

