# Client-side entry point
# This gets processed with browserify to find straggling dependencies.
App = require('./app.coffee')

# Anchor libraries.
# We finally include jquery from bower here.
Backbone      = require("backbone")
Marionette    = require("backbone.marionette")
Backbone.$    = Marionette.$ = require("jquery")

App.addInitializer (opts) ->
  # Initialize the main content regions on the page.
  @addRegions
     mainRegion: "#"

conf = require('./config.client.coffee')
App.start(conf)
