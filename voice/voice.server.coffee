App = require('../app')
State = require('../state')
Models = App.module "Models"
express = require('express')
request = require('request')
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

    if req.body?.session?.parameters
      callState = req.body.session.parameters.callState

      playerId = req.body.session.parameters.playerId


      session = State.getSession(playerId)
      world = State.world
      game  = world.game
      round = game.currentRound()
      player = State.getPlayer(playerId)

      if callState is 'init'
        tropo.call session.sip

      tropo.say "session is #{session.state().name}" if session
      tropo.say "world is #{world.state().name}" if world
      tropo.say "game is #{game.state().name}" if game
      tropo.say "round is #{round.state().name}" if round
      tropo.say "player is #{player.state().name}" if player

      #tropo.say "http://hosting.tropo.com/5010929/www/audio/Introduction.mp3"
      #tropo.say 'what the fuck'
      #tropo.conference("game", null, "conference", null, null, null)

    else
      console.log "not a session"
      tropo.say "not a session"
      tropo.conference("game", null, "conference", null, null, null)

    res.send TropoJSON(tropo)

App.on 'before:routes', mountRoutes, App


Voice.listenTo App, 'before:state', (opts) ->
  @token = opts.token

Voice.listenTo State, 'state', (url, state) ->
  if state is 'online.sip'
    session = State.models[url]
    @initSession session.id, (err, resp) =>
      session.voice = resp.body.id.replace(/\/r\/n/, '')

Voice.initSession = (playerId, cb) ->
  body = JSON.stringify
    token: @token,
    playerId: playerId
    callState: 'init'

  reqOpts =
    url: 'https://api.tropo.com/1.0/sessions'
    body: body
    json: true

  request.post reqOpts, cb


module.exports = Voice
