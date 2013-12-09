App      = require('../app/app.server.coffee')
State    = require('../state')
Socket   = require('../socket')
Models   = require('../models')
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
$stub   = {}
$io     = {}
$socket = {}
$state  = {}
$server = {}
$clock  = false

$round  = _(fixture.rounds).pluck 'actions'
$player = _(fixture.players).map (p) ->
  _(p).pick('id', 'name')

$roles = [
  'werewolf', 'seer', 'villager',
  'werewolf', 'villager', 'villager',
  'villager', 'villager', 'villager'
]

MemoryStore = express.session.MemoryStore

setupSpies = ->
  $spy.state = sinon.spy State, 'trigger'
  $spy.socket = sinon.spy Socket, 'trigger'
  $spy.wolfIoData = sinon.spy()
  $spy.wolfIoState = sinon.spy()

  $spy.seerIoData = sinon.spy()
  $spy.seerIoState = sinon.spy()

  $spy.villagerIoData = sinon.spy()
  $spy.villagerIoState = sinon.spy()

  $spy.socket.withArgs('connection')
  $spy.state.withArgs('data', 'add', 'session')
  $spy.state.withArgs('data', 'change')
  $spy.state.withArgs('state')

  $stub.roles = sinon.stub Models, '_getRoles'
  $stub.roles.returns $roles


resetSpies = -> _($spy).invoke 'reset'

restoreSpies = ->
  $spy.state.restore()
  $spy.socket.restore()
  Models._getRoles.restore()

# Configuration things we need to do
socketio.transports = ["websocket"]

App.config = ->
  _.extend {}, config.defaults,
    port: 8001
    socket:
      log: false

before ->
  App.module "Voice",
    startsWithParent: false
  
  config = App.config()
  State.sessionStore = new MemoryStore(secret: config.secret)

  Socket.start config
  App.start config

it 'should have started the state module', ->
  State.should.have.property '_isInitialized', true

describe 'socket can connect', ->

  before (done) ->
    setupSpies()
    $io.socket = socketio.connect(Socket.formatUrl(App.config()))
    $io.socket.on 'connect', -> done()
    $io.socket.on 'data', $spy.wolfIoData
    $io.socket.on 'state', $spy.wolfIoState


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
      $state.timer = State.world.timer
      $state.game = State.world.game
      $state.players = State.world.game.players

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

    it 'the world should only a single session', ->
      should.exist($io.world.sessions)
      $io.world.sessions.length.should.equal 1

    it 'should have a game state', ->
      should.exist($io.world.game)
  
    it 'gives me the same world on both sides', ->
      should.exist $io.world.game.id
      should.exist $io.world.game._state
      $io.world.game.id.should.equal $state.game.id
      $io.world.game._state.should.equal $state.game.state().path()
 
    it 'gives me the same timer on both sides', ->
      should.exist $io.world.timer
      should.exist $io.world.timer._state
      $io.world.timer._state.should.equal $state.timer.state().path()


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
      $spy.wolfIoData.calledWith('change', $state.url).should.be.ok

    it 'IO should have caught a state event', ->
      $spy.wolfIoState.calledWith($state.url, 'online.sip').should.be.ok


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
      $spy.wolfIoData.calledWith('change', $state.url).should.be.ok

    it 'IO should have caught a state event', ->
      $spy.wolfIoState.calledWith($state.url, 'online.sip').should.be.ok



  describe 'it should allow us to join the game', ->
    before (done) ->
      $io.socket.emit 'game:join', (err, player) ->
        return done(err) if err

        $io.wolf = player
        $state.wolf = State.getPlayer($io.wolf.id)
        $state.wolfUrl = _.result $state.wolf, 'url'
        done()
    
    it 'should have passed back a player model', ->
      should.exist $io.wolf
      should.exist $state.wolf

    it 'should have right defaults', ->
      $io.wolf.role.should.equal 'villager'
      $io.wolf.name.should.be.ok
      $io.wolf.occupation.should.be.ok

    it 'should have the same id as session', ->
      $io.wolf.id.should.equal $state.session.id
      $io.wolf.id.should.equal $io.session.id
      $state.wolf.id.should.equal $io.wolf.id
 
    it 'should have an initial player state', ->
      $io.wolf._state.should.equal 'alive'
      $state.wolf.state().path().should.equal 'alive'

    it 'should have added us to the players list', ->
      $state.players.length.should.equal 1

    it 'should have changed the world state', ->
      $state.world.state().path().should.equal 'startup'

    it 'should have fired the state event', ->
      $spy.state.calledWith('state', 'world', 'startup').should.be.ok

    it 'should have fired the data add player event', ->
      $spy.state.calledWith('data', 'add', 'player', $state.wolfUrl).should.be.ok

  describe 'can only join once', ->
    before (done) ->
      resetSpies()
      $io.socket.emit 'game:join', (err, player) ->
        return done(err) if err
        done()

    it 'shouldnt have added us again', ->
      $state.players.length.should.equal 1

  describe 'another socket connects to the server', ->
    before (done) ->
      resetSpies()
      url = Socket.formatUrl(App.config())
      $io.seerSocket = socketio.connect url,
        'force new connection': true

      $io.seerSocket.on 'connect', -> done()
      $io.seerSocket.on 'data', $spy.seerIoData
      $io.seerSocket.on 'state', $spy.seerIoState

    it 'should not leak session info between sockets', ->
      $spy.wolfIoState.called.should.not.be.ok
      $spy.wolfIoData.called.should.not.be.ok



  describe 'adding the seer to the game', ->
    before (done) ->
      resetSpies()
      $io.seerSocket.emit 'game:join', (err, player) ->
        $state.seer = State.getPlayer player.id
        done()

    it 'should have added them to the players list', ->
      $state.players.length.should.equal 2

    it 'should have fired the data add player event', ->
      $spy.state.calledWith('data', 'add', 'player', $state.seer.getUrl()).should.be.ok

    it 'should have passed the data add to the first socket', ->
      $spy.wolfIoData.calledWith('add', 'player', $state.seer.getUrl()).should.be.ok
      withArgs = $spy.wolfIoData.withArgs('add', 'player', $state.seer.getUrl())
      $io.seer = withArgs.firstCall.args[3]

    it 'should have passed the data add to the second socket', ->
      $spy.seerIoData.calledWith('add', 'player', $state.seer.getUrl()).should.be.ok

    it 'should have given the new player the right state', ->
      $io.seer._state.should.equal 'alive'

    it 'should have right defaults', ->
      $io.seer.role.should.equal 'villager'
      $io.seer.name.should.be.ok
      $io.seer.occupation.should.be.ok

  describe 'adding a villager to the game', ->
    before (done) ->
      resetSpies()
      url = Socket.formatUrl(App.config())
      $io.villagerSocket = socketio.connect url,
        'force new connection': true

      $io.villagerSocket.on 'data', $spy.villagerIoData
      $io.villagerSocket.on 'state', $spy.villagerIoState

      $io.villagerSocket.on 'connect', ->
        $io.villagerSocket.emit 'game:join', (err, player) ->
          $state.villager = State.getPlayer player.id
          done()

    it 'should have passed the data add to the other sockets', ->
      $spy.wolfIoData.calledWith('add', 'player', $state.villager.getUrl()).should.be.ok
      withArgs = $spy.wolfIoData.withArgs('add', 'player', $state.villager.getUrl())
      $io.villager = withArgs.firstCall.args[3]

    it 'should have passed the data add to the second socket', ->
      $spy.villagerIoData.calledWith('add', 'player', $state.villager.getUrl()).should.be.ok

    it 'should have given the new player the right state', ->
      $io.villager._state.should.equal 'alive'

    it 'should have right defaults', ->
      $io.villager.role.should.equal 'villager'
      $io.villager.name.should.be.ok
      $io.villager.occupation.should.be.ok

  # only this part uses fake timers
  describe 'starting the game', ->

    before ->
      resetSpies()

      $clock = sinon.useFakeTimers()
   
    describe 'adding more players, 10 seconds apart', ->
      before ->
        resetSpies()
        rest = _($player).rest(2)
        _(rest).each (p) ->
          $clock.tick 10000
          $state.game.addPlayer p
   
      it 'should have fired 6 player add data events', ->
        $spy.state.withArgs('data', 'add', 'player').callCount.should.equal 6

      it 'should have changed the game state', ->
        $state.game.state().path().should.equal('recruit.ready')

      it 'sockets should have picked up 6 player add events', ->
        $spy.wolfIoData.withArgs('add', 'player').callCount.should.equal 6

      it 'socket should have gotten the game state change', ->
        $spy.wolfIoState.withArgs($state.game.getUrl(), 'recruit.ready').called.should.be.ok

    describe 'game starts in another 30 seconds', ->
      before ->
        resetSpies()
        $clock.tick 30100

      it 'changed the world state to gameplay', ->
        $state.world.state().is('gameplay').should.be.ok

      it 'changed the world state to the first night', ->
        $state.game.state().is('round.firstNight').should.be.ok

      it 'set all the players to one of the night states', ->
        $state.players.each (p) ->
          p.state().isIn('alive').should.be.ok
          p.state().isIn('night').should.be.ok

      it 'triggered all state changes over the state module', ->
        $spy.state.calledWith('state', 'world', 'gameplay').should.be.ok
        $spy.state.calledWith('state', $state.game.getUrl(), 'round.firstNight').should.be.ok
        $state.players.each (p) ->
          $spy.state.calledWith('state', p.getUrl(), p.state().path()).should.be.ok

    describe 'all players got roles', ->
      before ->
        $state.roles = $state.players.groupBy((p) -> p.role)
        $state.wolf2 = $state.players.at(3)

      it 'handed out the right roles', ->
        $state.roles.werewolf.length.should.equal 2
        $state.roles.seer.length.should.equal 1
        $state.roles.villager.length.should.equal 6

        $state.wolf.get('role').should.equal 'werewolf'
        $state.seer.get('role').should.equal 'seer'
        $state.villager.get('role').should.equal 'villager'

      it 'triggered all the data events for role changes', ->
        $state.players.each (p) ->
          if p.role != 'villager'
            $spy.state.calledWith('data', 'change', p.getUrl()).should.be.ok
          else
            $spy.state.calledWith('data', 'change', p.getUrl()).should.not.be.ok

      it 'have sent the wolf his role', ->
        $spy.wolfIoData.calledWith('change', $state.wolf.getUrl()).should.be.ok

      it 'should not have sent the wolf the seer', ->
        withArgs = $spy.wolfIoData.withArgs('change', $state.seer.getUrl())
        # TODO: fix this so it doesnt send any messages, or sends for everyone
        withArgs.called.should.be.ok
        withArgs.args[0][2].role.should.equal 'villager'


      it 'should have sent the wolf the other wolf', ->
        $spy.wolfIoData.calledWith('change', $state.wolf2.getUrl()).should.be.ok

      it 'have sent the seer his role', ->
        $spy.seerIoData.calledWith('change', $state.seer.getUrl()).should.be.ok

      it 'should not have sent the seer the wolves yet', ->
        wolf1 = $spy.seerIoData.withArgs('change', $state.wolf.getUrl())
        wolf1.called.should.be.ok
        wolf1.args[0][2].role.should.equal 'villager'

        wolf2 = $spy.seerIoData.withArgs('change', $state.wolf2.getUrl())
        wolf2.called.should.be.ok
        wolf2.args[0][2].role.should.equal 'villager'

    describe 'first night', ->


    after ->
      $clock.restore()


describe 'cleanup', ->
  before (done) ->
    restoreSpies()
    App.once 'close', done

    Socket.stop()
    App.stop()

    App.module "Voice",
      startsWithParent: true



  it 'should have stopped the modules', ->
    State.should.have.property '_isInitialized', false
    Socket.should.have.property '_isInitialized', false
    App.Models.should.have.property '_isInitialized', false



