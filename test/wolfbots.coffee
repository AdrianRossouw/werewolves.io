App      = require('../app/app.server.coffee')
State    = require('../state')
Socket   = require('../socket')
Models   = require('../models')
Wolfbots = require('../wolfbots')
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

setupSpies = ->
  $spy.remove = sinon.spy()
  $spy.add = sinon.spy()
  $spy.debug = sinon.spy()
  $spy.command = sinon.spy()

resetSpies = ->
  _($spy).invoke 'reset'

restoreSpies = ->


describe 'testing wolfbots module', ->

  before ->
    State.sessionStore = new MemoryStore(secret: config.secret)
    App.Voice.startWithParent= false
    Socket.start App.config()
    App.start App.config()
    Wolfbots.start mode: 'master'

  it 'should have initialized the bots collection', ->
    should.exist State.bots
    State.bots.length.should.equal 0
  
  describe 'spawning a master bot', ->
    @timeout(0)
    before (done) ->
      setupSpies()
      Socket.on 'connection', (socket, state) ->
        $state.session = state

        socket.on 'wolfbot:add', $spy.add
        socket.on 'wolfbot:remove', $spy.remove
        socket.on 'wolfbot:command', $spy.command
        socket.on 'wolfbot:debug', $spy.debug

        socket.on 'disconnect', ->
          socket.removeAllListeners 'wolfbot:add'
          socket.removeAllListeners 'wolfbot:remove'
          socket.removeAllListeners 'wolfbot:command'
          socket.removeAllListeners 'wolfbot:debug'

      start = (id) ->
        doSend = (arg1=null, arg2=null) ->
          window.callPhantom(arg1, arg2) if window.callPhantom

        Socket = App.Socket
        Wolfbots = App.Wolfbots
        State = App.State
        io = Socket.io

        Socket.io.emit('wolfbot:debug', 'botId', id)
        #doSend(null, id)
        Wolfbots.start master: true
        wb = Wolfbots
                
        bots = State.bots
        
        clyde = null
        # just adding the bot via the emit
        io.emit 'wolfbot:add', 'clyde'

        # using solo form of helper
        wb.add 'blinky'
        
        # using multiple form of helper
        wb.add 'sid', 'gaylord'

        io.emit('wolfbot:command', 'clyde', 'test:solo1')

        # solo form of command helper
        wb.command('clyde', 'test:solo2', 'A', 'B')

        # single array form of command helper
        wb.command(['clyde'], 'test:solo3', 'C', 'D')
      
        wb.command(['blinky', 'sid'], 'test:group1', 'E')

        wb.commandAll('test:all')

        io.emit 'wolfbot:remove', 'blinky'
       
        setTimeout (-> doSend null, 'ok'), 500

        undefined

      $state.master = new Models.Bot({id: 'master'}, {start:start})
      $state.master.stop().then(done.bind(null, null), done)


    it 'should have populated the master bot', ->
      should.exist $state.master
    
    it 'should have fired the add spy twice', ->
      $spy.add.callCount.should.equal 4
      $spy.add.withArgs('blinky').called.should.be.ok
      $spy.add.withArgs('clyde').called.should.be.ok
      $spy.add.withArgs('sid').called.should.be.ok
      $spy.add.withArgs('gaylord').called.should.be.ok

    it 'should have triggered solo commands', ->
      $spy.command.withArgs('clyde', 'test:solo1').called.should.be.ok
      $spy.command.withArgs('clyde', 'test:solo2', 'A', 'B').called.should.be.ok
      $spy.command.withArgs('clyde', 'test:solo3', 'C', 'D').called.should.be.ok

    it 'should have triggered group commands', ->
      $spy.command.withArgs('blinky', 'test:group1', 'E').called.should.be.ok
      $spy.command.withArgs('sid', 'test:group1', 'E').called.should.be.ok

    it 'should have triggered all commands', ->
      $spy.command.withArgs('blinky', 'test:all').called.should.be.ok
      $spy.command.withArgs('clyde', 'test:all').called.should.be.ok
      $spy.command.withArgs('sid', 'test:all').called.should.be.ok
      $spy.command.withArgs('gaylord', 'test:all').called.should.be.ok

    it 'should have fired the debug with the id parameter', ->
      $spy.debug.withArgs('botId', 'master').called.should.be.ok


  describe 'cleanup', ->
    before (done) ->
      restoreSpies()
      App.once 'close', done
      Socket.stop()
      App.stop()
      App.Voice.startWithParent= true


    it 'should have stopped the modules', ->
      State.should.have.property '_isInitialized', false
      Socket.should.have.property '_isInitialized', false
      Wolfbots.should.have.property '_isInitialized', false
      App.Models.should.have.property '_isInitialized', false
