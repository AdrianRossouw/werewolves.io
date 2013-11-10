App = require('./app.coffee')
State = require('./state.client.coffee')

Backbone = require('backbone')

Views = App.module "Views"
Models = App.module "Models"

getContestants = (players, round) ->
  grouped = round.actions.groupBy('target')
  contestants = new Backbone.Collection
  for grouper, votes of grouped
    player = players.findWhere name: grouper
    player.votes = new Backbone.Collection
    for vote in votes
      player.votes.add players.findWhere name: vote.get('player')
    contestants.add player
  contestants

class Views.Game extends Backbone.Marionette.ItemView
  template: require('./templates/game.jade')

  ui:
    players: "#players"
    player: "#player"
    round: "#round"

  onRender: ->
    console.clear()
    players = State.world.game.players
    for player, i in players.models
      player.set 'number', i+1
    others = players.filter (p) =>
      p.name != State.world.game.player.name
    otherPlayers = new Backbone.Collection others

    round = App.State.world.game.rounds.last()
    contestants = getContestants(players, round)

    @status = new Views.Status el: @ui.status
    @players = new Views.Players collection: otherPlayers, el: @ui.players
    @player = new Views.Player model: State.world.game.player, el: @ui.player
    @round = new Views.Round collection: contestants, el: @ui.round

    @status.render()
    @players.render()
    @player.render()
    @round.render()

    this


class Views.Status extends Backbone.Marionette.ItemView
  render: -> this

class Views.Player extends Backbone.Marionette.ItemView
  className: 'player'

  template: require('./templates/player.jade')

  serializeData: ->
    json = super
    json.me = @model.name == App.State.world.game.player.name
    json

class Views.Players extends Backbone.Marionette.CollectionView
  itemView: Views.Player

class Views.Voter extends Backbone.Marionette.ItemView
  className: ->
    number = @model.get 'number'
    "vote color-#{number}"

  render: ->
    @$el.attr 'title', @model.name
    this

class Views.Contestant extends Backbone.Marionette.CompositeView
  className: 'contestant'

  template: require('./templates/contestant.jade')

  itemView: Views.Voter

  itemViewContainer: '.votes'

class Views.Round extends Backbone.Marionette.CollectionView
  className: 'round'

  itemView: Views.Contestant

  buildItemView: (item, ItemView) ->
    view = new Views.Contestant model: item, collection: item.votes
    view

module.exports = Views
