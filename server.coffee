App      = require('./app.coffee')
_        = require('underscore')

# The app object inherits all the methods of the express
# server, allowing us to register middleware more
# easily.
http     = require("http")
express  = require("express")
_express = express()
server   = http.createServer(_express)
_.defaults App, _express

# Set up express with some default things.
App.addInitializer (opts) ->
  @set 'views', __dirname + '/views'
  @set "view engine", "jade"

# Setup express middleware.
App.addInitializer (opts) ->
  @use express.compress()
  @use new express.static(__dirname + "/build")
  @use new express.static(__dirname + "/bower_components/bootstrap/dist")


# Set up express routes.
App.addInitializer (opts) ->
  # Wildcard default route.
  @get "/*", (req, res, next) =>
    res.render "intro",
      host: opts.host
      env: env

# Start listening to the ports.
App.addInitializer (opts) ->
  server.listen opts.port, (err) =>
    if err
      console.error err
      process.exit -1

    console.log "Server running at http://#{opts.host}:#{opts.port}/"
    @trigger "listen"

# set back to non-root permissions
#
# if run as root, downgrade to the owner of this file.
#
# we run nginx in our environment since we need
# https, and it complicates the app too much
# to implement it directly.
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
