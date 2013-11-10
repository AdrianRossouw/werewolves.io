# Shared model code.
#
# These form the base agreed upon data structures that will be extended
# by the front-end and/or backend.
App = require('./app.coffee')
Backbone = require('backbone')
state = require('state')
Models = App.module "Models"

# generates useful 'random' values
Nonsense     = require('Nonsense')
ns           = new Nonsense()


# Create model attribute getter/setter property.
# From : http://srackham.wordpress.com/2011/10/16/getters-and-setters-for-backbone-model-attributes/
class BaseModel extends Backbone.Model
  _attributes: []

  initialize: (attrs = {}, options = {}) ->
    @initAttribute attr, val for val, attr in attrs

  initAttribute: (attr, value) ->
    @set(attr, value)

  @attribute = (attr) ->
    @_attributes ?= []
    @_attributes.push attr
    Object.defineProperty @prototype, attr,
      get: -> @get attr
      set: (value) ->
        attrs = {}
        attrs[attr] = value
        @set attrs


# Singular representation of all the various
# contact mechanisms available.
#
# We are multi-plexed over REST/WSS/SIP/Tropo,
# so we need to handle cases like multiple tabs etc.
#
# Sessions might or might not be listening in to the
# current game.
class Models.Session extends BaseModel
  state s = @::,
    offline: state 'initial'
    online: state
      socket: state
      sip: state
      voice: state

class Models.Sessions extends Backbone.Collection
  model: Models.Session
  refreshSession: (sessionId) ->
    model = @findWhere session: sessionId
    model ?= id: ns.uuid(), name: ns.name()
    model = @add model, merge: true
    model.session = sessionId
    return model

  refreshSocket: (sessionId, socketId) ->
    model = @refreshSession(sessionId)
    model.sockets ?= []
    if socketId not in model.sockets
      model.sockets.push(socketId)
    return model

# A player who has joined an active or upcoming
# game.
class Models.Player extends BaseModel
  @attribute 'session'
  @attribute 'name'
  @attribute 'role'
  @attribute 'living'
  @attribute 'occupation'

  initialize: ->
    super
    @set('id', ns.uuid()) unless @id
    @set('occupation', ns.jobTitle()) unless @occupation

  state s = @::,
    lobby: state, 'initial'
    spectacte: state
    dead: state
    alive: state
      lynching: state
      seeing: state
      eating: state
      sleeping: state


class Models.Players extends Models.Sessions
  model: Models.Player

# A game that is running or will be starting.
class Models.Game extends BaseModel
  @attribute 'players'
  @attribute 'startTime'
  @attribute 'rounds'
  @attribute 'phaseTime'
  state s = @::,
    recruit: state 'initial',
      startGame: -> @state('-> startup')
    startup: state
      nextPhase: -> @state('-> night')
    day: state 'abstract',
      first: state
      next: state

      # methods
      nextPhase: -> @state('-> night')
      transitions:
        FirstDay:
          origin: 'night.first'
          action: ->
            debugger
            console.log 'the first day breaks'
        DayBreak:
          origin: 'night'
          action: ->
            debugger
            console.log 'day breaks'

    night: state 'abstract',
      first: state
      next: state

      # methods
      nextPhase: -> @state('-> day')
      transitions:
        FirstNight:
          origin: 'startup'
          action: ->
            debugger
            console.log 'first night falls'
        NightFall:
          origin: 'day'
          action: ->
            debugger
            console.log 'night falls'

    victory: state 'abstract',
      wolves: state
      villagers: state
    cleanup: state 'final'
    transitions:
      StartGame: origin: 'recruit', target: 'startup', action: ->
        console.log "game started"


class Models.Action extends BaseModel
  @attribute 'action'
  @attribute 'target'

class Models.Round extends BaseModel
  @attribute 'death'
  @attribute 'phase'
  initialize: (data = {}, opts = {}) ->
    @actions ?= new Backbone.Collection [],
      model: Models.Action
    data.actions ?= []
    @actions.add data.actions

  toJSON: ->
    obj = super
    obj.actions = @actions.toJSON()
    obj

  choose: (me, actionName, target, opts = {}) ->
    action = @actions.findWhere
      id:me
      action:actionName

    action ?=
      id:me
      action:actionName
      target:target

    _.extend opts, merge: true

    @actions.add action, opts
    

class Models.Rounds extends Backbone.Collection

# The world acts as the container for the other
# pieces of state.
class Models.World extends BaseModel
  @attribute 'game'
  @attribute 'sessions'
  state s = @::,
    attract: state 'initial'
    gameplay: state

module.exports = Models
