App = require('../app')
State = require('../state')
should = require('should')

fixture = require('./fixture/game1.coffee')

it 'should get to this point', ->
  should.ok('reached this point')

it 'should have returned a module', ->
  should.exist(State)

describe 'init state', ->
  before ->
    State.load(fixture)
    State.start()

  it 'did the loading of records', ->
    should.exist State.world
    should.exist State.world.sessions
    should.exist State.world.game
    should.exist State.world.game.players
    should.exist State.world.game.rounds

  it 'is in the right state', ->
    State.world.game.state().path().should.equal 'round.day'

  it 'has 4 rounds', ->
    State.world.game.rounds.length.should.equal 4

  describe 'choose method', ->
    before ->
      @world = State.world
      @game = @world.game
      @currentRound = @game.currentRound()
      @myRecord = @currentRound.actions.findWhere
        id: 'Edward'
        action: 'lynch'

      @currentVote = @myRecord.target

    it 'should be in votes.all state', ->
      @currentRound.state().path().should.equal 'votes.all'


    it 'is in the daytime', ->
      State.world.game.state().path().should.equal 'round.day'

    it 'all living players are awake', ->
      villagers = @game.players.chain()
        .where(role: 'villager')
        .filter((v) -> v.state().path() != 'dead')
        .each((v) -> v.state().path().should.equal 'alive.day.lynching')

    it 'should have a current vote', ->
      should.exist @myRecord
      should.exist @currentVote

    it 'should be the right user', ->
      @currentVote.should.equal 'Juniper'

    it 'should change my vote', ->
      @currentRound.choose 'Edward', 'lynch', 'Gaylord'

      @myRecord.should.not.equal 'Juniper'

    it 'should fire the change event', (done) ->
      @currentRound.actions.on 'change', (model) ->
        should.exist model
        model.should.have.property 'id'
        model.id.should.equal 'Edward'
        should.exist model.target
        model.target.should.equal 'Juniper'

        done()


      @currentRound.choose 'Edward', 'lynch', 'Juniper'
  describe 'game ending', ->
    before ->
      @currentRound = State.world.game.currentRound()

    it 'should count the votes correctly', ->
      votes = @currentRound.countVotes()

      votes[0].should.include { id: 'Edward', votes: 2 }
      votes[1].should.include { id: 'Juniper', votes: 1 }
      votes[2].should.include { id: 'Dafydd', votes: 1 }
      votes[3].should.include { id: 'Florence', votes: 1 }

    it 'should pick the correct victim', ->
      @currentRound.getDeath().should.equal 'Edward'
      
  after () ->
    State.stop()

