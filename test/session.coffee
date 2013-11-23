# This test is built to confirm that the session
# state machine behaves as expected.

Models   = require('../models')
should   = require('should')
sinon    = require('sinon')
_ = require('underscore')

# some initial states for the session object to play with
$data =
  offline:
    id: 'offline'
    _state: 'offline'

  session:
    id: 'session'
    session: 'session.id'
    _state: 'online.session'

  socket:
    id: 'socket'
    session: 'session.id'
    socket: 'socket.id'
    _state: 'online.socket'

  sip:
    id: 'sip'
    session: 'session.id'
    socket: 'socket.id'
    sip: 'sip.id'
    _state: 'online.sip'

  voice:
    id: 'voice'
    session: 'session.id'
    socket: 'socket.id'
    sip: 'sip.id'
    voice: 'voice.id'
    _state: 'online.voice'

  # edge case: used during testing a lot
  socketOnly:
    id: 'socket-only'
    socket: 'socket.id'
    _state: 'online.socket'

# get a clean instance
cleanInstances = ->
  result = {}
  for type, data of $data
    result[type] = new Models.Session data
  result

describe 'initializing sessions', ->
  before ->
    @m = cleanInstances()

  testInitialized = (instances, key) ->
    data = $data[key]
    inst = instances[key]

    should.exist inst

    for key, value of data
      if key is not '_state'
        should.exist inst[key]
        inst[key].should.equal value

    should.exist inst.state
    inst.state().path().should.equal data._state


  it 'should have initialized an offline session', ->
    testInitialized @m, 'offline'

  it 'should have initialized an session session', ->
    testInitialized @m, 'session'

  it 'should have initialized an socket session', ->
    testInitialized @m, 'socket'

  it 'should have initialized an sip session', ->
    testInitialized @m, 'sip'

  it 'should have initialized an voice session', ->
    testInitialized @m, 'voice'

  it 'should have initialized an socketOnly session', ->
    testInitialized @m, 'socketOnly'

describe 'upgrading connections', ->
  
  describe 'from offline state', ->
    beforeEach -> @m = cleanInstances().offline

    it 'should upgrade to session', ->
      @m.session = 'session.id'
      @m.session.should.equal 'session.id'
      @m.state().path().should.equal 'online.session'

    it 'should upgrade to socket', ->
      @m.session = 'session.id'
      @m.socket = 'socket.id'
      @m.socket.should.equal 'socket.id'
      @m.state().path().should.equal 'online.socket'

    it 'should upgrade to sip', ->
      @m.session = 'session.id'
      @m.socket = 'socket.id'
      @m.sip = 'sip.id'
      @m.sip.should.equal 'sip.id'
      @m.state().path().should.equal 'online.sip'

    it 'should upgrade to voice', ->
      @m.session = 'session.id'
      @m.socket = 'socket.id'
      @m.sip = 'sip.id'
      @m.voice = 'voice.id'
      @m.voice.should.equal 'voice.id'
      @m.state().path().should.equal 'online.voice'

  
  describe 'from session state', ->
    beforeEach -> @m = cleanInstances().session

    it 'should upgrade to socket', ->
      @m.socket = 'socket.id'
      @m.socket.should.equal 'socket.id'
      @m.state().path().should.equal 'online.socket'

    it 'should upgrade to sip', ->
      @m.socket = 'socket.id'
      @m.sip = 'sip.id'
      @m.sip.should.equal 'sip.id'
      @m.state().path().should.equal 'online.sip'

    it 'should upgrade to voice', ->
      @m.socket = 'socket.id'
      @m.sip = 'sip.id'
      @m.voice = 'voice.id'
      @m.voice.should.equal 'voice.id'
      @m.state().path().should.equal 'online.voice'
 
  describe 'from socket state', ->
    beforeEach -> @m = cleanInstances().socket

    it 'should upgrade to sip', ->
      @m.sip = 'sip.id'
      @m.sip.should.equal 'sip.id'
      @m.state().path().should.equal 'online.sip'

    it 'should upgrade to voice', ->
      @m.sip = 'sip.id'
      @m.voice = 'voice.id'
      @m.voice.should.equal 'voice.id'
      @m.state().path().should.equal 'online.voice'

  describe 'from sip state', ->
    beforeEach -> @m = cleanInstances().sip

    it 'should upgrade to voice', ->
      @m.voice = 'voice.id'
      @m.voice.should.equal 'voice.id'
      @m.state().path().should.equal 'online.voice'

  describe 'from socketOnly state', ->
    beforeEach -> @m = cleanInstances().socketOnly
    
    it 'should not downgrade to session', ->
      @m.session = 'session.id'
      @m.session.should.equal 'session.id'
      @m.state().path().should.not.equal 'online.session'

    it 'should upgrade to sip', ->
      @m.sip = 'sip.id'
      @m.sip.should.equal 'sip.id'
      @m.state().path().should.equal 'online.sip'

    it 'should upgrade to voice', ->
      @m.sip = 'sip.id'
      @m.voice = 'voice.id'
      @m.voice.should.equal 'voice.id'
      @m.state().path().should.equal 'online.voice'


  describe 'out of order credentials', ->
    beforeEach -> @m = cleanInstances().offline
    
    it.skip 'voice, sip, socket', ->
      @m.voice = 'voice.id'
      @m.state().path().should.equal 'offline'

      @m.sip = 'sip.id'
      @m.state().path().should.equal 'offline'

      @m.socket = 'socket.id'

      @m.state().path().should.equal 'online.voice'

 
    it 'socket, session, voice, sip', ->
      @m.socket = 'socket.id'
      @m.state().path().should.equal 'online.socket'

      @m.session = 'session.id'
      @m.state().path().should.equal 'online.socket'

      @m.voice = 'voice.id'
      @m.state().path().should.equal 'online.socket'

      @m.sip = 'sip.id'
      @m.state().path().should.equal 'online.voice'



describe.skip 'downgrading connections', ->
 
  describe 'from online.voice state', ->
    beforeEach -> @m = cleanInstances().voice

    it 'should downgrade to sip', ->
      @m.unset('voice')
      should.not.exist(@m.voice)
      @m.state().path().should.equal 'online.sip'
