App = require('../app')
Models = require('../models')
State = require('../state')
config = require('../config')

should = require('should')

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

  describe 'game', ->
    before ->
      @game = @world.game

    it 'should have state recruit', ->
      @game.state().path().should.equal 'recruit'

    it 'should have an empty players collection', ->
      @game.players.length.should.equal 0

###
describe 'adding first player', ->
  before (done) ->
    @world = State.world
    @game = @world.game
    @game.players.on 'add', -> done

    @game.addPlayer id: App.ns.uuid()

  it 'should have worked', ->
    @game.players.length.should.equal 1
###
