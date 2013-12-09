App      = require('../app')
state    = require('state')
debug    = require('debug')('werewolves:model:round')
_        = require('underscore')
Backbone = require('backbone')
Models   = App.module "Models"
State    = App.module "State"


class Models.Action extends Models.BaseModel
  urlRoot: 'action'
  @attribute 'action'
  @attribute 'target'
  initialize: ->
    super
    @publish()

class Models.Actions extends Models.BaseCollection
  url: 'action'
  model: Models.Action

class Models.Round extends Models.BaseModel
  urlRoot: 'round'
  @attribute 'death'
  @attribute 'phase'
  @attribute 'number'
  @attribute 'activeTotal'
  initialize: (data = {}, opts = {}) ->
    @timer = State.getTimer()
    @id = data.id or App.ns.uuid()
    @players ?= opts.players
    @actions = new Models.Actions []
    @actions.reset data.actions if data.actions
    @timer.limit = @activeTotal * 30000
    super
    @state().change(data._state or 'votes.none')
    @publish()

    @listenTo @timer, 'end', @endPhase

  destroy: ->
    @stopListening @timer

    super
    delete @players

    @actions.destroy()
    delete @actions

  voteState: ->
    @state('-> votes.none')
    @state('-> votes.some')
    @state('-> votes.all')

  toJSON: ->
    obj = super
    obj.actions = @actions.toJSON()
    obj

  endPhase: ->
    @state().change('complete.died')
    @state().change('complete.survived')

  initState: -> state @,
    votes: state 'abstract',
      admit:
          'complete.*': false

      # waiting for the first vote to be cast
      none: state 'default',
        admit:
          '*': -> !@owner.actions.length
        arrive: ->
          @timer.start()

      # we have  votes
      some:
        admit:
          'none': -> (1 <= @owner.actions.length <= @owner.activeTotal)

      # we have all the votes
      all:
        enter: ->
          if @timer.remaining() >= 30000
            @timer.limit = 30000
            @timer.reset()
        admit:
          'some': -> @owner.actions.length == @owner.activeTotal

    complete: state 'conclusive',
      enter: ->
        @death = @getDeath()
      # there is a death
      died: state 'final',
        admit:
          'votes.all': -> !!@owner.getDeath()
          'complete.*': false

      # there wasn't one
      survived: state 'final',
        admit:
          'votes.all': -> !@owner.getDeath()
          'complete.*': false

  # transform an array of actions into a single
  # array of votes (player id only), indexed
  # by who they voted for
  getVotes: ->
    action = if @phase is 'day' then 'lynch' else 'eat'
    byTarget      = (a)    -> a.target
    sortByLength  = (a)    -> -a.votes?.length
    makeArray     = (v, k) ->
      id: k,
      votes: _(v).pluck('id')

    @actions.chain()
      .where(action: action)
      .groupBy(byTarget)
      .map(makeArray)
      .sortBy(sortByLength)
      .value()

  # Do a simple transform on the votes to give us
  # the vote count instead of a list of people who
  # voted for them.
  countVotes: ->
    _(@getVotes()).map (v) ->
      _.extend {}, v, votes: v.votes.length

  # make sure there is only a single victim of the
  # voting / eating process.
  #
  # returns the player id meant to die,
  # otherwise returns false for draws.
  getDeath: ->
    votes    = @countVotes()
    victim   =  _(votes).first()
    top      = _(votes).where votes: victim.votes
    return if top.length == 1 then victim.id else false


  # Pick a victim to kill.
  choose: (me, target, opts = {}) ->
    player = State.getPlayer me
    actionName = player.voteAction()

    if !actionName
      debug 'player cant do this'
      return false

    debug 'choose', me, target, actionName

    action = @actions.findWhere
      id:me
      action:actionName
    
    if not action
      action ?=
        id:me
        action:actionName
        target:target

      @actions.add action, opts
    else
      action.set
        target: target

    debug "change vote state", action
    @voteState()

class Models.Rounds extends Models.BaseCollection
  url: 'round'
  model: Models.Round
