App = require('../app')
State = App.module "State"
Voice = App.module "Voice"

phono = require('phono')
PhonoStrophe.LogLevel = {  }
buzz = require('buzz')

###
#
mySound = new buzz.sound( "assets/audio/Introduction", {
    formats: [ "mp3"]
})

mySound.play()
    .unloop()
###

Voice.listenTo App, 'state', (opts) ->
  loader = (world) ->
    @appId = opts.appId
    @apiKey = opts.apiKey
    $.phono
      apiKey: @apiKey
      onReady: (event) ->
        Voice.phono = @
        State.session.setIdentifier 'sip', @sessionId
  State.on 'load', loader, Voice

module.exports = Voice
