App      = require('../app')
state    = require('state')
_        = require('underscore')
Backbone = require('backbone')
debug    = require('debug')('werewolves:model:game')
Models   = App.module "Models"
{Capped} = require('backbone.projections')

# A game that is running or will be starting.
class Models.Game extends Models.BaseModel
  urlRoot: 'game'
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

  destroy: ->
    @players.invoke('destroy')
    @rounds.invoke('destroy')
    super

  toJSON: ->
    obj = super
    obj.players = @players.toJSON()
    obj.rounds = @rounds.toJSON()
    obj


  # try to go to the next phase
  next: ->
    before = @state().path()
    @state().change('victory.werewolves')
    @state().change('victory.villagers')
    @state().emit 'next' if before is @state().path()

  initState: -> state @,
    # This game hasn't started yet
    recruit: state 'abstract',
      
      # we are still waiting for enough players to join
      waiting: {}
      ready:
        next: 'round.firstNight'
        admit:
          # only admit state changes from .waiting when ...
          waiting: ->
            @owner.players.length >= 7

      # startgame method.
      startGame: -> @next()

      addPlayer: (player) ->
        # order player joined in.
        player.seqId = @players.length + 1
        result = @players.add(player)
        @lastPlayerAdded = Date.now()
        @state('-> ready')
        result

      # assign the roles when we leave the recruit state
      exit: ->
        @players.assignRoles() if App.server

    round: state 'abstract',
      enter: ->
        # kill someone if the death property gets changed
        # this should only happen when the round reaches complete.died stage
        @listenTo @rounds, 'change:death', (model, death) ->
          @players.kill death if death
          @next()

      depart: ->
        @stopListening @rounds, 'change:death'

      # won't come back here from victory state
      admit:
        'victory.*': false

      firstNight: state
        arrive: -> @addRound 'night'
        next: 'round.firstDay'

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

    # victory conditions
    victory: state 'abstract',
      enter: -> @trigger 'game:end'
      werewolves:
        admit:
          'round.*': ->
            aliveCount = @owner.players.aliveByRole()
            aliveCount.werewolf >= aliveCount.villager
      villagers:
        admit:
          'round.*': ->
            !@owner.players.aliveByRole().werewolf

    cleanup: state 'final'

    # default addplayer method
    addPlayer: -> debug 'can not add player any more'
    currentRound: -> debug 'no rounds yet'

