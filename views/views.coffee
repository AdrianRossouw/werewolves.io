App = require('../app')
State = require('../state')

Backbone = require('backbone')

Views = App.module "Views"
Models = App.module "Models"

# Pass the actual models through to the templates
#
# Let's not pussy-foot around the fact that it's utterly
# ridiculous to rely on only the serialized versions of the data
# objects to render templates, and avoid building millions
# upon millions of levels of indirection to stop ourselves
# from being allowed to type myvariable().
#
# that is all.
class Backbone.Marionette.ItemView extends Backbone.Marionette.ItemView
  serializeData: ->
    json = super
    json.model      ?= @model
    json.collection ?= @collection
    json.options    ?= @options
    json

class Backbone.Marionette.Layout extends Backbone.Marionette.Layout
  serializeData: ->
    json = super
    json.model      ?= @model
    json.collection ?= @collection
    json.options    ?= @options
    json

require('./status.coffee')
require('./timer.coffee')
require('./player.coffee')
require('./round.coffee')
require('./game.coffee')

module.exports = Views
