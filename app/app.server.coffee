App        = require('../app')
conf       = require('../config')
debug      = require('debug')('werewolves:server')
http       = require("http")
_          = require('underscore')
express    = require("express")
_express   = express()
server     = http.createServer(_express)
App.server = server
env        = process.env.NODE_ENV or 'development'

# The app object inherits all the methods of the express
# server, allowing us to register middleware more
# easily.
_.defaults App, _express

# Load up the state instances
#
# We initialize this separately because
# we don't want it to run just when included
State = require('../state')
App.addInitializer (opts) ->
  @trigger 'before:state', opts
  State.start(opts)
  @trigger 'state', opts

# Load up the web sockets
Socket = require('../socket')
Voice = require('../voice')

if env is 'development'
  Wolfbots = require('../wolfbots')
  Wolfbots.start()





# Set up express with some default things.
App.addInitializer (opts) ->
  @trigger 'before:settings', opts
  @set 'views', __dirname + '/../templates'
  @set "view engine", "jade"
  @trigger 'settings', opts

# Setup express middleware.
#
# We call just @router first as a
# no-op, to get around express auto-mounting the
# router when the first verb is called.
App.addInitializer (opts) ->
  @router
  @trigger 'before:middleware', opts
  @use express.compress()
  @use new express.static(__dirname + "/../build")
  @use '/assets', new express.static(__dirname + "/../assets")
  @trigger 'middleware', opts

# Set up express routes.
# Mostly the wildcard default route.
#
# Also mounts the router middleware in a predicatable place.
App.addInitializer (opts) ->
  defaultRoute = (req, res, next) =>
    res.render "layout-server",
      host: opts.host
      env: env
      playerId: req.state.session.id
      socketUrl: App.Socket.formatUrl(opts)
      world: JSON.stringify(State.world.mask(req.state.session))

  @trigger 'before:routes', opts
  @get "/", defaultRoute
  @trigger 'routes', opts
  @use @router

# Start listening to the ports.
App.addInitializer (opts) ->
  @trigger 'before:listen', opts
  server.listen opts.port, (err) =>
    if err
      debug 'listen error', err
      process.exit -1

    @_running = true
    debug 'started', "http://#{opts.host}:#{opts.port}/"
    @trigger "listen", opts

# Stop the application and server
#
# mostly needed for multiple tests that start the
# server on different ports.
App.addInitializer (opts) ->
  @listenTo @, "stop", ->
    @trigger 'before:close'
    server.close() if @_running
    @_running = false
    @trigger 'close'


# figure out config for the current environment
App.config = ->
  _.defaults({}, conf[env], conf.defaults)

module.exports = App
