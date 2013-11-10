App = require('./app.coffee')
State = require('./state.server.coffee')
express = require('express')
request = require('request')
Voice = App.module "Voice"

tropo  = require('tropo-webapi')

middleware = (opts) ->
  @use new express.json()
  @use new express.urlencoded()
  @use new express.static(__dirname + "/bower_components/phono/deps/flensed/1.0")

App.on 'middleware', middleware, App

mountRoutes = (opts) ->
  @post '/voice', (req, res, next) ->
    console.log "PLAYER ID", req.params.playerId
    tropo = new TropoWebAPI()
    tropo.say "http://hosting.tropo.com/5010929/www/audio/Introduction.mp3"


    tropo.conference("game", null, "conference", null, null, null)
    
    res.send TropoJSON(tropo)

App.on 'before:routes', mountRoutes, App

module.exports = Voice
