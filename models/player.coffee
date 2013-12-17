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

Models._getJobs = (numPlayers) ->
  jobs = [
    'Village Bicycle',
    'Vicar',
    'Apothecary',
    'Ashman',
    'Auger Maker',
    'Bobbin Turner',
    'Bodger',
    'Decretist',
    'Distiller',
    'Eremite',
    'Fawkner',
    'Furbisher',
    'Freemason',
    'Haberdasher',
    'Harlot',
    'Hosteller',
    'Iron Master',
    'Journeyman',
    'Lumberjack',
    'Chimney Sweep',
    'Mule Minder',
    'Night Soilman',
    'Ostiary',
    'Pettifogger',
    'Phrenologist',
    'Traveling Loom Saleman',
    'Proctor',
    'Seamstress',
    'Soap Boiler',
    'Staymaker',
    'Street Orderly',
    'Steeple Jacker'
  ]
  _.shuffle jobs



# A player who has joined an active or upcoming
# game.
class Models.Player extends Models.BaseModel
  urlRoot: 'player'
  @attribute 'name'
  @attribute 'role'
  @attribute 'occupation'
  @attribute 'seqId'
  @attribute 'seen'

  initialize: (data={}, opts={}) ->
    @id = @id or App.ns.uuid()
    super
    @set('name', App.ns.name()) unless @name
    @set('role', 'villager') unless @role
    _occupation = _(Models._getJobs()).sample()

    @set('occupation', _occupation) unless @occupation
    @seen = data.seen or []
    @state().change(data._state or 'alive')
    @trigger('state', @state().path())
    @publish()
    @initClient(data, opts)

  toJSON: (session) ->
    result = super
    return result unless session

    # never reveal who the seer has seen
    result.seen = []

    # dead players roles are known
    return result if @state().is('dead')

    # your own role is known
    # and the seer can see his own seen
    player = session.player
    if @id == player?.id
      result.seen = @seen
      return result

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

  # conditionally filter out what events
  # get sent to the clients.
  filterData: (session, event) ->
    event is 'change'

  # never let other players know whether we
  # are alive.eating or alive.seeing
  maskState: (session, _state) ->
    return _state unless session

    # you can see your own true state
    return _state if session.id is @id

    # always return .asleep otherwise
    regex = /alive.night.*/
    return 'alive.night.asleep' if regex.test(_state)
    _state

  initState: ->
    state @,
      voteAction: -> false
      initial: state 'initial'
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
              'initial,alive,alive.day.*': ->
                return true if !App.server
                @owner.role is 'villager'
          seeing:
            admit:
              'initial,alive,alive.day.*': ->
                return true if !App.server
                @owner.role is 'seer'
            voteAction: -> 'see'
          eating:
            admit:
              'initial,alive,alive.day.*': ->
                return true if !App.server
                @owner.role is 'werewolf'
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
      player.set
        role: roles.shift()

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
