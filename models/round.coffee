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

  initialize: (data = {}, opts = {}) ->
    @id = data.id or App.ns.uuid()
    super
    @actions = new Models.Actions []
    @players = opts.players
    @actions.reset data.actions if data.actions
    @state().change(data._state or 'votes.none')
    @listenTo @state('votes.all'), 'arrive', @endPhase

    @publish()

  destroy: ->
    super

    delete @players

    @actions.destroy()
    delete @actions

  voteState: ->
    @lastChoice = Date.now()

    @state('-> votes.none')
    @state('-> votes.some')
    @state('-> votes.all')
  
  toJSON: ->
    obj = super
    obj.actions = @actions.toJSON()
    obj
  initState: -> state @,
    votes: state 'abstract',
      # waiting for the first vote to be cast
      none: state 'default',
        admit:
          '*': -> !@owner.actions.length

      # we have  votes
      some:
        admit:
          'none': ->
            activeTotal = @owner.players.activeTotal()
            (1 <= @owner.actions.length <= activeTotal)

        arrive: ->
          @firstVotes = Date.now()

      all:
        admit:
          '': -> true
          'some': ->
            activeTotal = @owner.players.activeTotal()
            @owner.actions.length == activeTotal

    complete: state 'conclusive',
      # there is a death
      died: state 'final',
        arrive: ->
          @death = @getDeath()
          @players.kill @death
        admit:
          'votes.all': -> @owner.getDeath()

      # there wasn't one
      survived: state 'final',
        admit:
          'votes.all': -> !@owner.getDeath()

  endPhase: ->
    @state().change('complete.died')
    @state().change('complete.survived')

  countVotes: ->
    action = if @phase is 'day' then 'lynch' else 'eat'

    byTarget      = (a)    -> a.target
    toLengthList  = (l, k) -> { id: k, votes: l.length }
    sortByLength  = (a)    -> -a.length

    @actions.chain()
      .where(action: action)
      .groupBy(byTarget)
      .map(toLengthList)
      .sortBy(sortByLength)
      .value()

  getDeath: ->
    votes    = @countVotes()
    victim   =  _(votes).first()
    top      = _(votes).where votes: victim.votes
    return if top.length == 1 then victim.id else false

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
