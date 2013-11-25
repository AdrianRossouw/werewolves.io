App      = require('../app')
state    = require('state')
_        = require('underscore')
Backbone = require('backbone')
Models   = App.module "Models"

# The world acts as the container for the other
# pieces of state.
class Models.World extends Models.BaseModel
  url: 'world'
  initialize: (data = {}, opts = {}) ->
    @timer = new Models.Timer(data.timer or {})
    @sessions = new Models.Sessions(data.sessions or [])
    @game = new Models.Game(data.game or {})
    super
    @state().change(data._state or 'attract')
    @publish()

  destroy: ->
    @sessions.invoke 'destroy'
    @game.destroy()
    @timer.destroy()
    super
    @stopListening()

  toJSON: ->
    obj = super
    obj._state = @state().path()
    obj.sessions = @sessions.toJSON()
    obj.timer = @timer.toJSON()
    obj.game = @game.toJSON()
    obj
  startGame: =>
    @timer.stop()
    @state('-> gameplay')

  initState: -> state @,
    joinGame: (id) ->
      @game.addPlayer(id: id)
      @trigger 'game:join'
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
        @timer.limit = 30000

        @listenTo @timer, 'end', @startGame

        @listenTo @game.players, 'add', ->
          @timer.reset()

        @listenTo @game.state('recruit.ready'), 'arrive', =>
          @timer.start()

      exit: ->
        @stopListening @game.state('recruit.ready'), 'arrive'
        @stopListening @game.timer, 'end'
        @stopListening @game.players, 'add'

    # there is an active game running
    gameplay:
      next: 'cleanup'
      arrive: ->
        @game.startGame()
        @listenTo @game, 'game:end', => @state().go 'cleanup'

      exit: ->
        @stopListening @game, 'game:end'
    # the last game finished
    cleanup:
      arrive: ->
        @listenTo @timer, 'end', => @state().go 'attract'
        @timer.start()

      exit: ->
        @stopListening @timer, 'end'
        @game.destroy()
        @game = new Models.Game()
