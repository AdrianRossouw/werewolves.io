App = require('./app.coffee')
State = require('./state.server.coffee')
express = require('express')
Voice = App.module "Voice"

tropo        = require('tropo-webapi')

middleware = (opts) ->
  @use new express.static(__dirname + "/bower_components/phono/deps/flensed/1.0")

App.on 'middleware', middleware, App

mountRoutes = (opts) ->
  @post '/voice', (req, res, next) ->
    tropo = new TropoWebAPI()
    tropo.say "http://nodesque.2013.nodeknockout.com:8000/assets/audio/Introduction.mp3"
    #tropo.say "welcome to werewolves dot io"

    #tropo.say "we aren't taking calls right now, but we will get back to you"
    tropo.hangup
    res.send TropoJSON(tropo)

App.on 'before:routes', mountRoutes, App

module.exports = Voice
