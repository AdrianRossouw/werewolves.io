App      = require('../app')
state    = require('state')
_        = require('underscore')
Backbone = require('backbone')
debug    = require('debug')('werewolves:model:game')
Models   = App.module "Models"
State    = App.module "State"
{Capped} = require('backbone.projections')

# A game that is running or will be starting.
class Models.Game extends Models.BaseModel
  url: 'game'
  @attribute 'phaseTime'
  initialize: (data = {}, opts={}) ->
    @id = App.ns.uuid()
    @players = new Models.Players []
    @rounds = new Models.Rounds []
    @players.reset data.players if data.players
    @rounds.reset data.rounds if data.rounds
    super
    @state().change(data._state or 'recruit')
    @publish()
    @trigger('state', @state().path())

  destroy: ->
    @players.invoke('destroy')
    @rounds.invoke('destroy')
    super

  toJSON: (session) ->
    obj = super
    obj.players = @players.toJSON(session)
    obj.rounds = @rounds.toJSON(session)
    obj

  # try to go to the next phase
  next: ->
    before = @state().path()

    @go('victory.werewolves')
    @go('victory.villagers')
    if App.server
      @state().emit 'next' if before is @state().path()

  initState: -> state @,
    initial: state 'initial'
    # This game hasn't started yet
    recruit: state 'abstract',
      # we are still waiting for enough players to join
      waiting: {}
      ready:
        next: 'round.firstNight'
        admit:
          # only admit state changes from .waiting when ...
          'initial, waiting': ->
            return true if !App.server
            @owner.players.length >= 7

      # startgame method.
      startGame: -> @next()

      addPlayer: (player) ->
        session = State.getSession(player.id)
        # order player joined in.
        player.seqId = @players.length + 1
        player.name = session.name if session?.name
        result = @players.add(player)
        @lastPlayerAdded = Date.now()
        @go('ready')
        result

      # assign the roles when we leave the recruit state
      exit: ->
        @players.assignRoles() if App.server
        State.trigger('data', 'merge', 'player', @players)

    round: state 'abstract',
      enter: ->
        # kill someone if the death property gets changed
        # this should only happen when the round reaches complete.died stage
        @listenTo @rounds, 'change:death', (model, death) ->
          @players.kill death if death
          State.trigger('data', 'merge', 'player', @players)
          @next()

      depart: ->
        @stopListening @rounds, 'change:death'
        State.trigger('data', 'merge', 'player', @players)

      firstNight: state
        arrive: -> @addRound 'night'
        next: 'round.firstDay'
        lastRound: -> debug 'no rounds yet'

      firstDay: state
        arrive: -> @addRound 'day'
        next: 'night'

      night: state
        arrive: -> @addRound 'night'
        next: 'day'

      day: state
        arrive: -> @addRound 'day'
        next: 'night'

      addRound: (phase) ->
        return null if !App.server
        @players.startPhase(phase)
        round =
          id: App.ns.uuid()
          number: @rounds.length + 1
          phase: phase or 'night'
          activeTotal: @players.activeTotal()

        round = @rounds.add round,
          timer: @timer
          players: @players

      currentRound: ->
        @rounds.last()
      lastRound: ->
        return null unless @rounds.length >= 2

        index = @rounds.length - 2
        @rounds.at(index)

    # victory conditions
    victory: state 'abstract',
      enter: -> @trigger 'game:end'
      werewolves:
        admit:
          'initial, round.*': ->
            return true if !App.server
            aliveCount = @owner.players.aliveByRole()
            aliveCount.werewolf >= aliveCount.villager
      villagers:
        admit:
          'initial, round.*': ->
            return true if !App.server
            !@owner.players.aliveByRole().werewolf
      lastRound: -> @rounds.last()

    cleanup: state 'final'

    # default addplayer method
    addPlayer: -> debug 'can not add player any more'
    currentRound: -> debug 'no rounds yet'
    lastRound: -> debug 'no rounds yet'
