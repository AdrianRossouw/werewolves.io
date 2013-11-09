nko     = require('nko')
http    = require("http")
_       = require('underscore')
express = require("express")
app     = express()
server  = http.createServer(app)

# figure out config for the current environment

sConf  = require('./config.server.coffee')
conf   = {}
env    = process.env.NODE_ENV
env   ?= 'development'

_.defaults conf, sConf[env], sConf.defaults

nko conf.nkoKey

app.set 'views', __dirname + '/views'
app.set "view engine", "jade"
app.use express.compress()

app.use new express.static(__dirname + "/build")
app.use new express.static(__dirname + "/bower_components/bootstrap/dist")

app.get "/*", (req, res, next) ->
    res.render "intro",
        host: conf.host
        env: env

app.listen conf.port, (err) ->
  if err
    console.error err
    process.exit -1
  
  # if run as root, downgrade to the owner of this file
  if process.getuid() is 0
    require("fs").stat __filename, (err, stats) ->
      return console.error(err)  if err
      process.setuid stats.uid

  console.log "Server running at http://0.0.0.0:" + conf.port + "/"
