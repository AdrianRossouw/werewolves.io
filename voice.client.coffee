App = require('./app.coffee')
Voice = App.module "Voice"

require('phono')

Voice.addInitializer (opts) ->
  @appId = opts.appId
  @apiKey = opts.apiKey
  $.phono
    apiKey: @apiKey
    logLevel: 'ERROR'
    onReady: (event) ->
      App.phono = @
      @phone.wideband true
      @phone.ringbackTone false
      @phone.dial Voice.appId,
          volume: 100
          headset: false

module.exports = Voice
