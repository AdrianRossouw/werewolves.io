# Shared model code.
#
# These form the base agreed upon data structures that will be extended
# by the front-end and/or backend.
App = require('./app.coffee')
Backbone = require('backbone')
_ = require('underscore')
state = require('state')
Models = App.module "Models"

# generates useful 'random' values
Nonsense     = require('Nonsense')
ns           = new Nonsense()


# Create model attribute getter/setter property.
# From : http://srackham.wordpress.com/2011/10/16/getters-and-setters-for-backbone-model-attributes/
class BaseModel extends Backbone.Model
  _attributes: []
  toState: (state) ->
    @state('-> %{state}')
    @triggerState state

  triggerState: (state) ->
    @trigger 'state', state

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
  defaultSession: -> id: ns.uuid(),

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


# A player who has joined an active or upcoming
# game.
class Models.Player extends BaseModel
  @attribute 'session'
  @attribute 'name'
  @attribute 'role'
  @attribute 'living'
  @attribute 'occupation'

  triggerState: (state) ->
    @trigger @id, state, living

  initialize: ->
    super
    @set('name', ns.name()) unless @name
    @set('occupation', ns.jobTitle()) unless @occupation
    @set('role', 'villager') unless @villager
    @set('timeAdded', Date.now())

  state s = @::,
    lobby: state, 'initial'
    spectacte: state
    dead: state
    alive: state
      lynching: state
      seeing: state
      eating: state
      sleeping: state

getRoles = (numPlayers) ->
  #werewolf, seer, villager
  # rules:
  # < 12: 2
  # < 18: 3
  # 18: 4

  roles = ['seer', 'werewolf', 'werewolf']
  if numPlayers > 11
    roles.push 'werewolf'
  if numPlayers > 17
    roles.push 'werewolf'

  while roles.length < numPlayers
    roles.push 'villager'

  roles = _.shuffle roles
  roles

class Models.Players extends Models.Sessions
  model: Models.Player

  assignRoles: ->
    roles = getRoles(@length)
    @each (player) ->
      player.set('role', roles.shift())

# A game that is running or will be starting.
class Models.Game extends BaseModel
  @attribute 'players'
  @attribute 'startTime'
  @attribute 'rounds'
  @attribute 'phaseTime'
  state s = @::,
    phaseAction: -> console.log('phase action')
    wolvesWin: ->
      wolves = @players.where role:'werewolf'
      villagers = @players.filter (m) -> m.role is 'villager' or 'seer'

    recruit: state 'initial',
      nextPhase: ->
        @trigger('state', 'round.night.first')
        @state('-> round.night.first')
      addRound: ->
        @rounds.add {}
        @trigger('state', 'round:add')
      startGame: ->
<<<<<<< HEAD
        if process.env.NODE_ENV != 'production'
          minPlayerLimit = 3
        else
          minPlayerLimit = 7

=======
>>>>>>> parent of 3cce697... stuff
        if App.isServer
          checkStart = ->
            thirtySecondsLast = _(players).max (m) -> (m.timeAdded - 20000)
            waitMore = (@players.length > 7) and (thirtySecondsLast < Date.now())
            if (not waitMore) or @players.length = 16
              @nextPhase()

          _.debounce checkStart, 30000
          
      joinGame: ->  @trigger 'game:join'
    round: state 'abstract',
      night: state 'abstract',
        first: state
          nextPhase: ->
            @state('-> round.day.first')
            @trigger('state', 'round.day.first')
        next: state
          nextPhase: ->
            @state('-> round.day.next')
            @trigger('state', 'round.day.next')

      day: state 'abstract',
        first: state
          nextPhase: () ->
            @toState('round.night.next')
        next: state
          nextPhase: () ->
            @state('-> round.night.first')


    victory: state 'abstract',
      wolves: state
      villagers: state
    cleanup: state 'final'
    endRound:  ->
        if App.isServer
          checkRound = ->
            thirtySecondsLast = _(players).max (m) -> m.timeCast
            waitMore = (thirtySecondsLast < (Date.now() - 150000))
            if (not waitMore)
              @phaseAction()

              if @wolvesWin()
                @toState('victory.wolves')
              else if @villagersWin()
                @toState('victory.villagers')
              else
                @nextPhase()
              
          _.debounce checkRound, 152000



class Models.Action extends BaseModel
  @attribute 'action'
  @attribute 'target'
  @attribute 'timeCast'

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

    if not action
      action ?=
        id:me
        action:actionName
        target:target
        timeCast: Date.now()

      @actions.add action, opts
    else
      action.target = target
      action.timeCast= Date.now()

    _.debounce State.world.game.endRound, 150000
    

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
