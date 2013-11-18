phantom = require("node-phantom")
_ = require('underscore')

runPhantom = (work, log, cb = ->) ->
  phantom.create (err, ph) ->
    ph.createPage (err, page) ->

      page.open "http://localhost:8000", (err, status) ->
        error = (err, result) ->
          log(err, result)
          cb( err, ph, result)
        return page.evaluate work, error, log

#worker = require('./botscript.coffee')
logger = -> console.log arguments
worker = (log) ->
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
  

runPhantom worker, logger, (err, ph, result) ->
  console.log err, result
  ph.exit()

