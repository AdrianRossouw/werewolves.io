App = require('../app')
State = require('../state')

Backbone = require('backbone')

Views = App.module "Views"
Models = App.module "Models"

getContestants = (players, round) ->
  grouped = round.actions.chain()
   .where(action: 'lynch')
   .groupBy('target')
   .map((val, key) -> [key, val])
   .sortBy((o) -> -o[1].length)
   .object()
   .value()
  contestants = new Backbone.Collection
  for grouper, votes of grouped
    player = players.get grouper
    player.votes = new Backbone.Collection
    for vote in votes
      player.votes.add players.get vote.id
    contestants.add player
  contestants

class Views.Game extends Backbone.Marionette.ItemView
  template: require('../templates/game.jade')

  ui:
    main: "#main"
    player: "#player"
    sidebar: "#sidebar"

  onRender: ->
    @players = State.world.game.players
    @listenTo @players, 'add', @syncPlayersView
    @listenTo @players, 'delete', @syncPlayersView

    @syncPlayersView()

    @statusView = new Views.Status el: @ui.status
    @playerView = new Views.Player model: State.session.player, el: @ui.player

    @playersView.render()
    @playerView.render()

    @syncRound()
    # TODO: change round sync round again

    this

  syncPlayersView: ->
    @playersView.close() if @playersView

    # TODO: move to server
    for player, i in @players.models
      player.set 'number', i+1

    others = @players.filter (p) =>
      p.id != State.session.player.id
    otherPlayers = new Backbone.Collection others

    @playersView = new Views.Players collection: otherPlayers
    @ui.main.append @playersView.render().el

  syncRound: ->
    @stopListening @round.actions if @round

    @round = State.world.game.rounds.last()
    @listenTo @round.actions, 'add', @syncRoundView
    @listenTo @round.actions, 'delete', @syncRoundView
    @listenTo @round.actions, 'change', @syncRoundView

    @syncRoundView()

  syncRoundView: (a, b, c)->
    contestants = getContestants(@players, @round)
    @roundView.close() if @roundView
    @roundView = new Views.Round collection: contestants
    @ui.sidebar.append @roundView.render().el

class Views.Status extends Backbone.Marionette.ItemView
  render: -> this

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
    json.me = @model.id == State.session.player.id
    #json.selected = @model.collection.selected == @model
    json

class Views.Players extends Backbone.Marionette.CollectionView
  className: 'players'

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

  template: require('../templates/contestant.jade')

  itemView: Views.Voter

  itemViewContainer: '.votes'

class Views.Round extends Backbone.Marionette.CollectionView
  className: 'round'

  itemView: Views.Contestant

  buildItemView: (item, ItemView) ->
    view = new Views.Contestant model: item, collection: item.votes
    view

# also: GameLog

class Views.PlayerLog extends Backbone.Marionette.ItemView
  className: 'playerlog'

  template: require('../templates/playerlog.jade')

  serializeData: ->
    json =
      player: @model
      pages: pages

    json


module.exports = Views
