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
    super
    @

  onShow: ->
    @player.show new Views.Player
      model: @playerState

    # TODO: filter through a decorator
    @main.show new Views.Opponents
      collection: @gameState.players

    # this is a no-op if there are no rounds yet.
    @showCurrentRound()
    @listenTo @gameState.rounds, 'add', @showCurrentRound


  showCurrentRound: ->
    opts =
      model: @gameState.currentRound()
      players: @gameState.players
    
    @round.show new Views.Round(opts) if opts.model

  onClose: ->
    @stopListening()
