# Base logic for the entire werewolves.io application stack
#
# This file is the entry point for all the shared code that the application uses.
# Each of the entry points (server.coffee/client.coffee) start off by including
# this file.
#
# It returns a backbone.marionette application object, that will be started separately
# after all the code has been loaded.

# All the dependencies used across the whole system
Backbone   = require("backbone")
Marionette = require("backbone.marionette")
Deferred   = require("underscore.deferred")
Nonsense   = require('Nonsense')
_          = require("underscore")

# Marionette needs an implementation of jquery.deferred to run.
Backbone.$ = Marionette.$ = ->

_.extend Marionette.$, Deferred
_.extend Backbone.$, Deferred
_.mixin Deferred

# Start the new marionette application
App = new Marionette.Application()

# generates useful 'random' values
App.ns = new Nonsense()

App.stop = ->
  _(@submodules).invoke 'stop'
  @trigger 'before:stop'
  @_initCallbacks.reset()
  @trigger 'stop'

module.exports = App
