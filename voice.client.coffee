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
      @phone.dial(Voice.appId)

module.exports = Voice
