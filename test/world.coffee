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

    it 'should only have the first round', ->
      @game.rounds.length.should.equal 1

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
      @clock = sinon.useFakeTimers()
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

    it 'should have started the game another second later', ->
      @clock.tick(2000)
      @world.state().path().should.equal 'gameplay'

    it 'should have assigned roles', ->
      counts = @game.players.aliveByRole()
      should.exist(counts)
      counts.werewolf.should.equal 1
      counts.villager.should.equal 6

    after ->
      @clock.restore()

  after ->
    State.stop()


