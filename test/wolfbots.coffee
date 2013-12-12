App      = require('../app/app.server.coffee')
State    = require('../state')
Socket   = require('../socket')
Models   = require('../models')
Wolfbots = require('../wolfbots')
socketio = require("socket.io-client")
config   = require('../config')
should   = require('should')
express  = require('express')
sinon    = require('sinon')
_        = require('underscore')
fixture  = require('./fixture/game1.coffee').game
MemoryStore = express.session.MemoryStore

$spy    = {}
$io     = {}
$socket = {}
$state  = {}
$server = {}
$clock  = false

App.config = ->
  _.extend {}, config.defaults,
    port: 8006
    socket:
      log: false

# we want the client side loaded too.
Client = require('../wolfbots/wolfbots.client.coffee')


setupSpies = ->
  $spy.remove = sinon.spy()
  $spy.add = sinon.spy()
  $spy.command = sinon.spy()
  $spy.commandAll = sinon.spy()

resetSpies = ->
  _($spy).invoke 'reset'

restoreSpies = ->

_config = App.config()
socketUrl = Socket.formatUrl(_config)

before (done) ->
  setupSpies()
  State.sessionStore = new MemoryStore(secret: _config.secret)
  App.Voice.startWithParent= false

  Socket.on 'connection', (socket, state) ->
    testHandler = (args..., cb = ->) -> cb(null)

    socket.on 'wolfbot:add', $spy.add
    socket.on 'wolfbot:remove', $spy.remove
    socket.on 'wolfbot:command', $spy.command
    socket.on 'wolfbot:command:all', $spy.commandAll

    socket.on 'test:solo1', testHandler
    socket.on 'test:solo2', testHandler
    socket.on 'test:group1', testHandler
    socket.on 'test:all', testHandler

    socket.on 'disconnect', ->
      socket.removeAllListeners 'wolfbot:add'
      socket.removeAllListeners 'wolfbot:remove'
      socket.removeAllListeners 'wolfbot:command'
      socket.removeAllListeners 'wolfbot:command:all'
      socket.removeAllListeners 'test:solo1'
      socket.removeAllListeners 'test:solo2'
      socket.removeAllListeners 'test:group1'
      socket.removeAllListeners 'test:all'

  App.once 'listen', ->
    $io.socket = socketio.connect socketUrl,'force new connection': true
    $io.socket.on 'connect', -> done()

  App.start _config
  Socket.start _config


it 'should have initialized the bots collection', ->
  should.exist Wolfbots.bots
  Wolfbots.bots.length.should.equal 0

describe 'spawning a master bot', ->
  before (done) ->
    Client.start(socket: $io.socket)

    Client.add('blinky')
      .then(-> Client.add 'sid', 'gaylord', 'clyde')
      .then(-> Client.command 'clyde', 'test:solo1', 'A', 'B')
      .then(-> Client.command ['clyde'], 'test:solo2', 'C', 'D')
      .then(-> Client.command ['blinky', 'sid'], 'test:group1', 'E')
      .then(-> Client.commandAll 'test:all')
      .then(-> Client.commandAll 'test:all', 'argument')
      .then(-> Client.remove 'blinky')
      .then(-> done())

  it 'should have fired the add spy thrice', ->
    $spy.add.callCount.should.equal 4
    $spy.add.withArgs('blinky').called.should.be.ok
    $spy.add.withArgs('clyde').called.should.be.ok
    $spy.add.withArgs('sid').called.should.be.ok
    $spy.add.withArgs('gaylord').called.should.be.ok

  it 'should have triggered solo commands', ->
    $spy.command.withArgs('clyde', 'test:solo1', 'A', 'B').called.should.be.ok
    $spy.command.withArgs('clyde', 'test:solo2', 'C', 'D').called.should.be.ok

  it 'should have triggered group commands', ->
    $spy.command.withArgs('blinky', 'test:group1', 'E').called.should.be.ok
    $spy.command.withArgs('sid', 'test:group1', 'E').called.should.be.ok

  it 'should have triggered all commands', ->
    $spy.commandAll.withArgs('test:all').called.should.be.ok
    $spy.commandAll.withArgs('test:all', 'argument').called.should.be.ok


describe 'cleanup', ->
  before (done) ->
    restoreSpies()
    $io.socket.disconnect()
    App.once 'close', done
    Socket.stop()
    App.stop()
    App.Voice.startWithParent= true

  it 'should have stopped the modules', ->
    State.should.have.property '_isInitialized', false
    Socket.should.have.property '_isInitialized', false
    Wolfbots.should.have.property '_isInitialized', false
    App.Models.should.have.property '_isInitialized', false
