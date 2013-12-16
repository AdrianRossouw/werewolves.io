App = require('../app')
State = App.module "State"
Voice = App.module "Voice"

phono = require('phono')

Voice.addInitializer (opts) ->
  @appId = opts.appId
  @apiKey = opts.apiKey

  @listenTo State, 'load', (world) ->
    @phone = $.phono
      apiKey: @apiKey
      onReady: (event) ->
        Voice.phono = @
        @phone.ringTone false
        @phone.wideband true
        State.addSip @sessionId
      onUnready: (event) ->
        alert event

      phone:
        onIncomingCall: (event) ->
          call = event.call
          State.addCall()
          console.log("Auto-answering call with ID " + call.id)
          call.answer()
        onError: (reason) ->
          alert "error #{reason}"

    @phone.setLogLevel("WARN")

module.exports = Voice
