App      = require('../app')
state    = require('state')
_        = require('underscore')
Backbone = require('backbone')
Models   = App.module "Models"

getRoles = (numPlayers) ->
  #werewolf, seer, villager
  # rules:
  # < 12: 2
  # < 18: 3
  # 18: 4

  roles = ['seer', 'werewolf']
  if numPlayers > 7
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
      dead: state 'final'
      alive:
        daytime: state 'abstract',
          # every living player lynches
          lynching: {}
        nighttime: state 'abstract',
          # guards set on the states based on roles
          seeing:
            admit: -> @owner.role is 'seer'
          eating:
            admit: -> @owner.role is 'villager'
          sleeping:
            admit: -> @owner.role is 'werewolf'

class Models.Players extends Backbone.Collection
  model: Models.Player

  assignRoles: ->
    roles = getRoles(@length)
    @each (player) ->
      player.set('role', roles.shift())

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
