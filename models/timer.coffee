App      = require('../app')
state    = require('state')
_        = require('underscore')
Backbone = require('backbone')
debug    = require('debug')('werewolves:model:timer')
Models   = App.module "Models"


# World timer object.
#
# the timer is a singleton object attached to the
# world, that allows us to centralize and sync the
# game's timed events.
#
# By having it a separate model, we also allow the
# interface to represent it as a countdown, giving
# valuable feedback on how long the round will go on.


class Models.Timer extends Models.BaseModel
  url: 'timer'
  @attribute 'limit'
  
  # this is sort of private.
  # it should never be set directly, as
  # the timer model will overwrite it the
  # whole time.
  @attribute '_endTime'
  @attribute '_remaining'

  initialize: (data = {}) ->
    @limit = data.limit or 0
    @_endTime ?= data._endTime
    @_remaining ?= data._remaining
    super
    @state().change(data._state or 'stopped')
    @trigger('state', @state().path())
    @publish()

  toJSON: (session) ->
    json = super
    json._state = @state().path()
    json

  destroy: ->
    super
    @stopListening()
    @off
    
  # return the ms remaining on the counter.
  remaining: -> @limit

  # return the time when the counter will (would?) end.
  deadline: -> Date.now() + @remaining()

  ## section: methods
  # start the countdown.
  start: ->
    @go('active')

  # pause the coundown where it is
  pause: -> @go('paused')

  # resume the countdown (alias for start)
  resume: -> @start()

  # stop the countdown and reset to 0.
  stop: -> @go('stopped')
  
  # reset the countdown
  reset: ->
    before = @state().name
    @stop()
    @start() if before is 'active'

  # end the timer, triggering the 'end' event
  end: =>
    @stop()
    @trigger 'end'

  # while running, trigger a tick event every second
  #
  # allows us to tie the interface to the progression
  # of time.
  tick: =>
    @trigger 'tick', @remaining()

  ## section: state machine
  initState: ->
    state @,
      # timer is frozen
      inactive: state 'abstract default',
        
        # remaining time reset.
        # only allow leaving this state if there is a limit.
        stopped: state 'default',
          arrive: ->
            @unset('_endTime') if @_endTime
            @unset('_remaining') if @_remaining

          release:
            active: -> !!@owner.limit

          exit: ->
            @_remaining = @limit

        # remaining time kept.
        paused:
          remaining: -> @_remaining


      # timer is running
      active:
        # calculate the deadline based on
        # time remaining.
        arrive: ->
          @_interval = setInterval @tick, 100
          @_timeout = setTimeout @end, @_remaining
          @_endTime ?= Date.now() + @_remaining

        deadline: -> @_endTime
        remaining: -> @_endTime - Date.now()

        # this countdown has run out,
        # and needs to be restarted.
        exit: ->
          @_remaining = @_endTime - Date.now()
          @unset('_endTime')

          clearTimeout @_timeout
          delete @_timeout

          clearInterval @_interval
          delete @_interval
