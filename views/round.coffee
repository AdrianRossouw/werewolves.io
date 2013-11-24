Backbone = require('backbone')
App = require('../app')
Views = App.module "Views"

# Renders the current voting summary block in the sidebar
#
# This uses the helper method on the round model, that
# collates and builds a map of player id's that are used.
#
# We then pass in the players collection to the template too,
# so it can fetch the player properties out of there using
# the indexes
class Views.Round extends Backbone.Marionette.ItemView
  className: 'round'
  template: require('../templates/round.jade')

  initialize: (options) ->
    super
    @players ?= options.players
    @

  # pass the players as a top level variable
  # to the template.
  serializeData: ->
    json = super
    json.targets = @model.getVotes()
    json.players = @players
    json


  # re-render whenever the actions get modified
  # you can only ever modify or add a new vote
  onShow: ->
    @listenTo @model.actions, 'add', @render
    @listenTo @model.actions, 'change', @render
