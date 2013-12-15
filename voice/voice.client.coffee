App = require('../app')
State = App.module "State"
Voice = App.module "Voice"

phono = require('phono')

Voice.listenTo App, 'state', (opts) ->

  loader = (world) ->
    @appId = opts.appId
    @apiKey = opts.apiKey

    $.phono
      apiKey: @apiKey
      onReady: (event) ->
        Voice.phono = @
        @phone.ringTone false
        @phone.wideband true
        State.addSip @sessionId

      phone:
        onIncomingCall: (event) ->
          call = event.call
          State.addCall()
          console.log("Auto-answering call with ID " + call.id)
          call.answer()

  State.on 'load', loader, Voice

module.exports = Voice
