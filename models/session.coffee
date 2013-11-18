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

    @listenTo @, 'change', @findState


    Object.defineProperty @, 'player',
      get: -> State.getPlayer(@id)
      set: (value) ->
        player = State.getPlayer(@id)
        player = value
        player

  # attempt all the possible states in order
  findState: ->
    @state().change('offline')
    @state().change('session')
    @state().change('socket')
    @state().change('sip')
    @state().change('voice')

  destroy: ->
    @stopListening @

  setIdentifier: (type, id) ->
    @[type] = id

  initState: ->
    state @,
      offline: state 'initial'
      online: state 'abstract',
        session: state 'default',
          admit: (from) ->
            console.log from
            true if @owner.session
          release: true
        socket:
          deps: -> true if @socket

          admit:
            offline: state.bind @deps
            session: state.bind @deps
            sip: state.bind @deps
          release:
            sip:  state.bind @deps
            session: state.bind -> !@owner.deps()
        sip:
          deps: -> true if @socket and @sip
          admit:
            offline:  state.bind @deps
            socket:  state.bind @deps
            voice:  state.bind @deps
          release:
            voice:  state.bind @deps
            socket: state.bind -> !@owner.deps()
        voice:
          deps: -> true if @socket and @sip and @voice
          admit:
            offline:  state.bind @deps
            sip:  state.bind @deps
          release:
            sip: state.bind -> !@owner.deps()

class Models.Sessions extends Models.BaseCollection
  url: 'session'
  model: Models.Session

