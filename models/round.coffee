App      = require('../app')
state    = require('state')
_        = require('underscore')
Backbone = require('backbone')
Models   = App.module "Models"


class Models.Action extends Models.BaseModel
  urlRoot: 'action'
  @attribute 'action'
  @attribute 'target'

class Models.Actions extends Backbone.Collection
  model: Models.Action

class Models.Round extends Models.BaseModel
  urlRoot: 'round'
  @attribute 'death'
  @attribute 'phase'
  @attribute 'number'
  @attribute 'activeTotal'

  initialize: (data = {}, opts = {}) ->
    @id = data.id or App.ns.uuid()
    super
    @actions = new Models.Actions []
    @state().change(data._state or 'startup')
    @actions.reset data.actions if data.actions

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
    startup: {}

    votes: state 'abstract',
      # waiting for the first vote to be cast
      none: state 'default',
        admit:
          '*': -> !@owner.actions.length

      # we have  votes
      some:
        admit:
          '*': -> (1 <= @owner.actions.length <= @owner.activeTotal)
        arrive: ->
          @firstVotes = Date.now()

      all:
        admit:
          '*': -> @owner.actions.length == @owner.activeTotal
        
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

  choose: (me, actionName, target, opts = {}) ->
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

    @voteState()
    

class Models.Rounds extends Backbone.Collection
  model: Models.Round
