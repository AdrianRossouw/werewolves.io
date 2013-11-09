App = require('app.coffee')
State = require('./state.server.coffee')
express = require('express')

Socket = App.module "Socket"
socketio     = require("socket.io")
SessionIo    = require("session.socket.io")

# Initialize the socket.io library, with the
# session handler wrapper.
sessionInit = (opts) ->
  cookieParser = new express.cookieParser(opts.secret)

  @io = socketio.listen(App.server)
  @io.set("destroy upgrade",false)

  @sio = new SessionIo @io, State.sessionStore, cookieParser

  
  @sio.on 'connection', (err, args...) =>
    if err
      return @trigger 'error', err

    @trigger 'connection', args...

App.on "listen", sessionInit, State


module.exports = Socket
