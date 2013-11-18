module.exports = (log) ->
  log 'hey there?'
  ###
  Backbone = require('backbone')
  _ = require('underscore')
  Deferred = require('underscore.deferred')

  State = App.module 'State'
  log(State.session)
  _.delay State.world.game.joinGame, 10000
  ###
  
  return '123'
  
