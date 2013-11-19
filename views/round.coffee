App = require('../app')
State = require('../state')

Backbone = require('backbone')

Views = App.module "Views"
Models = App.module "Models"


class Views.Player extends Backbone.Marionette.ItemView
  className: 'player'

  template: require('../templates/player.jade')

  events:
    click: 'choose'

  initialize: ->
    @listenTo @model, 'selected', @selected
    @listenTo @model, 'deselected', @deselected

  selected: ->
    @$el.addClass 'selected'

  deselected: ->
    @$el.removeClass 'selected'

  choose: ->
    player = State.world.session.player or @model.collection.first()
    return if @model.id == player.id
    # TODO: also don't allow choose when you're not allowed to vote
    @model.collection.select @model

  serializeData: ->
    json = super
    player = State.world.session.player or @model.collection.first()
    json.me = @model.id == player.id
    #json.selected = @model.collection.selected == @model
    json

class Views.Players extends Backbone.Marionette.CollectionView
  className: 'players'

  itemView: Views.Player

