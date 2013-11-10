App = require('./app.coffee')
Voice = App.module "Voice"

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
  @appId = opts.appId
  @apiKey = opts.apiKey
  $.phono
    apiKey: @apiKey
    logLevel: 'ERROR'
    onReady: (event) ->
      Voice.phono = @
      @phone.wideband true
      @phone.ringbackTone false
      @phone.dial Voice.appId,
          volume: 100
          headset: false

module.exports = Voice
