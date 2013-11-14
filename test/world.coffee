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
    App.start(config.defaults)
    State.start(config.defaults)

  it 'should have initialized a model on the state', ->
    should.exist(State.world)
    @world = State.world
  
  it 'should have a sessions object', ->
    should.exist(@world.sessions)

  it 'should have a game object', ->
    should.exist(@world.game)

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

    it 'should have added 7 players total', ->
      @game.players.length.should.equal 7

    it 'should have state recruit.ready', ->
      @game.state().path().should.equal 'recruit.ready'

    it 'should still be in startup state 29 seconds later', ->
      @clock.tick(29000)
      @world.state().path().should.equal 'startup'

  describe 'starting game', ->
    before () ->
      @world = State.world
      @game = @world.game

    it 'should have started the game another second later', ->
      @clock.tick(2000)
      @world.state().path().should.equal 'gameplay'

    it 'should have assigned roles', ->
      counts = @game.players.aliveByRole()
      should.exist(counts)
      counts.werewolf.should.equal 1
      counts.villager.should.equal 6

    it 'should have moved to the night.first round', ->
      @game.state().path().should.equal 'round.night.first'

    it 'should have added a night round', ->
      @game.rounds.length.should.equal 1

  describe 'during the first night', ->
    before () ->
      @world = State.world
      @game = @world.game


    it 'should only have 2 active players', ->
      @game.players.activeTotal().should.equal 2

    it 'should have put the seer in seeing state', ->
      seer = @game.players.findWhere role: 'seer'
      seer.state().path().should.equal 'alive.night.seeing'

    it 'should have put the wolf in eating state', ->
      wolf = @game.players.findWhere role: 'werewolf'
      wolf.state().path().should.equal 'alive.night.eating'

    it 'should have put the rest in sleep state', ->
      villagers = @game.players.chain()
        .where(role: 'villager')
        .each((v) -> v.state().path().should.equal 'alive.night.asleep')

  describe 'during the first day', ->
    before () ->
      @world = State.world
      @game = @world.game
      @game.next()

    it 'should go to the first day round', ->
      @game.state().path().should.equal 'round.day.first'
      @game.rounds.length.should.equal 2
      @game.currentRound().phase.should.equal 'day'

    it 'should have 7 active players', ->
      @game.players.activeTotal().should.equal 7

    it 'all should be in lynching state', ->
      @game.players.each (p) ->
        p.state().path().should.equal 'alive.day.lynching'


  describe 'during the next night', ->
    before () ->
      @world = State.world
      @game = @world.game
      @game.next()


    it 'should go to the next night round', ->
      @game.state().path().should.equal 'round.night'
      @game.rounds.length.should.equal 3

  describe 'during the next day', ->
    before () ->
      @world = State.world
      @game = @world.game
      @game.next()


    it 'should go to the next day round', ->
      @game.state().path().should.equal 'round.day'
      @game.rounds.length.should.equal 4




  after ->
    State.stop()
    @clock.restore()


