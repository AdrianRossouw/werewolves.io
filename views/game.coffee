App = require('../app')
State = require('../state')

Backbone = require('backbone')

Views = App.module "Views"
Models = App.module "Models"


class Views.Game extends Backbone.Marionette.Layout
  id: 'game'
  className: 'game'
  template: require('../templates/game.jade')

  regions:
    main: "#main"
    player: "#player"
    round: "#round"

  initialize: (options) ->
    @gameState = options.game
    @worldState = options.world
    @playerState = options.player
    @opponentState = options.opponents
    super
    @

  onShow: ->
    @player.show new Views.Player
      model: @playerState

    @main.show new Views.Opponents
      collection: @opponentState
      player: @playerState

    @showCurrentRound()
    @makeActive()
    @listenTo @gameState.rounds, 'add', @showCurrentRound
    @listenTo @playerState, 'state', @makeActive

  makeActive: ->
    isAsleep = @playerState.state().isIn 'asleep'
    isDead = @playerState.state().is 'dead'
    isSpectator = @worldState.session.id != @playerState.id

    @$el.toggleClass('active', !isAsleep and !isDead and !isSpectator)


  # this is a no-op if there are no rounds yet.
  #
  # we pass all players, not just opponents, since
  # people can vote for you too.
  showCurrentRound: ->
    opts =
      model: @gameState.currentRound()
      players: @gameState.players
    
    @gameState.players.deselect()
    @round.show new Views.Round(opts) if opts.model

