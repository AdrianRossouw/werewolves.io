App      = require('../app')
state    = require('state')
_        = require('underscore')
Backbone = require('backbone')
Models   = App.module "Models"


class Models.Action extends Models.BaseModel
  @attribute 'action'
  @attribute 'target'
  @attribute 'timeCast'

class Models.Actions extends Backbone.Collection
  model: Models.Action


class Models.Round extends Models.BaseModel
  @attribute 'death'
  @attribute 'phase'
  @attribute 'maxVotes'

  initialize: (data = {}, opts = {}) ->
    super
    @actions = new Models.Actions data.actions or []

  toJSON: ->
    obj = super
    obj.actions = @actions.toJSON()
    obj
    
  initState: -> state @,
    # waiting for the first vote to be cast
    noVotes: {},
    # we have enough votes
    someVotes: {}
    allVotes: {}
  

  choose: (me, actionName, target, opts = {}) ->
    action = @actions.findWhere
      id:me
      action:actionName

    if not action
      action ?=
        id:me
        action:actionName
        target:target
        timeCast: Date.now()

      @actions.add action, opts
    else
      action.set
        target: target
        timeCast: Date.now()

    #_.debounce State.world.game.endRound, 150000
    

class Models.Rounds extends Backbone.Collection
  model: Models.Round
