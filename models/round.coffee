App      = require('../app')
state    = require('state')
_        = require('underscore')
Backbone = require('backbone')
Models   = App.module "Models"


class Models.Action extends Models.BaseModel
  @attribute 'action'
  @attribute 'target'

class Models.Actions extends Backbone.Collection
  model: Models.Action

class Models.Round extends Models.BaseModel
  @attribute 'death'
  @attribute 'phase'
  @attribute 'number'
  @attribute 'activeTotal'

  initialize: (data = {}, opts = {}) ->
    super
    @id = data.id or App.ns.uuid()
    @actions = new Models.Actions data.actions or []

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
    startup: state 'initial'

    votes: state 'abstract',
      # waiting for the first vote to be cast
      none: state 'default',
        admit:
          '*': -> !@owner.actions.length

      # we have  votes
      some:
        admit:
          '*': -> (1 <= @owner.actions.length <= @owner.activeTotal)

      all:
        admit:
          '*': -> @owner.actions.length == @owner.activeTotal
        
    counted:
      # only admit full votes
      admit:
        'votes.all': true


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
    #_.debounce State.world.game.endRound, 150000
    

class Models.Rounds extends Backbone.Collection
  model: Models.Round
