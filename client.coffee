# Client-side entry point
# This gets processed with browserify to find straggling dependencies.
App = require('./app.coffee')
Views = require('./views.coffee')
window.App = App

# Anchor libraries.
# We finally include jquery from bower here.
Backbone      = require("backbone")
Marionette    = require("backbone.marionette")
Backbone.$    = Marionette.$ = require("jquery")

App.addInitializer (opts) ->
  # Initialize the main content regions on the page.
  ###
  @addRegions
   statusRegion: "#status"
   mainRegion: "#main"
   sidebarRegion: "#sidebar"
  ###


# Load up the state instances
State = require('./state.client.coffee')
App.addInitializer (opts) ->
  @trigger 'before:state', opts
  # We initialize this separately because
  # we don't want it to run just when included
  State.start(opts)
  @trigger 'state', opts


App.on 'state', (opts) ->
  @addRegions
    game: '#game'

  @gameView = new Views.Game el: $('#game')
  @gameView.render()

  #@gameLayout.contenders.show @contenders




conf = require('./config.client.coffee')
App.start(conf)
