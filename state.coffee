# State machine instances
#
# This module will manage the instances of the
# data models in the game world.
#
# The IO layer will listen for changes from
# this module, and views will manipulate it
# from the interface.
App      = require("./app.coffee")
Backbone = require('backbone')
State    = App.module "State",
  startWithParent: false

# Noop implementations of some methods.
State.load = ->
State.sync = ->

module.exports = State
