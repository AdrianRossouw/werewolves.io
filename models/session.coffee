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

    @state().change(data._state or 'offline')

    @listenTo @, 'change', @upgrade

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

  toState: (nextState) ->
    state.bind ->
      next = @query(nextState)
      # check if we meet the requirements
      if next.call 'allow'
        @go nextState
        next.call 'upgrade'
      else if not @owner.allow()
        console.log 'hello?'
        next.call 'downgrade'

  initState: ->
    state @,
      upgrade: ->
      downgrade: ->
      offline: state 'initial',
        allow: -> true
        upgrade: @toState 'session'
      online: state 'abstract',
        session: state 'default',
          downgrade: @toState 'offline'
          upgrade: @toState 'socket'
          allow: -> true
        socket:
          upgrade: @toState 'sip'
          downgrade: @toState 'session'
          allow: -> true if @socket
        sip:
          upgrade: @toState 'voice'
          downgrade: @toState 'socket'
          allow: -> true if @socket and @sip
        voice:
          allow: -> true if @socket and @voice and @sip
          downgrade: @toState 'sip'



class Models.Sessions extends Models.BaseCollection
  url: 'session'
  model: Models.Session

