App = require('../app')
Voice = App.module "Voice"
State = App.module "State"

phono = require('phono')
PhonoStrophe.LogLevel = { ERROR: 3 }
buzz = require('buzz')

###
#
mySound = new buzz.sound( "assets/audio/Introduction", {
    formats: [ "mp3"]
})

mySound.play()
    .unloop()
###

Voice.addInitializer (opts) ->
  loader = (world) ->
    @appId = opts.appId
    @apiKey = opts.apiKey
    $.phono
      apiKey: @apiKey
      logLevel: 'ERROR'
      onReady: (event) ->
        Voice.phono = @
        State.session.setIdentifier 'sip', @phone.id
  State.on 'load', loader, Voice

module.exports = Voice
