App = require('../app')
State = require('../state')

Backbone = require('backbone')

Views = App.module "Views"
Models = App.module "Models"

class Views.Opponents extends Backbone.Marionette.CollectionView
  id: 'opponents'

  itemView: Views.Opponent

class Views.Opponent extends Backbone.Marionette.ItemView
  className: 'player'
  template: require('../templates/player.jade')

  events:
    click: 'choose'

  modelEvents:
    'change': 'render'
    'selected': 'selected'
    'deselected': 'deselected'

  initialize: ->
    @listenTo @model, 'selected', @selected
    @listenTo @model, 'deselected', @deselected

  selected: ->
    @$el.addClass 'selected'

  deselected: ->
    @$el.removeClass 'selected'

  choose: ->
    return if @model.id == State.world.session.player.id
    # TODO: also don't allow choose when you're not allowed to vote
    @model.collection.select @model


class Views.Player extends Backbone.Marionette.ItemView
  className: 'player'

  template: require('../templates/player.jade')
  modelEvents:
    'change': 'render'





class Views.PlayerLog extends Backbone.Marionette.ItemView
  className: 'playerlog'

  template: require('../templates/playerlog.jade')

  serializeData: ->
    json =
      player: @model
      pages: pages

    json


