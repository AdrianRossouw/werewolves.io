App = require('../app')
State = require('../state')
Models = App.module "Models"
express = require('express')
request = require('request')
debug = require('debug')('werewolves:voice:server')
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
  @use '/voice', new express.logger()
  @use new express.json()
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
  tropo.say 'you go to sleep'
  tropo.conference("asleep", true, "asleep", false, null, '#', 'exit')

Voice.awake = (tropo) ->
  tropo.say 'you wake up'
  tropo.conference "awake", null, "awake", false, null, '#', 'exit'

Voice.spectate = (tropo) ->
  tropo.say 'you are spectating'
  tropo.conference("awake", true, "awake", false, null, '#', 'exit')


# introductory, to be played in attract mode
Voice.intro = (tropo, env) ->
  @audio tropo, "Introduction"
  @awake tropo

# To be played on the first night
Voice.firstNight = (tropo, env) ->
  # per role
  switch env?.player?.role
    when 'villager'
      #@audio tropo, 'VillagerTutorial'
      tropo.say 'you are a villager'
    when 'werewolf'
      #@audio tropo, 'VillagerTutorial'
      tropo.say 'you are a werewolf'
    when 'seer'
      #@audio tropo, 'SeerTutorial'
      tropo.say 'you are the seer'

  # for everyone
  #@audio tropo, 'FirstNight'
  tropo.say 'the first night'

  # for specific roles again
  switch env?.player?.role
    when 'villager'
      #@audio tropo, 'FirstNightWerewolves'
      tropo.say 'kill somebody'
    when 'seer'
      #@audio tropo, 'FirstNightSeer'
      tropo.say 'dream about somebody'

  @awakeByRole tropo, env.player

# first day
Voice.firstDay = (tropo, env) ->
  #@audio tropo, 'FirstDay'
  tropo.say 'first day'
  @awake(tropo)

# each subsequent night

Voice.night = (tropo, env) ->
  #@audio tropo, 'NextNight1'
  tropo.say 'next night'
  @awakeByRole(tropo, env.player)

# each subsequent day
# TODO: add files for who died.
Voice.day = (tropo, env) ->
  #@audio tropo, 'NextDay1'
  tropo.say 'next day'
  @awake tropo

Voice.wolvesWin = (tropo, env) ->
  tropo.say 'wolves win'
  @awake tropo

Voice.villagersWin = (tropo, env) ->
  tropo.say 'villagers win'
  @awake tropo



# for specific roles
# leave them muted/unmuted in the 
# right conference rooms.
Voice.awakeByRole = (tropo, player) ->
  if player?.state()?.is('dead')
    @spectate(tropo)
  if player?.role is 'werewolf'
    @awake(tropo)
  else
    @asleep(tropo)

Voice.listenTo App, 'before:state', (opts) ->
  @token = opts.token

# Listen to the various states of the game flipping over
Voice.listenTo State, 'state', (url, state) ->

  # if a user gets up to the sip state, call them
  if state is 'online.sip'
    session = State.models[url]
    session.initVoice()

  # end of a round, interrupt everyone.
  # tropo will call back to get the script
  State.world.sessions.invoke 'signal', 'exit' if url == 'game'


# this is the url that tropo will hit when it calls
# us.
#
# TODO: handle hangups, so we can remove inactive sessions
Voice.listenTo App, 'before:routes', (opts) ->
  App.post '/voice', (req, res, next) =>
    tropo = new TropoWebAPI()

    # when the session get the exit signal, it will call back
    tropo.on 'exit', null, '/voice'
    #tropo.on "hangup", null, "/voice/hangup"
    #tropo.on "error", null, "/voice/error"


    # session.voice maps to this body property from tropo's backend
    session = State.world.sessions.findVoice(req.body?.session?.id)

    # if we just got your sip number, call your browser
    if req.body?.session?.parameters
      callState = req.body.session.parameters.callState

      if callState is 'init'
        tropo.call session?.sip

    # gather env variables to handle the call correctly
    playerId = session?.id
    env =
      session: session
      world: State.world
      game: State.world.game
      round: State.world.game.currentRound()
      player: State.getPlayer(playerId)


    # play the right files for each phase
    switch env.world.state().path()
      when 'attract' or 'startup'
        @intro tropo, env
      when 'gameplay'
        switch env.game.state().name
          when 'firstNight'
            @firstNight tropo, env
          when 'firstDay'
            @firstDay tropo, env
          when 'night'
            @night tropo, env
          when 'day'
            @day tropo, env
          else @awake tropo

      when 'cleanup'
        switch env.game.state().path()
          when 'victory.werewolves'
            @wolvesWin tropo, env
          when 'victory.villagers'
            @villagersWin tropo, env
          else @awake tropo
      else @awake tropo

    return res.send TropoJSON(tropo)

  App.post '/voice/hangup', (req, res, next) ->
    sessionId = req.body?.result?.sessionId

    # session.voice maps to this body property from tropo's backend
    #session = State.world.sessions.findVoice(sessionId)
    #session.unset('voice') if session

    res.send(500)

  App.post '/voice/error', (req, res, next) ->
    console.log(req.body)
    res.send 500

Voice.addFinalizer (opts) ->
  @stopListening()


module.exports = Voice
