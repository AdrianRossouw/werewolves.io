App      = require('./app.coffee')
App.isServer = true
_        = require('underscore')

# The app object inherits all the methods of the express
# server, allowing us to register middleware more
# easily.
http       = require("http")
express    = require("express")
_express   = express()
server     = http.createServer(_express)
App.server = server
_.defaults App, _express

# Load up the state instances
State = require('./state.server.coffee')
App.addInitializer (opts) ->
  @trigger 'before:state', opts

  # We initialize this separately because
  # we don't want it to run just when included

  State.start(opts)
  @trigger 'state', opts

# Load up the web sockets
Socket = require('./socket.server.coffee')
Voice = require('./voice.server.coffee')

# Set up express with some default things.
App.addInitializer (opts) ->
  @trigger 'before:settings', opts
  @set 'views', __dirname + '/views'
  @set "view engine", "jade"
  @trigger 'settings', opts

# Setup express middleware.
App.addInitializer (opts) ->
  # no-op, to get around express auto-mounting the
  # router when the first verb is called.
  @router
  @trigger 'before:middleware', opts
  @use express.compress()
  @use new express.static(__dirname + "/build")
  @use new express.static(__dirname + "/bower_components/bootstrap/dist")
  @use '/assets', new express.static(__dirname + "/assets")
  @trigger 'middleware', opts

# Set up express routes.
App.addInitializer (opts) ->
  @trigger 'before:routes', opts

  # Wildcard default route.
  @get "/*", (req, res, next) =>
    res.render "layout",
      host: opts.host
      env: env
  @trigger 'routes', opts

  # mount the router middleware in a predicatable place.
  @use @router

# Start listening to the ports.
App.addInitializer (opts) ->
  @trigger 'before:listen', opts
  server.listen opts.port, (err) =>
    if err
      console.error err
      process.exit -1

    console.log "Server running at http://#{opts.host}:#{opts.port}/"
    @trigger "listen", opts

# set back to non-root permissions
#
# if run as root, downgrade to the owner of this file.
#
# we run nginx in our environment since we need
# https, and it complicates the app too much
# to implement it directly.
fs = require('fs')

downgradePerms = ->
  if process.getuid() is 0
    fs.stat __filename, (err, stats) ->
      return console.error(err)  if err
      process.setuid stats.uid
      #process.setgid stats.gid
      #process.initgroups(stats.uid, stats.gid)

App.on "listen", downgradePerms

# figure out config for the current environment
sConf   = require('./config.server.coffee')
conf    = {}
env     = process.env.NODE_ENV
env    ?= 'development'

_.defaults conf, sConf[env], sConf.defaults

# Ping home to show we have been deployed
nko = require('nko')
nko conf.nkoKey

# Start the app.
App.start(conf)
