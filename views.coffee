App = require('./app.coffee')
State = require('./state.client.coffee')

Backbone = require('backbone')

Views = App.module "Views"

class Views.Game extends Backbone.Marionette.ItemView
  template: require('./templates/game.jade')

  ui:
    players: "#players"
    player: "#player"
    contenders: "#contenders"

  onRender: ->
    for player, i in State.world.game.players.models
      player.set 'number', i+1
    others = State.world.game.players.filter (p) =>
      #p.get('name') != State.player.get('name')
      p.name != State.player.name
    otherPlayers = new Backbone.Collection others


    @status = new Views.Status el: @ui.status
    @players = new Views.Players collection: otherPlayers, el: @ui.players
    @player = new Views.Player model: State.player, el: @ui.player, me: true

    @status.render()
    @players.render()
    @player.render()

    this


class Views.Status extends Backbone.Marionette.ItemView
  render: -> this

class Views.Player extends Backbone.Marionette.ItemView
  className: 'player'

  template: require('./templates/player.jade')

  initialize: (options)->
    @me = options.me ? false

  serializeData: ->
    json = super
    json.me = @me
    json

class Views.Players extends Backbone.Marionette.CollectionView
  itemView: Views.Player


module.exports = Views
