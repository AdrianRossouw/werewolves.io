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
    super
    @players = new Models.Players []
    @rounds = new Models.Rounds []
    @publish()
    @state().change(data._state or 'recruit')
    @players.reset data.players if data.players
    @rounds.reset data.rounds if data.rounds


  destroy: ->
    @players.invoke('destroy')
    @rounds.invoke('destroy')
    super

  toJSON: ->
    obj = super
    obj.players = @players.toJSON()
    obj.rounds = @rounds.toJSON()
    obj

  status: ->
    switch @state().path()
      when 'recruit.waiting' then "#{@players.length} players. #{7 - @players.length} more needed."
      when 'recruit.ready' then "Starting game with #{@players.length} players."
      when 'round.night.first' then "First night"
      when 'round.day.first' then "First day"
      when 'round.night' then "Nightime"
      when 'round.day' then "Daytime"
      when 'victory.werewolves' then "Werewolves win!"
      when 'victory.villagers' then "Villagers win!"
      when 'cleanup' then 'Game over!'



  # try to go to the next phase
  next: ->
    @state().change('victory.werewolves')
    @state().change('victory.villagers')
    @state().emit 'next'

  initState: -> state @,
    # This game hasn't started yet
    recruit: state 'abstract',
      
      # we are still waiting for enough players to join
      waiting: {}
      ready:
        next: 'round.night.first'
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
        @players.assignRoles()

    round: state 'abstract',

      # won't come back here from victory state
      admit:
        'victory.*': -> false

      night: state
        first: state
          next: 'round.day.first'

        enter: -> @addRound 'night'
        next: 'day'

      day:
        enter: -> @addRound 'day'
        next: 'night'
        first: state
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

