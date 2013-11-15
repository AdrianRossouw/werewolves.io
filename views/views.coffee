App = require('../app')
State = require('../state')

Backbone = require('backbone')

Views = App.module "Views"
Models = App.module "Models"

require('./player.coffee')
require('./round.coffee')
require('./game.coffee')

module.exports = Views
