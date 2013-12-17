# This test is built to confirm that the session
# state machine behaves as expected.
App      = require('../app')
Models   = require('../models')
should   = require('should')
sinon    = require('sinon')
_ = require('underscore')

fiveSecs = 5000
tenSecs = 10000
twentySecs = 20000
thirtySecs = 30000
oneMin = 60000

$json = {}

describe 'timer model', ->
  before ->
    App.server = true
    @clock = sinon.useFakeTimers()
    @timer = new Models.Timer()

  it 'should start in a stopped state', ->
    @timer.state().path().should.equal 'inactive.stopped'

  it 'should have a time limit of 0', ->
    @timer.limit.should.equal 0

  it 'should not have an _endTime value', ->
    should.not.exist @timer._endTime

  describe 'while stopped', ->
    it 'should return now() as the deadline', ->
      @timer.deadline().should.equal Date.now()
    
    it 'should always return 0 ms remaining', ->
      @timer.remaining().should.equal 0

    it 'should not be able to start without a limit', ->
      @timer.start()
      @timer.state().path().should.equal 'inactive.stopped'

    it 'should allow a time limit to be set (in miliseconds)', ->
      @timer.limit = thirtySecs
      @timer.limit.should.equal thirtySecs

    it 'should always give me the deadline as $limit ms in the future', ->
      @timer.deadline().should.equal Date.now() + @timer.limit
      @clock.tick oneMin
      @timer.deadline().should.equal Date.now() + @timer.limit

    it 'should always give me the remaining ms as the $limit', ->
      @timer.remaining().should.equal @timer.limit
      @clock.tick oneMin
      @timer.remaining().should.equal @timer.limit

  describe 'resetting a stopped timer', ->
    before ->
      @timer.reset()

    it 'should still be stopped', ->
      @timer.state().path().should.equal 'inactive.stopped'

  describe 'starting the timer', ->
    before ->
      $json.stopped = @timer.toJSON()
      @timer.start()
      $json.started = @timer.toJSON()


    it 'should be in the active state', ->
      @timer.state().path().should.equal 'active'

    it 'should have set the _endTime correctly', ->
      should.exist @timer._endTime
      @timer._endTime.should.equal Date.now() + @timer.limit

    it 'should have added a setTimeout instance on the model', ->
      should.exist @timer._timeout

    it 'should have added a setInterval instance on the model', ->
      should.exist @timer._interval

   
  describe 'timer is active', ->
    before ->
      @spy = sinon.spy()
      @timer.on 'tick', @spy

      @clock.tick(fiveSecs) # 5 seconds ahead in time

    it 'should return the _endTime as the deadline', ->
      @timer.deadline().should.equal @timer._endTime

    it 'should subtract the time remaining correctly', ->
      @timer.remaining().should.equal twentySecs + fiveSecs

    it 'should have emitted tick events', ->
      @spy.callCount.should.equal 50

    after ->
      @timer.off 'tick', @spy
      @clock.tick fiveSecs # move another 5 seconds up in time

  describe 'pausing the timer', ->
    before ->
      @deadline = @timer.deadline()
      @remaining = @timer.remaining()
      @timer.pause()
      $json.paused = @timer.toJSON()

      @clock.tick fiveSecs # move another 5 seconds up in time

    it 'should be in paused state', ->
      @timer.state().path().should.equal 'inactive.paused'

    it 'should have cleared the _endTime', ->
      should.not.exist @timer._endTime

    it 'should have cleared the setInterval instance', ->
      should.not.exist @timer._interval

    it 'should have cleared the setTimeout instance', ->
      should.not.exist @timer._timeout

    it 'remaining be fixed at what it was when paused', ->
      @timer.remaining().should.equal @remaining

    it 'deadline should always be remaining ms from now', ->
      @timer.deadline().should.equal @remaining + Date.now()
      @clock.tick fiveSecs # move another 5 seconds up in time
      @timer.deadline().should.equal @remaining + Date.now()


  describe 'resuming the timer', ->
    before ->
      @deadline = @timer.deadline()
      @remaining = @timer.remaining()
      @timer.resume()


    it 'should be in active state', ->
      @timer.state().path().should.equal 'active'

  describe 'once the timer is active again', ->
    before ->
      @remaining = @timer.remaining()
      @clock.tick(fiveSecs) # move another 5 seconds up in time

    it 'should return the _endTime as the deadline', ->
      @timer.deadline().should.equal @timer._endTime

    it 'should subtract the time remaining correctly', ->
      @timer.remaining().should.equal @remaining - fiveSecs

  describe 'stopping the timer', ->
    before ->
      @timer.stop()

    it 'should have reached the stopped state', ->
      @timer.state().path().should.equal 'inactive.stopped'

    it 'should have cleared the _endTime', ->
      should.not.exist @timer._endTime

    it 'should have cleared the interval/timeout instances', ->
      should.not.exist @timer._timeout
      should.not.exist @timer._interval

    it 'should return the limit as remaining()', ->
      @timer.limit.should.equal @timer.remaining()

    it 'should always return limit ms from now as the deadline', ->
      @timer.deadline().should.equal @timer.limit + Date.now()
      @clock.tick fiveSecs # move another 5 seconds up in time
      @timer.deadline().should.equal @timer.limit + Date.now()

  describe 'resetting the timer', ->
    before ->
      @timer.start()
      @clock.tick(tenSecs)
      @timer.reset()

    it 'should still be active after being reset', ->
      @timer.state().path().should.equal 'active'

    it 'should have reset the remaining time', ->
      @timer.remaining().should.equal thirtySecs
      @clock.tick fiveSecs
      @timer.remaining().should.equal twentySecs + fiveSecs

    it 'should always return the _endTime as the deadline()', ->
      @timer.deadline().should.equal @timer._endTime
      @clock.tick fiveSecs
      @timer.deadline().should.equal @timer._endTime

  describe 'trigger the timeout', ->
    before ->
      @spy = sinon.spy()
      @timer.on 'end', @spy
      @clock.tick(twentySecs)

    it 'should have triggered the end event', ->
      @spy.called.should.be.ok

    it 'should be in stopped state', ->
      @timer.state().path().should.equal 'inactive.stopped'

    after ->
      @timer.off 'end', @spy

  describe 'serializing the timer', ->

    describe 'stopped timers', ->
      it 'got serialized', ->
        should.exist $json.stopped

      it 'have a state', ->
        should.exist $json.stopped._state
        $json.stopped._state.should.equal 'inactive.stopped'

      it 'have a limit', ->
        should.exist $json.stopped.limit
        $json.stopped.limit.should.equal thirtySecs

      it 'dont have an endTime or remaining', ->
        should.not.exist $json.stopped._endTime
        should.not.exist $json.stopped._remaining


    describe 'started timers', ->
      it 'got serialized', ->
        should.exist $json.started

      it 'have a state', ->
        should.exist $json.started._state
        $json.started._state.should.equal 'active'

      it 'have a limit', ->
        should.exist $json.started.limit
        $json.started.limit.should.equal thirtySecs

      it 'have an endTime and remaining', ->
        should.exist $json.started._endTime
        should.exist $json.started._remaining


    describe 'paused timers', ->
      it 'got serialized', ->
        should.exist $json.paused

      it 'have a state', ->
        should.exist $json.paused._state
        $json.paused._state.should.equal 'inactive.paused'

      it 'have a limit', ->
        should.exist $json.paused.limit
        $json.paused.limit.should.equal thirtySecs

      it 'have _remaining', ->
        should.exist $json.paused._remaining

      it 'not have _endTime', ->
        should.not.exist $json.paused._endTime


  describe 'initializing the timer', ->

    describe 'stopped timers', ->
      before ->
        @timer = new Models.Timer($json.stopped)

      it 'have received their state', ->
        @timer.state().path().should.equal 'inactive.stopped'

      it 'should have all their correct attributes', ->
        @timer.limit.should.equal thirtySecs
        should.not.exist @timer._endTime
        should.not.exist @timer._remaining

     describe 'started timers', ->
      before ->
        @timer = new Models.Timer($json.started)

      it 'have received their state', ->
        @timer.state().path().should.equal 'active'

      it 'should have all their correct attributes', ->
        @timer.limit.should.equal thirtySecs
        @timer._endTime.should.equal $json.started._endTime
        @timer._remaining.should.equal $json.started._remaining

     describe 'paused timers', ->
      before ->
        @timer = new Models.Timer($json.paused)

      it 'have received their state', ->
        @timer.state().path().should.equal 'inactive.paused'

      it 'should have all their correct attributes', ->
        @timer.limit.should.equal thirtySecs
        should.not.exist @timer._endTime
        @timer._remaining.should.equal $json.paused._remaining

  after ->
    @clock.restore()
