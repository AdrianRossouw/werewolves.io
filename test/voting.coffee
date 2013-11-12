App = require('../app')
State = require('../state')
should = require('should')

fixture = require('./fixture/game1.coffee')

it 'should get to this point', ->
  should.ok('reached this point')

it 'should have returned a module', ->
  should.exist(State)

describe 'init state', ->
  before (done) ->
    State.on 'load', (data) ->
      done()

    State.load(fixture)
    State.start()

  it 'did the loading of records', ->
    should.exist State.world
    should.exist State.world.sessions
    should.exist State.world.game
    should.exist State.world.game.players
    should.exist State.world.game.rounds

  describe 'choose method', ->
    before ->
      @currentRound = State.world.game.rounds.last()

      @myRecord = @currentRound.actions.findWhere
        id: 'Edward'
        action: 'lynch'

      @currentVote = @myRecord.target

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
        model.target.should.equal 'Florence'

        done()

      @currentRound.choose 'Edward', 'lynch', 'Florence'
