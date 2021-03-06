# This test is built to confirm that the session
# state machine behaves as expected.
App      = require('../app')
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
    socket: ['socket.id']
    _state: 'online.socket'

  sip:
    id: 'sip'
    session: 'session.id'
    socket: ['socket.id']
    sip: 'socket.id': 'sip.id'
    _state: 'online.sip'

  voice:
    id: 'voice'
    session: 'session.id'
    socket: ['socket.id']
    sip: 'socket.id': 'sip.id'
    voice: 'voice.id'
    _state: 'online.voice'

  call:
    id: 'voice'
    session: 'session.id'
    socket: ['socket.id']
    sip: 'socket.id': 'sip.id'
    voice: 'voice.id'
    call: 'socket.id'
    _state: 'online.call'

  # edge case: used during testing a lot
  socketOnly:
    id: 'socket-only'
    socket: ['socket.id']
    _state: 'online.socket'

# get a clean instance
cleanInstances = ->
  result = {}
  for type, data of $data
    result[type] = new Models.Session data
  result

describe 'initializing sessions', ->
  before ->
    App.server = true
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

  it 'should have initialized a call session', ->
    testInitialized @m, 'call'

  it 'should have initialized an socketOnly session', ->
    testInitialized @m, 'socketOnly'

describe 'upgrading connections', ->
  
  describe 'from offline state', ->
    beforeEach -> @m = cleanInstances().offline

    it 'should upgrade to session', ->
      @m.addSession 'session.id'
      @m.session.should.equal 'session.id'
      @m.state().path().should.equal 'online.session'

    it 'should upgrade to socket', ->
      @m.addSession 'session.id'
      @m.addSocket 'socket.id'
      @m.socket.should.include 'socket.id'
      @m.state().path().should.equal 'online.socket'

    it 'should upgrade to sip', ->
      @m.addSession 'session.id'
      @m.addSocket 'socket.id'
      @m.addSip 'socket.id', 'sip.id'
      @m.sip.should.include 'socket.id': 'sip.id'
      @m.state().path().should.equal 'online.sip'

    it 'should upgrade to voice', ->
      @m.addSession 'session.id'
      @m.addSocket 'socket.id'
      @m.addSip 'socket.id', 'sip.id'
      @m.addVoice 'voice.id'
      @m.voice.should.equal 'voice.id'
      @m.state().path().should.equal 'online.voice'

      it 'should upgrade to call', ->
      @m.addSession 'session.id'
      @m.addSocket 'socket.id'
      @m.addSip 'socket.id', 'sip.id'
      @m.addVoice 'voice.id'
      @m.addCall 'socket.id'
      @m.call.should.equal 'socket.id'
      @m.state().path().should.equal 'online.call'

  describe 'from session state', ->
    beforeEach -> @m = cleanInstances().session

    it 'should upgrade to socket', ->
      @m.addSocket 'socket.id'
      @m.socket.should.include 'socket.id'
      @m.state().path().should.equal 'online.socket'

    it 'should upgrade to sip', ->
      @m.addSocket 'socket.id'
      @m.addSip 'socket.id', 'sip.id'
      @m.sip.should.include 'socket.id': 'sip.id'
      @m.state().path().should.equal 'online.sip'

    it 'should upgrade to voice', ->
      @m.addSocket 'socket.id'
      @m.addSip 'socket.id', 'sip.id'
      @m.addVoice 'voice.id'
      @m.voice.should.equal 'voice.id'
      @m.state().path().should.equal 'online.voice'

    it 'should upgrade to call', ->
      @m.addSocket 'socket.id'
      @m.addSip 'socket.id', 'sip.id'
      @m.addVoice 'voice.id'
      @m.addCall 'socket.id'
      @m.call.should.equal 'socket.id'
      @m.state().path().should.equal 'online.call'

  describe 'from socket state', ->
    beforeEach -> @m = cleanInstances().socket

    it 'should upgrade to sip', ->
      @m.addSip 'socket.id', 'sip.id'
      @m.sip.should.include 'socket.id': 'sip.id'
      @m.state().path().should.equal 'online.sip'

    it 'should upgrade to voice', ->
      @m.addSip 'socket.id', 'sip.id'
      @m.addVoice 'voice.id'
      @m.voice.should.equal 'voice.id'
      @m.state().path().should.equal 'online.voice'

    it 'should upgrade to call', ->
      @m.addSip 'socket.id', 'sip.id'
      @m.addVoice 'voice.id'
      @m.addCall 'socket.id'
      @m.call.should.equal 'socket.id'
      @m.state().path().should.equal 'online.call'

  describe 'from sip state', ->
    beforeEach -> @m = cleanInstances().sip

    it 'should upgrade to voice', ->
      @m.addVoice 'voice.id'
      @m.voice.should.equal 'voice.id'
      @m.state().path().should.equal 'online.voice'

    it 'should upgrade to call', ->
      @m.addVoice 'voice.id'
      @m.addCall 'socket.id'
      @m.call.should.equal 'socket.id'
      @m.state().path().should.equal 'online.call'

  describe 'from voice state', ->
    beforeEach -> @m = cleanInstances().voice

    it 'should upgrade to call', ->
      @m.addCall 'socket.id'
      @m.call.should.equal 'socket.id'
      @m.state().path().should.equal 'online.call'

  describe 'from socketOnly state', ->
    beforeEach -> @m = cleanInstances().socketOnly
    
    it 'should not downgrade to session', ->
      @m.addSession 'session.id'
      @m.session.should.equal 'session.id'
      @m.state().path().should.not.equal 'online.session'

    it 'should upgrade to sip', ->
      @m.addSip 'socket.id', 'sip.id'
      @m.sip.should.include 'socket.id': 'sip.id'
      @m.state().path().should.equal 'online.sip'

    it 'should upgrade to voice', ->
      @m.addSip 'socket.id', 'sip.id'
      @m.addVoice 'voice.id'
      @m.voice.should.equal 'voice.id'
      @m.state().path().should.equal 'online.voice'

    it 'should upgrade to call', ->
      @m.addSip 'socket.id', 'sip.id'
      @m.addVoice 'voice.id'
      @m.addCall 'socket.id'
      @m.call.should.equal 'socket.id'
      @m.state().path().should.equal 'online.call'

  describe 'out of order credentials', ->
    beforeEach -> @m = cleanInstances().offline
    
    it 'voice, sip, session, socket', ->
      @m.addVoice 'voice.id'
      @m.state().path().should.equal 'offline'

      @m.addSip 'socket.id', 'sip.id'
      @m.state().path().should.equal 'offline'

      @m.addSocket 'socket.id'
      @m.addSession 'session.id'

      @m.state().path().should.equal 'online.voice'
 
    it 'socket, session, voice, sip', ->
      @m.addSocket 'socket.id'
      @m.state().path().should.equal 'online.socket'

      @m.addSession 'session.id'
      @m.state().path().should.equal 'online.socket'

      @m.addVoice 'voice.id'
      @m.state().path().should.equal 'online.socket'

      @m.addSip 'socket.id', 'sip.id'
      @m.state().path().should.equal 'online.voice'

describe 'downgrading connections', ->
 
  describe 'from online.call state', ->
    beforeEach -> @m = cleanInstances().call

    it 'should downgrade to voice', ->
      @m.removeCall 'socket.id'
      @m.call.should.equal false
      @m.state().path().should.equal 'online.voice'

    it 'should downgrade to sip', ->
      @m.removeCall 'socket.id'
      @m.removeVoice 'voice.id'
      @m.voice.should.equal false
      @m.state().path().should.equal 'online.sip'

    it 'should downgrade to socket', ->
      @m.removeCall 'socket.id'
      @m.removeVoice 'voice.id'
      @m.removeSip 'socket.id', 'sip.id'

      @m.state().path().should.equal 'online.socket'

    it 'should downgrade to session', ->
      @m.removeCall 'socket.id'
      @m.removeVoice 'voice.id'
      @m.removeSip 'socket.id', 'sip.id'
      @m.removeSocket 'socket.id'

      @m.state().path().should.equal 'online.session'

    it 'should downgrade to offline', ->
      @m.removeCall 'socket.id'
      @m.removeVoice 'voice.id'
      @m.removeSip 'socket.id'
      @m.removeSocket 'socket.id'
      @m.removeSession 'session.id'

      @m.state().path().should.equal 'offline'

  describe 'from online.voice state', ->
    beforeEach -> @m = cleanInstances().voice

    it 'should downgrade to sip', ->
      @m.removeVoice 'voice.id'
      @m.voice.should.equal false
      @m.state().path().should.equal 'online.sip'

    it 'should downgrade to socket', ->
      @m.removeVoice 'voice.id'
      @m.removeSip 'socket.id', 'sip.id'

      @m.state().path().should.equal 'online.socket'

    it 'should downgrade to session', ->
      @m.removeVoice 'voice.id'
      @m.removeSip 'socket.id', 'sip.id'
      @m.removeSocket 'socket.id'

      @m.state().path().should.equal 'online.session'

    it 'should downgrade to offline', ->
      @m.removeVoice 'voice.id'
      @m.removeSip 'socket.id'
      @m.removeSocket 'socket.id'
      @m.removeSession 'session.id'

      @m.state().path().should.equal 'offline'

  describe 'from online.sip state', ->
    beforeEach -> @m = cleanInstances().sip

    it 'should downgrade to socket', ->
      @m.removeSip 'socket.id'
      @m.state().path().should.equal 'online.socket'

    it 'should downgrade to session', ->
      @m.removeSip 'socket.id'
      @m.removeSocket 'socket.id'

      @m.state().path().should.equal 'online.session'

    it 'should downgrade to offline', ->
      @m.removeSip 'socket.id'
      @m.removeSocket 'socket.id'
      @m.removeSession 'session.id'

      @m.state().path().should.equal 'offline'

  describe 'from online.socket state', ->
    beforeEach -> @m = cleanInstances().socket

    it 'should downgrade to session', ->
      @m.removeSocket 'socket.id'

      @m.state().path().should.equal 'online.session'

    it 'should downgrade to offline', ->
      @m.removeSocket 'socket.id'
      @m.removeSession 'session.id'

      @m.state().path().should.equal 'offline'

  describe 'only socket removed first', ->
    before ->
      @m = cleanInstances().call
      @m.removeSocket 'socket.id'

    it 'should have dowgraded us to online.session', ->
      @m.state().path().should.equal 'online.session'

    it 'should not have sockets', ->
      @m.hasSocket().should.equal false

    it 'should have removed the relevant sip address', ->
      should.not.exist @m.sip['socket.id']

    it 'should have removed the call id if it was active', ->
      @m.call.should.not.equal 'socket.id'

    it 'should have removed the voice connection', ->
      @m.voice.should.equal false

  describe 'call -> voice -> call', ->
    before ->
      @m = cleanInstances().call

    describe 'downgrade to voice', ->
      before ->
        @m.removeCall 'socket.id'

      it 'should have dowgraded us to online.voice', ->
        @m.state().path().should.equal 'online.voice'

      it 'should not have call', ->
        @m.call.should.equal false

      it.skip 'should have removed the voice connection', ->
        @m.voice.should.equal false

    describe 'upgrade to call', ->
      before ->
        @m.addCall 'socket.id'

      it 'should have dowgraded us to online.voice', ->
        @m.state().path().should.equal 'online.call'

      it 'should not have call', ->
        @m.call.should.equal 'socket.id'
