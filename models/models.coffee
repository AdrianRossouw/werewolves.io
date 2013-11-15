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

  initialize: (attrs = {}, options = {}) ->
    @initState()
    @initAttribute attr, val for val, attr in attrs
    @publish()

  destroy: ->
    @unpublish()

  initState: ->
  mask: -> @
  publish:  -> @
  toJSON: ->
    obj = super
    obj._state = @state().path() if @state
    obj

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
