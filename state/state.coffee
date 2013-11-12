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

# Noop implementations of some methods.
State.load = (data) ->
  
  @world ?= new Models.World()
  @world.sessions ?= new Models.Sessions()
  @world.game = new Models.Game data
  @world.game.players = new Models.Players data.players
  @world.game.rounds = new Backbone.Collection data.rounds,
    model: Models.Round

  @trigger 'load', @


State.sync = ->

module.exports = State
