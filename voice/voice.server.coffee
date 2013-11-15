App = require('../app')
State = require('../state')
express = require('express')
Voice = App.module "Voice"
request = require('request')


tropo  = require('tropo-webapi')

middleware = (opts) ->
  @use new express.json()
  @use new express.urlencoded()
  @use new express.static(__dirname + "/../bower_components/phono/deps/flensed/1.0")

App.on 'middleware', middleware, App

mountRoutes = (opts) ->
  @post '/voice', (req, res, next) ->
        
    #console.log(req.body)

    tropo = new TropoWebAPI()
    tropo.say "http://hosting.tropo.com/5010929/www/audio/Introduction.mp3"
    tropo.say 'what the fuck'

    tropo.conference("game", null, "conference", null, null, null)
    res.send TropoJSON(tropo)

App.on 'before:routes', mountRoutes, App

App.addInitializer (opts) ->
  body = JSON.stringify
    token: opts.token

  reqOpts =
    url: 'https://api.tropo.com/1.0/sessions'
    body: body
    json: true

  request.post reqOpts, (err, resp) ->
    #console.log(resp)
    

module.exports = Voice
