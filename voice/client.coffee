App = require('../app.coffee')
Voice = App.module "Voice"
State = App.module "State"

phono = require('phono')
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
        Socket.setSipId world.playerId, @phone.id
        @phone.wideband true
        @phone.ringbackTone false
        @phone.dial Voice.appId,
          volume: 100
          headers: [
            { name: "x-player-id", value: ''+world.playerId }
          ]
  State.on 'load', loader, Voice

module.exports = Voice
