App = require('../app')
State = require('../state')
Models = App.module "Models"
express = require('express')
request = require('request')
debug = require('debug')('werewolves:voice:server')
Voice = App.module "Voice"
_ = require('underscore')

# require the game script
require('./script')

# initializes the tropo connection
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

# sends a signal (interrupt) to the tropo session
Models.Session::signal = (signal) ->
  return false if not @voice

  body = JSON.stringify(signal: signal)

  reqOpts =
    url: "https://api.tropo.com/1.0/sessions/#{@voice}/signals"
    body: body
    json: true

  request.post reqOpts, ->

# hangs up a tropo connection (via signal)
Models.Session::hangup = -> @signal 'hangup'

# exits the current script, causing a new script to be fetched.
Models.Session::exit = -> @signal 'exit'

App.listenTo App, 'middleware', (opts) ->
  flensed = "bower_components/phono/deps/flensed/1.0"
  @use '/voice', new express.logger()
  @use new express.json()
  @use new express.urlencoded()
  @use new express.static "#{__dirname}/../#{flensed}"

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
  sessions.invoke 'exit' if url == 'game'

# this is the url that tropo will hit when it calls us.
Voice.listenTo App, 'before:routes', (opts) ->
  App.post '/voice', (req, res, next) =>
    tropo = new TropoWebAPI()

    # determine the voice session to use
    voiceId = req.body?.session?.id
    voiceId ?= req.body?.result.sessionId

    # session.voice maps to this body property from tropo's backend
    sessions = State.world.sessions
    session = sessions.findVoice(voiceId)

    # call all registered sip addresses, hoping one of them picks up.
    callState = req.body?.session?.parameters?.callState

    if callState is 'init'
      sips = _(session?.sip).values()
      console.log('sips being called', sips)
      tropo.call sips if sips.length

    # gather env variables to handle the call correctly
    env = world: State.world
    env.game = env.world.game
    env.round = env.game.currentRound()
    env.session = session
    env.player = session?.player

    debug 'env', _(env).invoke('toJSON', session)

    # run through main game script
    @script tropo, env

    # when the session get the exit signal, it will call back
    tropo.on 'exit', null, '/voice'
    tropo.on "hangup", null, "/voice/hangup"
    tropo.on "incomplete", null, "/voice/incomplete"
    tropo.on "error", null, "/voice/error"

    return res.send TropoJSON(tropo)

  downgrade = (req, res, next) ->
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
