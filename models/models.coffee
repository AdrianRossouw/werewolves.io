# Shared model code.
#
# These form the base agreed upon data structures that will be extended
# by the front-end and/or backend.
App      = require('../app')
Backbone = require('backbone')
_        = require('underscore')
state    = require('state')
Models   = App.module "Models"


# Create model attribute getter/setter property.
# From : http://srackham.wordpress.com/2011/10/16/getters-and-setters-for-backbone-model-attributes/
class Models.BaseModel extends Backbone.Model
  _attributes: []
  toState: (state) ->
    @state('-> %{state}')
    @triggerState state

  triggerState: (state) ->
    @trigger 'state', state

  initialize: (attrs = {}, options = {}) ->
    @initAttribute attr, val for val, attr in attrs

  initAttribute: (attr, value) ->
    @set(attr, value)

  @attribute = (attr) ->
    @_attributes ?= []
    @_attributes.push attr
    Object.defineProperty @prototype, attr,
      get: -> @get attr
      set: (value) ->
        attrs = {}
        attrs[attr] = value
        @set attrs


require('./session.coffee')
require('./player.coffee')
require('./round.coffee')
require('./game.coffee')
require('./world.coffee')

module.exports = Models
