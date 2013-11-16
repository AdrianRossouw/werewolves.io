App      = require('../app')
state    = require('state')
_        = require('underscore')
debug    = require('debug')('werewolves:model:player')
Backbone = require('backbone')
Models   = App.module "Models"

getRoles = (numPlayers) ->
  #werewolf, seer, villager
  # rules:
  # < 12: 2
  # < 18: 3
  # 18: 4

  roles = ['seer', 'werewolf']
  if numPlayers > 8
    roles.push 'werewolf'
  if numPlayers > 11
    roles.push 'werewolf'
  if numPlayers > 17
    roles.push 'werewolf'

  while roles.length < numPlayers
    roles.push 'villager'

  roles = _.shuffle roles
  roles

# A player who has joined an active or upcoming
# game.
class Models.Player extends Models.BaseModel
  urlRoot: 'player'
  @attribute 'name'
  @attribute 'role'
  @attribute 'occupation'

  initialize: (data={}, opts={}) ->
    @id = @id or App.ns.uuid()
    super
    @set('name', App.ns.name()) unless @name
    @set('occupation', App.ns.jobTitle()) unless @occupation
    @set('role', 'villager') unless @villager
    @state().change(data._state or 'alive')
    @publish()

  initState: ->
    state @,
      voteAction: -> false
      # player is dead, they don't get to take part in anything
      dead: state 'final',
        startPhase: ->
      alive:
        kill: -> @state('-> dead')
        startPhase: (phase) ->
          debug('phase', @state().path(), phase)
          if phase is 'day'
            @state('-> lynching')
          else
            @state('-> seeing')
            @state('-> asleep')
            @state('-> eating')


        night: state 'abstract',
          # guards set on the states based on roles
          asleep:
            admit: 'alive': -> @owner.role is 'villager'
          seeing:
            admit: 'alive': -> @owner.role is 'seer'
            voteAction: -> 'see'
          eating:
            admit: 'alive': -> @owner.role is 'werewolf'
            voteAction: -> 'eat'
        day: state 'abstract',
          # every living player lynches
          lynching:
            voteAction: -> 'lynch'


class Models.Players extends Models.BaseCollection
  url: 'player'
  model: Models.Player

  assignRoles: (roles) ->
    roles = getRoles(@length)
    @each (player) ->
      player.set('role', roles.shift())

  aliveTotal: ->
    isAlive = (p) -> p.state().isIn('alive')
    @filter(isAlive).length

  activeTotal: ->
    isActive = (p) ->
      state = p.state()
      debug 'active state', p.id, state.isIn('alive'), state.isIn('asleep'), state.path()
      state.isIn('alive') and not state.isIn('asleep')
    @filter(isActive).length

  startPhase: (phase) ->
    @invoke 'startPhase', phase

  aliveByRole: ->
    isAlive = (p) -> p.state().isIn('alive')
    toLengthPair = (v, k) -> [k, v.length]

    replaceSeer = (p) ->
      role = 'villager'
      role = 'werewolf' if p.role == 'werewolf'
      role

    @chain()
      .filter(isAlive)
      .map(replaceSeer)
      .groupBy(_.identity)
      .map(toLengthPair)
      .object()
      .value()
