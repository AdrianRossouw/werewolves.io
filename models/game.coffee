App      = require('../app')
state    = require('state')
_        = require('underscore')
Backbone = require('backbone')
Models   = App.module "Models"


# A game that is running or will be starting.
class Models.Game extends Models.BaseModel
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
        if process.env.NODE_ENV != 'production'
          minPlayerLimit = 3
        else
          minPlayerLimit = 7

        if App.isServer
          checkStart = ->
            thirtySecondsLast = _(players).max (m) -> (m.timeAdded - 20000)
            waitMore = (@players.length > 7) and (thirtySecondsLast < Date.now())
            if (not waitMore) or @players.length = 16
              @nextPhase()

          
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

