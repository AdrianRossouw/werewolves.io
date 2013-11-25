App     = require('../app')
Models  = require('../models')
State   = require('../state')
config  = require('../config')
should  = require('should')
sinon   = require('sinon')
_       = require('underscore')
fixture = require('./fixture/game1.coffee')

it 'should have a world model', ->
  should.exist(Models.World)

describe 'start application', ->
  before ->
    @clock = sinon.useFakeTimers()
    App.server ?= true
    App.start(config.defaults)
    State.start(config.defaults)

  it 'should have initialized a model on the state', ->
    should.exist(State.world)
    @world = State.world
  
  it 'should have a sessions object', ->
    should.exist(@world.sessions)

  it 'should have a game object', ->
    should.exist(@world.game)

  it 'should have a timer object', ->
    should.exist(@world.timer)

  it 'should return game as the url()', ->
    @world.url.should.equal('world')

  it 'should have an initial state of attract', ->
    @world.state().path().should.equal 'attract'

  describe 'before game', ->
    before ->
      @game = @world.game

    it 'should have state recruit.waiting', ->
      @game.state().path().should.equal 'recruit.waiting'

    it 'should have an empty players collection', ->
      @game.players.length.should.equal 0

    it 'should have no rounds', ->
      @game.rounds.length.should.equal 0

  describe 'adding first player', ->
    before () ->
      @world = State.world
      @game = @world.game
      @firstPlayer = _(fixture.game.players).first()
      @game.addPlayer id: @firstPlayer.id

    it 'should have worked', ->
      @game.players.length.should.equal 1

    it 'should have changed world state to startup', ->
      @world.state().path().should.equal 'startup'

  describe 'rest of players', ->
    before () ->
      @world = State.world
      @game = @world.game


      rest = _(fixture.game.players).rest()

      _(rest).each (p) =>
        @game.addPlayer id: p.id

    it 'should have added 8 players total', ->
      @game.players.length.should.equal 8

    it 'should have state recruit.ready', ->
      @game.state().path().should.equal 'recruit.ready'

    it 'should still be in startup state 29 seconds later', ->
      @clock.tick(29000)
      @world.state().path().should.equal 'startup'

  describe 'starting game', ->
    before () ->
      @world = State.world
      @game = @world.game
      @timer = @world.timer

    it 'should have started the game another second later', ->
      @clock.tick(1000)
      @world.state().path().should.equal 'gameplay'

    it 'should have assigned roles', ->
      counts = @game.players.aliveByRole()
      should.exist(counts)
      counts.werewolf.should.equal 1
      counts.villager.should.equal 7

    it 'should have moved to the firstNight round', ->
      @game.state().path().should.equal 'round.firstNight'

    it 'should have added a night round', ->
      @game.rounds.length.should.equal 1

    it 'should have set the timer limit', ->
      @timer.limit.should.equal @game.players.activeTotal() * 30000


    it 'should have set the the correct activeTotal', ->
      @game.players.activeTotal().should.equal 2


  describe 'playing the game', ->
    before ->
      # we are assigning roles randomly
      # so we need to use the assigned roles
      @world = State.world
      @game = @world.game
      @timer = State.getTimer()

      @wolf = @game.players.findWhere
        role:'werewolf'
      @seer = @game.players.findWhere
        role:'seer'
      @villagers = @game.players.where
        role:'villager'

      # first night
      @victim1 = @villagers[0]
      @seen1 = @victim1

      # first day
      @victim2 = @villagers[1]

      # second night
      @victim3 = @villagers[2]
      @seen2 = @wolf

      # second day
      @victim4 = @wolf


    describe 'during the first night', ->
      before () ->
        @round = @game.currentRound()

      it 'should only have 2 active players', ->
        @game.players.activeTotal().should.equal 2
        @round.activeTotal.should.equal 2

      it 'should have put the seer in seeing state', ->
        @seer.state().path().should.equal 'alive.night.seeing'

      it 'should have put the wolf in eating state', ->
        @wolf.state().path().should.equal 'alive.night.eating'

      it 'should have put the rest in sleep state', ->
        _(@villagers).each((v) -> v.state().path().should.equal 'alive.night.asleep')

      it 'should have the round in votes.none state', ->
        @game.currentRound().state().path().should.equal 'votes.none'

    describe 'round timer should work', ->
      before () ->
        @round = @game.currentRound()

      it 'should have started the timer', ->
        @timer.state().path().should.equal 'active'

      it 'should correctly count down with time passing', ->
        @timer.remaining().should.equal 60000
        @clock.tick(1000)
        @timer.remaining().should.equal 59000

    describe 'wolf voting', ->
      before ->
        @round = @game.currentRound()
        @round.choose @wolf.id, @victim1.id

      it 'should allow the wolf to vote', ->
        @round.actions.at(0).should.include
          id: @wolf.id
          action: 'eat'
          target: @victim1.id

      it 'should have set the state to votes.some', ->
        @round.state().path().should.equal 'votes.some'

      it 'should correctly identify who would die next', ->
        @round.getDeath().should.equal @victim1.id

    describe 'seer voting', ->
      before ->
        @round = @game.currentRound()
        @round.choose @seer.id, @seen1.id

      it 'should allow the seer to vote', ->
        @round.actions.at(1).should.include
          id: @seer.id
          action: 'see'
          target: @seen1.id

      it 'should have set the state to votes.all', ->
        @round.state().path().should.equal 'votes.all'

    describe 'hurried timer', ->
      before ->
        @round = @game.currentRound()

      it 'should have changed the timer length', ->
        @timer.remaining().should.equal 30000

      it 'should still be running', ->
        @timer.state().path().should.equal 'active'

    describe 'villagers are really asleep', ->
      before ->
        @round = @game.currentRound()

        @round.choose _(@villagers).last().id, @wolf.id
        @round.choose _(@villagers).last().id, @victim1.id
        @round.choose @villagers[2].id, @seer.id

      it 'should not allow villagers to vote now', ->
        @round.actions.length.should.equal 2

    describe 'ending the first night', ->
      before (done) ->
        @round = @game.currentRound()
        @timer.once 'end', done
        @clock.tick 30000
        @nextRound = @game.currentRound()

      it 'should have moved the round to complete.died', ->
        @round.state().path().should.equal 'complete.died'

      it 'should have killed someone', ->
        @round.death.should.equal @victim1.id

      it 'should go to the first day round', ->
        @game.state().path().should.equal 'round.firstDay'

      it 'should add a round', ->
        @game.rounds.length.should.equal 2

      it 'should be in a day phase', ->
        @game.currentRound().phase.should.equal 'day'

    describe 'during the first day', ->

      before ->
        @round = @game.currentRound()
        @round.choose @seer.id, @victim2.id
        @round.choose @wolf.id, @victim2.id
        _(@villagers).each (a) =>
          @round.choose a.id, @victim2.id

      it 'should have 7 active players', ->
        @game.players.activeTotal().should.equal 7

      it 'all should be in lynching state', ->
        @game.players.each (p) =>
          path = p.state().path()
          if p.id is @victim1.id
            path.should.equal 'dead'
          else
            path.should.equal 'alive.day.lynching'

      it 'should allow all the votes', ->
        @round.actions.length.should.equal 7

      it 'should identify the correct victim', ->
        @round.getDeath().should.equal @victim2.id

    describe 'hurried daytime timer', ->
      before ->
        @round = @game.currentRound()

      it 'should have changed the timer length', ->
        @timer.remaining().should.equal 30000

      it 'should still be running', ->
        @timer.state().path().should.equal 'active'

    describe 'ending the day', ->
      before ->
        @round = @game.currentRound()
        @clock.tick 30000

      it 'should have killed second victim', ->
        @victim2.state().path().should.equal 'dead'

      it 'should have set the round to complete.died', ->
        @round.state().path().should.equal 'complete.died'

      it 'should have 2 active players', ->
        @game.players.activeTotal().should.equal 2

      it 'should add a round', ->
        @game.rounds.length.should.equal 3
        @game.currentRound().should.not.equal @round

      it 'should be in a night phase', ->
        @game.currentRound().phase.should.equal 'night'

      it 'should go to the next night round', ->
        @game.state().path().should.equal 'round.night'

      it 'should be in the votes.none state', ->
        @game.currentRound().state().path().should.equal 'votes.none'


    describe 'during the next night', ->
      before () ->
        @round = @game.currentRound()
        @round.choose @wolf.id, @victim3.id
        @round.choose @seer.id, @wolf.id

      it 'should allow all the votes', ->
        @round.actions.length.should.equal 2

      it 'should go to votes.all state', ->
        @round.state().path().should.equal 'votes.all'

    describe 'hurried nightime timer', ->
      before ->
        @round = @game.currentRound()

      it 'should have changed the timer length', ->
        @timer.remaining().should.equal 30000

      it 'should still be running', ->
        @timer.state().path().should.equal 'active'

    describe 'ending the night', ->
      before ->
        @clock.tick @timer.remaining()

      it 'should have 5 active players', ->
        @game.players.activeTotal().should.equal 5

      it 'should have killed third', ->
        @victim3.state().path().should.equal 'dead'

    describe 'during the next day', ->
      before () ->
        @round = @game.currentRound()
        @round.choose @seer.id, @wolf.id
        @round.choose @wolf.id, @seer.id
        _(@villagers).each (a) =>
          @round.choose a.id, @wolf.id

      it 'should go to the next day round', ->
        @game.state().path().should.equal 'round.day'
        @game.rounds.length.should.equal 4

      it 'should allow all the votes', ->
        @round.actions.length.should.equal 5

    describe 'villagers lynch the wolf', ->
      before ->
        @spy = sinon.spy()
        @game.once 'game:end', @spy
        @round = @game.currentRound()
        @clock.tick 30000

      it 'should have killed a wolf', ->
        @wolf.state().path().should.equal 'dead'
 
      it 'should have made it to complete.died', ->
        @round.state().path().should.equal 'complete.died'

      it 'should have change game to victory.villagers', ->
        @game.state().path().should.equal 'victory.villagers'

      it 'should have changed the world to cleanup', ->
        @world.state().path().should.equal 'cleanup'

      it 'should have started the timer again', ->
        @timer.state().path().should.equal 'active'

      it 'should have fired the game:end event', ->
        @spy.called.should.be.ok

      it 'should have given it 30 seconds before a new game', ->
        @timer.remaining().should.equal 30000

    describe 'ready for next game', ->
      before ->
        @clock.tick 30000
        @newGame = State.world.game
      
      it 'should go to attract mode again', ->
        @world.state().path().should.equal 'attract'


      it 'should have created an empty new game', ->
        @newGame.should.not.equal @game

      it 'should have no players or rounds yet', ->
        @newGame.players.length.should.equal 0
        @newGame.rounds.length.should.equal 0
      it 'should be recruit.waiting state', ->
        @newGame.state().path().should.equal 'recruit.waiting'

describe 'cleanup test', ->
  before ->
    App.stop()
    @clock.restore()

  it 'should have stopped the modules', ->
    State.should.have.property '_isInitialized', false
    App.Models.should.have.property '_isInitialized', false


