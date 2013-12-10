App = require('../app')
State = require('../state')

Backbone = require('backbone')

Views = App.module "Views"
Models = App.module "Models"

class Views.Player extends Backbone.Marionette.ItemView
  className: 'player'
  template: require('../templates/player.jade')
  modelEvents:
    'change': 'render'
    'state': 'render'

  serializeData: ->
    data = super
    data.stateClass = @model.state().path().replace(/\./g,' ')
    data

class Views.Opponent extends Views.Player
  triggers:
    'click .alive.card': 'choose'

  modelEvents:
    'change': 'render'
    'state': 'render'
    'selected': 'selected'
    'deselected': 'deselected'

  initialize: (opts) ->
    @player = opts.player if opts.player

    @listenTo @model, 'selected', @selected
    @listenTo @model, 'deselected', @deselected

  selected: ->
    @$el.addClass 'selected'

  deselected: ->
    @$el.removeClass 'selected'

  onChoose: ->
    player = State.getPlayer()
    isIn = player.state().isIn.bind(player.state())

    @model.select() if (isIn('lynching') or isIn('eating') or isIn('seeing'))

class Views.Opponents extends Backbone.Marionette.CollectionView
  id: 'opponents'
  className: 'opponents'
  itemView: Views.Opponent


class Views.PlayerLog extends Backbone.Marionette.ItemView
  className: 'playerlog'

  template: require('../templates/playerlog.jade')

  serializeData: ->
    json =
      player: @model
      pages: pages

    json


