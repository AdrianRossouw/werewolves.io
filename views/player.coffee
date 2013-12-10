App = require('../app')
State = require('../state')

Backbone = require('backbone')

Views = App.module "Views"
Models = App.module "Models"

class Views.Opponent extends Backbone.Marionette.ItemView
  className: 'player'
  template: require('../templates/player.jade')

  serializeData: ->
    data = super
    data.state = @model.state().path().replace('.', ' ')
    data

  triggers:
    'click .alive.card': 'choose'

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

  onChoose: ->  @model.select()

class Views.Opponents extends Backbone.Marionette.CollectionView
  id: 'opponents'
  className: 'opponents'
  itemView: Views.Opponent


class Views.Player extends Backbone.Marionette.ItemView
  className: 'player'
  template: require('../templates/player.jade')
  modelEvents:
    'change': 'render'

  serializeData: ->
    data = super
    data.state = @model.state().path().replace('.', ' ')
    data

class Views.PlayerLog extends Backbone.Marionette.ItemView
  className: 'playerlog'

  template: require('../templates/playerlog.jade')

  serializeData: ->
    json =
      player: @model
      pages: pages

    json


