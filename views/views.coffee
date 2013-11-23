App = require('../app')
State = require('../state')

Backbone = require('backbone')

Views = App.module "Views"
Models = App.module "Models"

# Status line view
#
# Prints out based on the current world state
# (which is passed in as it's model)
class Views.Status extends Backbone.Marionette.ItemView
  id: 'status',
  template: _.template "<%=status%>"

require('./player.coffee')
require('./round.coffee')
require('./game.coffee')

module.exports = Views
