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

  initialize: ->
    super
    @set('name', App.ns.name()) unless @name
    @set('occupation', App.ns.jobTitle()) unless @occupation
    @set('role', 'villager') unless @villager
    @state('-> alive')

  initState: ->
    state @,
      # player is dead, they don't get to take part in anything
      dead: state 'final',
        startPhase: ->
      alive:
        kill: -> @state('-> dead')

        startPhase: (phase) ->
          if phase is 'day'
            @state('-> lynching')
          else
            @state('-> seeing')
            @state('-> asleep')
            @state('-> eating')

        day: state 'abstract',
          # every living player lynches
          lynching: {}
        night: state 'abstract',
          # guards set on the states based on roles
          seeing:
            admit: '*': -> @owner.role is 'seer'
          eating:
            admit: '*': -> @owner.role is 'werewolf'
          asleep:
            admit: '*': -> @owner.role is 'villager'

class Models.Players extends Backbone.Collection
  model: Models.Player

  assignRoles: ->
    roles = getRoles(@length)
    @each (player) ->
      player.set('role', roles.shift())

  aliveTotal: ->
    isAlive = (p) -> p.state().isIn('alive')
    @filter(isAlive).length

  activeTotal: ->
    isActive = (p) ->
      state = p.state()
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
