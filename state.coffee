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
Models   = require('./models.coffee')
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

  @trigger 'load', data

  

State.sync = ->

module.exports = State
