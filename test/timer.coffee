# This test is built to confirm that the session
# state machine behaves as expected.

Models   = require('../models')
should   = require('should')
sinon    = require('sinon')
_ = require('underscore')

describe 'timer model', ->
  before ->
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
      @timer.limit = 30000
      @timer.limit.should.equal 30000

    it 'should always give me the deadline as $limit ms in the future', ->
      @timer.deadline().should.equal Date.now() + @timer.limit
      @clock.tick 60000
      @timer.deadline().should.equal Date.now() + @timer.limit

    it 'should always give me the remaining ms as the $limit', ->
      @timer.remaining().should.equal @timer.limit
      @clock.tick 60000
      @timer.remaining().should.equal @timer.limit

  describe 'starting the timer', ->
    before ->
      @timer.start()


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

      @clock.tick(5000) # 5 seconds ahead in time

    it 'should return the _endTime as the deadline', ->
      @timer.deadline().should.equal @timer._endTime

    it 'should subtract the time remaining correctly', ->
      @timer.remaining().should.equal 25000

    it 'should have emitted tick events', ->
      @spy.callCount.should.equal 5

    after ->
      @timer.off 'tick', @spy
      @clock.tick 5000 # move another 5 seconds up in time

  describe 'pausing the timer', ->
    before ->
      @deadline = @timer.deadline()
      @remaining = @timer.remaining()
      @timer.pause()

      @clock.tick 5000 # move another 5 seconds up in time

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
      @clock.tick 5000 # move another 5 seconds up in time
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
      @clock.tick(5000) # move another 5 seconds up in time

    it 'should return the _endTime as the deadline', ->
      @timer.deadline().should.equal @timer._endTime

    it 'should subtract the time remaining correctly', ->
      @timer.remaining().should.equal @remaining - 5000

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
      @clock.tick 5000 # move another 5 seconds up in time
      @timer.deadline().should.equal @timer.limit + Date.now()

  describe 'resetting the timer', ->
    before ->
      @timer.start()
      @clock.tick(10000)
      @timer.reset()

    it 'should still be active after being reset', ->
      @timer.state().path().should.equal 'active'

    it 'should have reset the remaining time', ->
      @timer.remaining().should.equal 30000
      @clock.tick 5000
      @timer.remaining().should.equal 25000

    it 'should always return the _endTime as the deadline()', ->
      @timer.deadline().should.equal @timer._endTime
      @clock.tick 5000
      @timer.deadline().should.equal @timer._endTime

  describe 'trigger the timeout', ->
    before ->
      @spy = sinon.spy()
      @timer.on 'end', @spy
      @clock.tick(20000)

    it 'should have triggered the end event', ->
      @spy.called.should.be.ok

    it 'should be in stopped state', ->
      @timer.state().path().should.equal 'inactive.stopped'

    after ->
      @timer.off 'end', @spy

  after ->
    @clock.restore()
