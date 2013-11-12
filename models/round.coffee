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
  initialize: (data = {}, opts = {}) ->
    @actions ?= new Models.Actions
    data.actions ?= []
    @actions.add data.actions

  toJSON: ->
    obj = super
    obj.actions = @actions.toJSON()
    obj

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

