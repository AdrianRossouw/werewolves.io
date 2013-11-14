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
    @state().change(data._state or 'attract')

  toJSON: ->
    obj = super
    obj._state = @state().path()
    obj.sessions = @sessions.toJSON()
    obj.game = @game.toJSON
    obj

  startGame: =>

    @state('-> gameplay')

  initState: -> state @,

    # we have no registered players or game
    attract:
      arrive: ->
        # on the first user added, go to startup
        @listenTo @game.players, 'add', ->
          @state('-> startup')
  
      exit: ->
        @stopListening @game.players, 'add'

    # the first player joined
    startup:
      arrive: ->
        @listenTo @game.state('recruit.ready'), 'arrive', =>
          _.delay @startGame, 30000

      exit: ->
        @stopListening @game.state('recruit.ready'), 'arrive'

    # there is an active game running
    gameplay:
     enter: ->
        @game.startGame()

    # the last game finished
    cleanup: {}
