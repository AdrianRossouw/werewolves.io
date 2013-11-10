App           = require('./app.coffee')
Socket        = App.module "Socket"
State         = require('./state.client.coffee')
_             = require('underscore')
url           = require('url')

# SocketIO library (browserified.. yay)
socketio            = require("socket.io-client")

Socket.addInitializer (opts) ->
  socketio.transports = ["websocket"]
  socketUrl = url.format _.pick(opts, 'hostname', 'protocol', 'port')

  if opts.protocol == 'https'
    @io = socketio.connect(socketUrl, { secure: true })
  else
    @io = socketio.connect(socketUrl)
  @io.on 'world:state', (data) =>
    State.load data
  

module.exports = Socket
