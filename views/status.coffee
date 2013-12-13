App = require('../app')
State = require('../state')
debug = require('debug')('werewolves:view:status')
Backbone = require('backbone')

Views = App.module "Views"
Models = App.module "Models"
State = App.module "State"

# Status line view
#
# Prints out based on the current world state
# (which is passed in as it's model)
class Views.Status extends Backbone.Marionette.Layout
  id: 'status'
  template: require('../templates/status.jade')

  # the timer is directly tied to a model, so we
  # should segregate it into it's own view.
  regions:
    timer: '#timer'

  # these are such simple text strings,
  # that we shouldn't really go through
  # the trouble to put them in a real view.
  ui:
    action: '.action'
    game: '.game'
    player: '.player'
    round: '.round'


  onShow: ->
    @updateStatus()

    @listenTo State, 'state data', @updateStatus
    @timer.show new Views.Timer
      model: @model.timer

  updateStatus: ->
    @actionStatus()
    @gameStatus()
    @playerStatus()
    @roundStatus()
    @$el.find('.last').removeClass('last')
    @$el.find('.status:visible').eq(-1).addClass('last')
    @$el.find('.first').removeClass('first')
    @$el.find('.status:visible').eq(-1).addClass('first')

  actionStatus: ->
    text = switch @model.state().name
      when 'attract' then 'waiting for players'
      else null

    text ?= switch @model.game.state().path()
      when 'recruit.waiting' then 'starting game'
      when 'recruit.ready' then 'starting game'
      else null

    player = State.getPlayer()
    text ?= switch player?.state?().path()
      when 'alive.day.lynching' then 'lynch the wolves'
      when 'alive.night.eating' then 'pick your victim'
      when 'alive.night.seeing' then 'dream of someone'
      else null
 
    return this.ui.action.hide() if !text
    this.ui.action.html(text).show()

  gameStatus: ->
    players = @model.game.players.length
    text = switch @model.game.state().path()
      when 'recruit.waiting' then "#{7 - players} players needed"
      when 'recruit.ready' then "#{players} players"
      when 'victory.werewolves' then "werewolves win"
      when 'victory.villagers' then "villagers win"
      else null
    return this.ui.game.hide() if !text
    return this.ui.game.html(text).show()

  playerStatus: ->
    player = State.getPlayer()

    text = switch player?.state?().path()
      when 'dead' then 'dead'
      when 'alive.day.lynching' then 'awake'
      when 'alive.night.eating' then 'awake'
      when 'alive.night.seeing' then 'awake'
      when 'alive.night.asleep' then 'asleep'
      else null

    text = null if !@model.state().is('gameplay')

    return this.ui.player.hide() if !text
    return this.ui.player.html(text).show()

  roundStatus: ->
    text = switch @model.game.state().path()
      when 'round.firstNight' then "first night"
      when 'round.firstDay' then "first day"
      when 'round.night' then "night"
      when 'round.day' then "day"
      else null

    return this.ui.round.hide() if !text
    this.ui.round.html(text).show()
