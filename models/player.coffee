App      = require('../app')
state    = require('state')
_        = require('underscore')
debug    = require('debug')('werewolves:model:player')
Backbone = require('backbone')
Models   = App.module "Models"
State    = App.module "State"

Models._getRoles = (numPlayers) ->
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
  @attribute 'seqId'

  initialize: (data={}, opts={}) ->
    @id = @id or App.ns.uuid()
    super
    @set('name', App.ns.name()) unless @name
    @set('occupation', App.ns.jobTitle()) unless @occupation
    @set('role', 'villager') unless @role
    @state().change(data._state or 'alive')
    @publish()
    @trigger('state', @state().path())

  toJSON: (session) ->
    result = super
    return result unless session

    # dead players roles are known
    return result if @state().is('dead')

    # your own role is known
    player = State.getPlayer(session.id)
    return result if player?.id == @id

    # werewolves get other wolves
    if player?.role == 'werewolf'
      return result if @role == 'werewolf'

    # seers get anyone they have seen before.
    if (player?.role == 'seer')
      seen = player?.seen or []
      return result if @id in seen

    # villagers get nothing else.
    result.role = 'villager'
    return result

  initState: ->
    state @,
      voteAction: -> false
      # player is dead, they don't get to take part in anything
      dead: state 'final',
        startPhase: ->
      alive:
        kill: ->
          @go('dead')

        startPhase: (phase) ->
          debug('phase', @name, @state().path(), phase)
          if phase is 'day'
            @go('lynching')
          else
            @go('seeing')
            @go('asleep')
            @go('eating')

        night: state 'abstract',
          # guards set on the states based on roles
          asleep:
            admit:
              'alive,alive.day.*': -> @owner.role is 'villager'
          seeing:
            admit:
              'alive,alive.day.*': -> @owner.role is 'seer'
            voteAction: -> 'see'
          eating:
            admit:
              'alive,alive.day.*': -> @owner.role is 'werewolf'
            voteAction: -> 'eat'
        day: state 'abstract',
          # every living player lynches
          lynching:
            voteAction: -> 'lynch'


class Models.Players extends Models.BaseCollection
  url: 'player'
  model: Models.Player

  assignRoles: (roles) ->
    roles = _.clone(Models._getRoles(@length))
    @each (player) ->
      player.set('role', roles.shift())

  kill: (id) ->
    @get(id).kill()

  active: ->
    isAlive = (p) -> p.state().isIn('alive')
    @filter(isAlive)

  aliveTotal: ->
    @active().length

  activeTotal: ->
    isActive = (p) ->
      _state = p.state()
      debug 'active _state', p.id, _state.isIn('alive'), _state.isIn('asleep'), _state.path()
      _state.isIn('alive') and not _state.isIn('asleep')
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
