fs      = require('fs')
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
  console.log "Server running at http://#{conf.host}:#{conf.port}/"
  if err
    console.error err
    process.exit -1

  # set back to non-root permissions
  #
  # we run nginx in our environment since we need
  # https, and it complicates the app too much
  # to implement it directly.
 
  # if run as root, downgrade to the owner of this file
  if process.getuid() is 0
    fs.stat __filename, (err, stats) ->
      return console.error(err)  if err
      process.setuid stats.uid
      #process.setgid stats.gid
      #process.initgroups(stats.uid, stats.gid)
