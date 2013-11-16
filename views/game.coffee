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

class Views.Status extends Backbone.Marionette.ItemView
  render: -> this

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
    @playersView.render()

    player = State.session.player or @players.first()
   
    if player
      @playerView = new Views.Player
          model: player
          el: @ui.player

      @playerView.render()

    if State.world.state().isIn('gameplay')
        @syncRound()
    this

  syncPlayersView: ->
    @playersView.close() if @playersView

    # TODO: move to server
    for player, i in @players.models
      player.set 'number', i+1



    # is the currently active session even playing along?
    sesPlayer = State.session.player or @players.first()
    others = @players.filter (p) =>
      p.id != sesPlayer.id

    players = new Backbone.Collection others

    @playersView = new Views.Players collection: players
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
