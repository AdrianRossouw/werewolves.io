# State machine instances
#
# This module will manage the instances of the
# data models in the game world.
#
# The IO layer will listen for changes from
# this module, and views will manipulate it
# from the interface.
App      = require("../app")
Backbone = require('backbone')
Models   = require('../models')
State    = App.module "State",
  startWithParent: false

State.addInitializer (opts) ->
  @world ?= new Models.World()

# Noop implementations of some methods.
State.load = (data) ->
  @world ?= new Models.World(data)
  @trigger 'load', @

State.addFinalizer = ->

  process.exit(1)
  delete @world


module.exports = State
