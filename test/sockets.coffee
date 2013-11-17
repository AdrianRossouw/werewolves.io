App = require('../app/app.server.coffee')
State = require('../state')
Socket = require('../socket')
config = require('../config')
should = require('should')
express     = require('express')
sinon = require('sinon')
_ = require('underscore')
socketio = require("socket.io-client")
socketio.transports = ["websocket"]

App.config = ->
  _.extend {}, config.defaults,
    port: 8001
    socket: log: false


before (done) ->
  App.on 'listen', -> done()

  App.start App.config()

it 'should have started the state module', ->
  State.should.have.property '_isInitialized', true

describe 'socket can connect', ->

  before (done) ->
    @stateSpy = sinon.spy State, 'trigger'
    @socketSpy = sinon.spy Socket, 'trigger'
    @io = socketio.connect('http://localhost:8001')
    @io.on 'connect', =>
      done()

  it 'should have set up the environment', ->
    should.exist @io
    console.log @socketSpy.args

  after ->
    @stateSpy.restore()
    @socketSpy.restore()

describe 'cleanup', ->
  before ->
    App.stop()

  it 'should have stopped the modules', ->
    State.should.have.property '_isInitialized', false
    Socket.should.have.property '_isInitialized', false
    App.Models.should.have.property '_isInitialized', false
    App.Voice.should.have.property '_isInitialized', false



