App = require('../app')
State = require('../state')
express = require('express')
Voice = App.module "Voice"

tropo  = require('tropo-webapi')

middleware = (opts) ->
  @use new express.json()
  @use new express.urlencoded()
  @use new express.static(__dirname + "/../bower_components/phono/deps/flensed/1.0")

App.on 'middleware', middleware, App

mountRoutes = (opts) ->
  @post '/voice', (req, res, next) ->
    tropo = new TropoWebAPI()
    tropo.say "http://hosting.tropo.com/5010929/www/audio/Introduction.mp3"


    tropo.conference("game", null, "conference", null, null, null)
    
    res.send TropoJSON(tropo)

App.on 'before:routes', mountRoutes, App

module.exports = Voice
