App      = require('../app')
state    = require('state')
_        = require('underscore')
Backbone = require('backbone')
Models   = App.module "Models"

# The world acts as the container for the other
# pieces of state.
class Models.World extends Models.BaseModel
  url: 'world',
  initialize: (data = {}, opts = {}) ->
    super
    @sessions = new Models.Sessions(data.sessions or [])
    @game = new Models.Game(data.game or {})
    @state('-> attract')

  toJSON: ->
    obj = super
    obj.sessions = @sessions.toJSON()
    obj.game = @game.toJSON
    obj

  state s = @::,
    # we have no registered players or game
    attract:
      arrive: ->
        @listenTo @game.players, 'add', -> @state('-> startup')

   
      exit: ->
        process.exit(1)

    # the first player joined
    startup: state

    # there is an active game running
    gameplay: state

    # the last game finished
    cleanup: state
