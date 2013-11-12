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

  roles = ['seer', 'werewolf', 'werewolf']
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
  @attribute 'session'
  @attribute 'name'
  @attribute 'role'
  @attribute 'living'
  @attribute 'occupation'

  triggerState: (state) ->
    @trigger @id, state, living

  initialize: ->
    super
    @set('name', App.ns.name()) unless @name
    @set('occupation', App.ns.jobTitle()) unless @occupation
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

class Models.Players extends Models.Sessions
  model: Models.Player

  assignRoles: ->
    roles = getRoles(@length)
    @each (player) ->
      player.set('role', roles.shift())
