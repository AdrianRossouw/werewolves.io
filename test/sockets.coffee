App = require('../app/app.server.coffee')
State = require('../state')
Socket = require('../socket')
should = require('should')
sinon = require('sinon')
socketio = require("socket.io-client")

App.config = ->
  secret: 'sasquatch'
  token: "22656a3121261b4db6509f369c89e7067a36eff14b6a1fd5f0438699b894211590fdca2edd37de9fd1fdd7e2"
  port: 8001
  socket:
    log: false

before (done) ->
  App.on 'listen', -> done()

  App.start App.config()

it 'should have started the state module', ->
  State.should.have.property '_isInitialized', true

describe 'socket can connect', ->
  before (done) ->
    socketio.transports = ["websocket"]
    @io = socketio.connect('http://localhost:8001')
    @io.on 'connect', ->
      done()

  it 'should have set up the environment', ->
    should.exist @io

describe 'cleanup', ->
  before ->
    App.stop()

  it 'should have stopped the modules', ->
    State.should.have.property '_isInitialized', false
    Socket.should.have.property '_isInitialized', false
    App.Models.should.have.property '_isInitialized', false
    App.Voice.should.have.property '_isInitialized', false



