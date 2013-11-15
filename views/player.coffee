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
    return if @model.id == State.session.player.id
    # TODO: also don't allow choose when you're not allowed to vote
    @model.collection.select @model

  serializeData: ->
    json = super
    if State.session.player.id
      json.me = @model.id == State.session.player.id
    #json.selected = @model.collection.selected == @model
    json

class Views.Players extends Backbone.Marionette.CollectionView
  className: 'players'

  itemView: Views.Player

class Views.PlayerLog extends Backbone.Marionette.ItemView
  className: 'playerlog'

  template: require('../templates/playerlog.jade')

  serializeData: ->
    json =
      player: @model
      pages: pages

    json


