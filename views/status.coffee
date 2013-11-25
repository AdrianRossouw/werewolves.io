App = require('../app')
State = require('../state')

Backbone = require('backbone')

Views = App.module "Views"
Models = App.module "Models"
State = App.module "State"

# Status line view
#
# Prints out based on the current world state
# (which is passed in as it's model)
class Views.Status extends Backbone.Marionette.ItemView
  id: 'status',
  template: =>
    @status()
  onShow: ->
    @listenTo State, 'state', @render

  status: ->
    switch @model.state().name
      when 'attract' then 'waiting for players'
      when 'startup' then @gameStatus()
      when 'gameplay' then @gameStatus()
      when 'cleanup' then 'game ending'
      else ''

  gameStatus: ->
    players = @model.game.players.length
    switch @model.game.state().path()
      when 'recruit.waiting' then "#{players} players. #{7 - players} more needed."
      when 'recruit.ready' then "Starting game with #{players} players."
      when 'round.firstNight' then "First night. #{@playerStatus()}"
      when 'round.firstDay' then "First day. #{@playerStatus()}"
      when 'round.night' then "Nightime. #{@playerStatus()}"
      when 'round.day' then "Daytime. #{@playerStatus()}"
      when 'victory.werewolves' then "Werewolves win!"
      when 'victory.villagers' then "Villagers win!"
      when 'cleanup' then 'Game over!'
      else ''

  playerStatus: ->
    player = State.getPlayer()
    switch player.state().path()
      when 'dead' then 'You are dead.'
      when 'alive.day.lynching' then 'Lynch someone.'
      when 'alive.night.asleep' then 'You are asleep.'
      when 'alive.night.eating' then 'Pick someone to eat.'
      when 'alive.night.seeing' then 'Have a dream about someone.'
      else ''
