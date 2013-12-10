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

  initialize: (attrs = {}, options = {}) ->
    @initState()

  destroy: ->
    @unpublish()

  go: (to) ->
    @state().go(to) if App.server

  initState: ->
  mask: (session) -> @toJSON()
  publish:  -> @
  getUrl: -> _.result @, 'url'
  toJSON: ->
    obj = super
    obj.id = @id if @id
    obj._state = @state().path() if @state
    obj


  @attribute = (attr) ->
    Object.defineProperty @prototype, attr,
      get: -> @get attr
      set: (value) ->
        attrs = {}
        attrs[attr] = value
        @set attrs

# Create model attribute getter/setter property.
# From : http://srackham.wordpress.com/2011/10/16/getters-and-setters-for-backbone-model-attributes/
class Models.BaseCollection extends Backbone.Collection

  initialize: (records = {}, options = {}) ->
    super
    @publish()

  destroy: ->
    @unpublish()

  initState: ->
  mask: (session) -> @toJSON()
  publish:  -> @
  unpublish:  -> @

require('./timer.coffee')
require('./session.coffee')
require('./player.coffee')
require('./round.coffee')
require('./game.coffee')
require('./world.coffee')

module.exports = Models
