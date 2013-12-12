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
    @publish()
    @trigger('state', @state().path())
    @listenTo @, 'change', @upgrade

    Object.defineProperty @, 'player',
      get: -> State.getPlayer(@id)
      set: (value) ->
        player = State.getPlayer(@id)
        player = value
        player

  toJSON: (session) ->
    json = super
    return json unless session

    return json if @id is session.id

  destroy: ->
    @stopListening @

  upgrade: ->
    before = @state().path()
    @state().emit 'upgrade'
    @upgrade() if before != @state().path()

  initState: ->
    state @,
      offline: state 'initial',
        upgrade: state.bind ->
          if @owner.session
            @be 'session'
          else if @owner.socket
            @be 'socket'

      online: state 'abstract',
        session: state
          upgrade: 'socket'
          admit:
            offline: -> true if @owner.session
        socket:
          upgrade: 'sip'
          admit:
            'offline,session': -> true if @owner.socket
        sip:
          upgrade: 'voice'
          admit:
            'socket,offline': -> true if (@owner.sip && @owner.socket)
        voice:
          admit:
            'sip,offline': -> true if (@owner.voice && @owner.sip && @owner.socket)

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
