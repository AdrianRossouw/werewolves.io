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

    it 'should have moved to the night.first round', ->
      @game.state().path().should.equal 'round.night.first'

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

      @wolves = @game.players.where
        role:'werewolf'
      @seer = @game.players.findWhere
        role:'seer'
      @villagers = @game.players.where
        role:'villager'

    describe 'during the first night', ->
      before () ->
        @round = @game.currentRound()

      it 'should only have 2 active players', ->
        @game.players.activeTotal().should.equal 2
        @round.activeTotal.should.equal 2

      it 'should have put the seer in seeing state', ->
        @seer.state().path().should.equal 'alive.night.seeing'

      it 'should have put the wolf in eating state', ->
        _(@wolves).each((v) -> v.state().path().should.equal 'alive.night.eating')

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
        @round.choose _(@wolves).first().id, _(@villagers).first().id

      it 'should allow the wolf to vote', ->
        @round.actions.at(0).should.include
          id: _(@wolves).first().id
          action: 'eat'
          target: _(@villagers).first().id

      it 'should have set the state to votes.some', ->
        @round.state().path().should.equal 'votes.some'

      it 'should correctly identify who would die next', ->
        @round.getDeath().should.equal(_(@villagers).first().id)

    describe 'seer voting', ->
      before ->
        @round = @game.currentRound()
        @round.choose @seer.id, _(@villagers).first().id

      it 'should allow the seer to vote', ->
        @round.actions.at(1).should.include
          id: @seer.id
          action: 'see'
          target: _(@villagers).first().id

      it 'should have set the state to votes.all', ->
        @round.state().path().should.equal 'votes.all'

    describe 'hurried timer', ->
      before ->
        @round = @game.currentRound()

      it 'should have changed the timer length', ->
        @round.getDeath().should.equal(_(@villagers).first().id)

    describe 'villagers are really asleep', ->
      before ->
        @clock.tick(100)
        @round = @game.currentRound()

        @round.choose _(@villagers).last().id, _(@wolves).last().id
        @round.choose _(@villagers).last().id, _(@villagers).first().id
        @round.choose @villagers[2].id, @seer.id

      it 'should not allow villagers to vote now', ->
        @round.actions.length.should.equal 2

    describe 'during the first day', ->
      before () ->
        @clock.tick(100)
        @game.next()

      # TODO: why is this broken ?
      it.skip 'should go to the first day round', ->
        @game.rounds.length.should.equal 2
        @game.state().path().should.equal 'round.day.first'
        @game.currentRound().phase.should.equal 'day'

      it 'should have 8 active players', ->
        @game.players.activeTotal().should.equal 8

      it 'all should be in lynching state', ->
        @game.players.each (p) ->
          p.state().path().should.equal 'alive.day.lynching'

    describe 'during the next night', ->
      before () ->
        @clock.tick(100)
        @game.next()


      it 'should go to the next night round', ->
        @game.state().path().should.equal 'round.night'
        @game.rounds.length.should.equal 3

    describe 'during the next day', ->
      before () ->
        @clock.tick(100)
        @game.next()


      it 'should go to the next day round', ->
        @game.state().path().should.equal 'round.day'
        @game.rounds.length.should.equal 4


describe 'cleanup', ->
  before ->
    App.stop()
    @clock.restore()

  it 'should have stopped the modules', ->
    State.should.have.property '_isInitialized', false
    App.Models.should.have.property '_isInitialized', false


