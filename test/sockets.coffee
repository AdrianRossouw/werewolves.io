App      = require('../app/app.server.coffee')
State    = require('../state')
Socket   = require('../socket')
config   = require('../config')
should   = require('should')
express  = require('express')
sinon    = require('sinon')
_        = require('underscore')
socketio = require("socket.io-client")
fixture  = require('./fixture/game1.coffee').game

# container objects for various things
# we collect along the way

$spy    = {}
$io     = {}
$socket = {}
$state  = {}
$server = {}

$round  = _(fixture.rounds).pluck 'actions'
$player = _(fixture.players).map (p) ->
  _(p).pick 'id', 'name'




# Configuration things we need to do
socketio.transports = ["websocket"]

App.config = ->
  _.extend {}, config.defaults,
    port: 8001
    socket: log: false

before (done) ->
  App.on 'listen', -> done()

  App.module "Voice",
    startsWithParent: false

  App.start App.config()

it 'should have started the state module', ->
  State.should.have.property '_isInitialized', true

describe 'socket can connect', ->

  before (done) ->

    $spy.state = sinon.spy State, 'trigger'
    $spy.socket = sinon.spy Socket, 'trigger'
    $spy.ioData = sinon.spy()
    $spy.ioState = sinon.spy()

    $spy.socket.withArgs('connection')
    $spy.state.withArgs('data', 'add', 'session')
    $spy.state.withArgs('data', 'change')
    $spy.state.withArgs('state')

    $io.socket = socketio.connect('http://localhost:8001')
    $io.socket.on 'connect', -> done()
    $io.socket.on 'data', $spy.ioData
    $io.socket.on 'state', $spy.ioState


  it 'should have set up the environment', ->
    should.exist $io.socket

  it 'should have called the socket connection event', ->
    $spy.socket.calledWith('connection').should.be.ok

    # keep these handy for future tests
    $server.socket = $spy.socket.args[0][1]
    $server.session = $spy.socket.args[0][2]
    $server.url = _.result $server.session, 'url'
    $server.id = $server.session.id
  
  describe 'on the server', ->
    before ->
      $state.session = State.getSession($server.id)
      $state.url = _.result $state.session, 'url'
      $state.id = $state.session.id
      $state.world = State.world
      $state.game = State.world.game
      $state.players = State.world.players

    it 'should have fired a data add state event', ->
      $spy.state.calledWith('data', 'add', 'session', $state.url).should.be.ok

    it 'should give me a proper reference', ->
      $state.session.should.be.exactly $server.session

    it 'should give me the same url', ->
      $state.url.should.be.exactly $server.url
      
    it 'should have fired a data change state event', ->
      $spy.state.calledWith('data', 'change', $state.url).should.be.ok

    it 'should have fired a state event', ->
      $spy.state.calledWith('state', $state.url, 'online.socket').should.be.ok

    it 'should have given me a good state', ->
      $state.session.state().isIn('online').should.be.ok
      
  describe 'getting initial data from the server', ->
    before (done) ->
      $io.socket.emit 'data', 'world', (err, data) =>
        return done(err) if err
        $io.world = data
        done()

    it 'fetched the world', ->
      should.exist $io.world

    it 'the world should not have sessions', ->
      should.not.exist($io.world.sessions)

    it 'should have a game state', ->
      should.exist($io.world.game)
  
    it 'gives me the same world on both sides', ->
      should.exist $io.world.game.id
      should.exist $io.world.game._state
      $io.world.game.id.should.equal $state.game.id
      $io.world.game._state.should.equal $state.game.state().path()

  describe 'getting session from server', ->
    before (done) ->
      $io.socket.emit 'data', $state.url, (err, data) =>
        return done(err) if err
        $io.session = data
        done()

    it 'should have the same info on both sides', ->
      should.exist $io.session.id
      should.exist $io.session._state
      $io.session.id.should.equal $server.id
      $io.session._state.should.equal $state.session.state().path()


  describe 'upgrading session from client', ->
    before (done) ->
      $io.session.sip = 'test@test.com'
      $io.socket.emit 'update', $state.url, $io.session, done

    it 'should have changed the server records', ->
      $server.session.sip.should.equal $io.session.sip
      $state.session.sip.should.equal $io.session.sip

    it 'should have changed the state on the server', ->
      $server.session.state().path().should.equal 'online.sip'

    it 'State should have fired a data change event', ->
      $spy.state.calledWith('data', 'change', $state.url).should.be.ok

    it 'State should have fired a state event', ->
      $spy.state.calledWith('state', $state.url, 'online.sip').should.be.ok

    it 'IO should have caught a data change event', ->
      $spy.ioData.calledWith('change', $state.url).should.be.ok

    it 'IO should have caught a state event', ->
      $spy.ioState.calledWith($state.url, 'online.sip').should.be.ok


  describe 'upgrading session from server', ->
    before ->
      $state.session.voice = 'voice@test.com'

    it 'should have changed the server records', ->
      $state.session.sip.should.equal $io.session.sip

    it 'should have changed the state on the server', ->
      $server.session.state().path().should.equal 'online.voice'

    it 'State should have fired a data change event', ->
      $spy.state.calledWith('data', 'change', $state.url).should.be.ok

    it 'State should have fired a state event', ->
      $spy.state.calledWith('state', $state.url, 'online.voice').should.be.ok

    it 'IO should have caught a data change event', ->
      $spy.ioData.calledWith('change', $state.url).should.be.ok

    it 'IO should have caught a state event', ->
      $spy.ioState.calledWith($state.url, 'online.sip').should.be.ok

  describe 'it should allow us to join the game', ->
    before (done) ->
      $io.socket.emit 'game:join', (err, player) ->
        return done(err) if err

        $io.player = player
        $state.player = State.getPlayer($io.player.id)
        $state.playerUrl = _.result $state.player, 'url'
        done()
    
    it 'should have passed back a player model', ->
      should.exist $io.player
      should.exist $state.player

    it 'should have the same id as session', ->
      $io.player.id.should.equal $state.session.id
      $io.player.id.should.equal $io.session.id
      $state.player.id.should.equal $io.player.id
 
    it 'should have an initial player state', ->
      $io.player._state.should.equal 'alive'
      $state.player.state().path().should.equal 'alive'

    it 'should match the state on the server', ->
        
    it 'should have added us to the players list', ->
      $state.game.players.length.should.equal 1

    it 'should have changed the world state', ->
      $state.world.state().path().should.equal 'startup'

    it 'should have fired the state event', ->
      $spy.state.calledWith('state', 'world', 'startup').should.be.ok

    it 'should have fired the data add player event', ->
      $spy.state.calledWith('data', 'add', 'player', $state.playerUrl).should.be.ok


  describe 'can only join once', ->
    before (done) ->
      $io.socket.emit 'game:join', (err, player) ->
        return done(err) if err
        done()

    it 'shouldnt have added us again', ->
      $state.game.players.length.should.equal 1

  describe 'adding another player to the game', ->
    before ->
      $state.game.addPlayer _($player).first()


  after ->
    $spy.state.restore()
    $spy.socket.restore()

describe 'cleanup', ->
  before ->
    App.stop()

    App.module "Voice",
      startsWithParent: true



  it 'should have stopped the modules', ->
    State.should.have.property '_isInitialized', false
    Socket.should.have.property '_isInitialized', false
    App.Models.should.have.property '_isInitialized', false



