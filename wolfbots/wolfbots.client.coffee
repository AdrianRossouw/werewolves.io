debug = require('debug')('werewolves:wolfbots:client')
_ = require('underscore')
Backbone = require('backbone')

App = require('../app')
State = App.module "State"
Models = App.module "Models"
Socket = App.module "Socket"
Client = App.module "Wolfbots.Client",
  startWithParent: false

Client.addInitializer (conf = {}) ->
  @socket ?= conf.socket or Socket.io

  promiseFn = (dfr) ->
    (err, result) ->
      return dfr.reject(err) if err
      return dfr.resolve(result)

  @io = (args...) =>
    @socket.emit args...

  @add = (names...) ->
    debug('add', arguments)
    _.when _(names).map (n) =>
      dfr = new _.Deferred()
      @io 'wolfbot:add', n, promiseFn(dfr)
      dfr.promise()

  @remove = (names...) ->
    debug('remove', arguments)
    _.when _(names).map (n) =>
      dfr = new _.Deferred()
      @io 'wolfbot:remove', n, promiseFn(dfr)
      dfr.promise()


  @command = (name, args...) ->
    debug('command', arguments)
    name = [name] if !_.isArray(name)
    _.when _(name).map (n) =>
      dfr = new _.Deferred()
      @io 'wolfbot:command', n, args..., promiseFn(dfr)
      dfr.promise()

  @commandAll = (args...) ->
    dfr = new _.Deferred()
    @io 'wolfbot:command:all', args..., promiseFn(dfr)
    dfr.promise()

module.exports = Client
