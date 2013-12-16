App = require('../app')
State = require('../state')
Models = App.module "Models"
express = require('express')
request = require('request')
debug = require('debug')('werewolves:voice:server')
Voice = App.module "Voice"
_ = require('underscore')

Models.Session::signal = (signal) ->
  return false if not @voice

  body = JSON.stringify(signal: signal)

  reqOpts =
    url: "https://api.tropo.com/1.0/sessions/#{@voice}/signals"
    body: body
    json: true

  request.post reqOpts, ->

Models.Session::initVoice = ->
  return false unless @hasSip()

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



tropo  = require('tropo-webapi')

middleware = (opts) ->
  @use '/voice', new express.logger()
  @use new express.json()
  @use new express.urlencoded()
  @use new express.static(__dirname + "/../bower_components/phono/deps/flensed/1.0")

App.on 'middleware', middleware, App

Voice.audio = (tropo, name) ->
  tropo.say "http://hosting.tropo.com/5010929/www/audio/#{name}.mp3"

Voice.asleep = (tropo) ->
  tropo.say 'you go to sleep'
  tropo.conference "asleep", true, "asleep", false, null, '#'

Voice.awake = (tropo) ->
  tropo.say 'you wake up'
  tropo.conference "awake", null, "awake", false, null, '#'

Voice.spectate = (tropo) ->
  tropo.say 'you are spectating'
  tropo.conference "awake", true, "awake", false, null, '#'

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
  sessions = State.world?.sessions

  # if a user gets up to the sip state, call them
  if state is 'online.sip'
    session = State.models[url]
    session.initVoice()

  # end of a round, interrupt everyone.
  # tropo will call back to get the script
  sessions.invoke 'signal', 'exit' if url == 'game'

# this is the url that tropo will hit when it calls us.
Voice.listenTo App, 'before:routes', (opts) ->
  App.post '/voice', (req, res, next) =>
    tropo = new TropoWebAPI()

    # when the session get the exit signal, it will call back
    tropo.on 'exit', null, '/voice'
    tropo.on "hangup", null, "/voice/hangup"
    tropo.on "incomplete", null, "/voice/incomplete"
    tropo.on "error", null, "/voice/error"

    # session.voice maps to this body property from tropo's backend
    sessions = State.world.sessions
    session = sessions.findVoice(req.body?.session?.id)
    
    # call all registered sip addresses, hoping one of them picks up.
    callState = req.body?.session?.parameters?.callState

    if callState is 'init'
      sips = _(session?.sip).values()
      console.log('sips being called', sips)
      tropo.call sips if sips.length

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

  downgrade = (req, res, next) ->
    console.log(req.body)
    sessionId = req.body?.result?.sessionId

    # session.voice maps to this body property from tropo's backend
    sessions = State.world?.sessions
    session = sessions?.findVoice(sessionId)
    return res.send(200) unless session

    # remove the voice connection
    session.removeVoice(sessionId)
    res.send(200)

  App.post '/voice/hangup', downgrade
  App.post '/voice/incomplete', downgrade
  App.post '/voice/error', downgrade
  App.post '/voice/error', downgrade

Voice.addFinalizer (opts) ->
  @stopListening()

module.exports = Voice
