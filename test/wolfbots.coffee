App      = require('../app/app.server.coffee')
State    = require('../state')
Socket   = require('../socket')
Models   = require('../models')
Wolfbots = require('../wolfbots')
config   = require('../config')
should   = require('should')
sinon    = require('sinon')
_        = require('underscore')
fixture  = require('./fixture/game1.coffee').game

$spy    = {}
$io     = {}
$socket = {}
$state  = {}
$server = {}
$clock  = false

App.config = ->
  _.extend {}, config.defaults,
    port: 8004
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
    setupSpies
    App.start App.config()
    Socket.start App.config()
    Wolfbots.start mode: 'master'

  
  it 'should have initialized the bots collection', ->
    should.exist State.bots
    State.bots.length.should.equal 0
  
  describe 'spawning a master bot', ->
    @timeout(0)
    before (done) ->
      start = (id) ->
        Socket = App.Socket
        Wolfbots = App.Wolfbots
        State = App.State

        State.joinGame(window.callPhantom)

        #Socket.io.on 'connect', ->
          #Wolfbots.start master: true
                  
          #bots = State.bots

          #clyde = bots.add id:'clyde'


          #Socket.io.emit('wolfbot:command', 'clyde', 'game:join', -> window.callPhantom(null, 'ok'))
          #Socket.io.emit('wolfbot:command', 'game:join', 'clyde', window.callPhantom)

      $state.master = new Models.Bot({}, {start:start})

      $state.master.phantom.then(done.bind(null, null), done)

      Socket.on 'connection', (socket, state) ->
        done()

        console.log 'hello world1'
        process.exit()

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

        done()


    it 'should have populated the master bot', ->
      should.exist $state.master
    
    it 'should have fired the add spy twice', ->
      $spy.add.calledTwice.should.be.ok

    after ->
      $state.master.stop()

  describe 'cleanup', ->
    before ->
      App.stop()


    it 'should have stopped the modules', ->
      State.should.have.property '_isInitialized', false
      Socket.should.have.property '_isInitialized', false
      Wolfbots.should.have.property '_isInitialized', false
      App.Models.should.have.property '_isInitialized', false
