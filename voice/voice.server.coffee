App = require('../app')
State = require('../state')
Models = App.module "Models"
express = require('express')
request = require('request')
Voice = App.module "Voice"

Models.Session::signal = (signal) ->
  return false if not @voice

  body = JSON.stringify(signal: signal)

  reqOpts =
    url: "https://api.tropo.com/1.0/sessions/#{@voice}/signals"
    body: body
    json: true

  request.post reqOpts, ->

Models.Session::initVoice = ->

  body = JSON.stringify
    token: Voice.token,
    playerId: @id
    callState: 'init'

  reqOpts =
    url: 'https://api.tropo.com/1.0/sessions'
    body: body
    json: true

  request.post reqOpts, (err, resp) =>
    @voice = resp.body.id.replace('\r\n', '')


Models.Sessions::findVoice = (voice) ->
  return false if not voice
  @findWhere voice: voice


Models.Sessions::findSip = (sip) ->
  return false if not sip
  @findWhere sip: sip

tropo  = require('tropo-webapi')

middleware = (opts) ->
  @use new express.json()
  @use new express.logger()
  @use new express.urlencoded()
  @use new express.static(__dirname + "/../bower_components/phono/deps/flensed/1.0")

App.on 'middleware', middleware, App

Voice.debug = (tropo, env) ->
  tropo.say "session is #{env.session.state().name}" if env.session
  tropo.say "world is #{env.world.state().name}" if env.world
  tropo.say "game is #{env.game.state().name}" if env.game
  tropo.say "round is #{env.round.state().name}" if env.round
  tropo.say "player is #{env.player.state().name}" if env.player


Voice.audio = (tropo, name) ->
  tropo.say "http://hosting.tropo.com/5010929/www/audio/#{name}.mp3"

Voice.asleep = (tropo) ->
  tropo.conference("asleep", true, "asleep", false, null, '#', 'exit')

Voice.awake = (tropo) ->
  tropo.conference("awake", null, "awake", false, null, '#', 'exit')

Voice.spectate = (tropo) ->
  tropo.conference("awake", true, "awake", false, null, '#', 'exit')

  
Voice.intro = (tropo, env) ->
  @audio tropo, "Introduction"
  @awake tropo


Voice.listenTo App, 'before:state', (opts) ->
  @token = opts.token

Voice.listenTo State, 'state', (url, state) ->
  if state is 'online.sip'
    session = State.models[url]
    console.log session
    session.initVoice()

Voice.listenTo App, 'before:routes', (opts) ->
  App.post '/voice', (req, res, next) =>
    tropo = new TropoWebAPI()

    tropo.on 'exit', null, 'voice'
    if req.body?.session?.parameters
      callState = req.body.session.parameters.callState

      session = State.world.sessions.findVoice(req.body?.session?.id)
      console.log State.world.sessions.pluck('voice')

      playerId = session.id

      env =
        session: session
        world: State.world
        game: State.world.game
        round: State.world.game.currentRound()
        player: State.getPlayer(playerId)

      if callState is 'init'
        tropo.call env.session.sip

      if not env.world.state().isIn('gameplay')
        #@intro tropo
        @debug tropo, env
      else
        @debug tropo, env
    else
      @intro tropo
    

    res.send TropoJSON(tropo)



module.exports = Voice
