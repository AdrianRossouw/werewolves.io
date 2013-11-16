App = require('../app/app.server.coffee')
State = require('../state')
Socket = require('../socket')
config = require('../config')
should = require('should')
sinon = require('sinon')
_ = require('underscore')
socketio = require("socket.io-client")

App.config = ->
  conf = {}
  _.defaults conf, config.defaults

  conf.port =  8001
  conf.socket =
      log: false
  conf

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



