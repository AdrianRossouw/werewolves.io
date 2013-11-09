nko  = require('nko')
http = require("http")
_    = require('underscore')

# figure out config for the current environment

serverConf = require('./config.server.coffee')
conf       = {}
env        = process.env.NODE_ENV
env       ?= 'development'

_.defaults conf,
    serverConf[env],
    serverConf.defaults


# https://github.com/nko4/website/blob/master/module/README.md#nodejs-knockout-deploy-check-ins
nko =  conf.nkoKey
port = conf.port

# http://blog.nodeknockout.com/post/35364532732/protip-add-the-vote-ko-badge-to-your-app
http.createServer((req, res) ->
  voteko = "<iframe src=\"http://nodeknockout.com/iframe/nodesque\" frameborder=0 scrolling=no allowtransparency=true width=115 height=25></iframe>"
  res.writeHead 200,
    "Content-Type": "text/html"

  res.end "<html><body>" + voteko + "</body></html>\n"
).listen port, (err) ->
  if err
    console.error err
    process.exit -1
  
  # if run as root, downgrade to the owner of this file
  if process.getuid() is 0
    require("fs").stat __filename, (err, stats) ->
      return console.error(err)  if err
      process.setuid stats.uid

  console.log "Server running at http://0.0.0.0:" + port + "/"
