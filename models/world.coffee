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
    # we need to attach the timer to the state module
    # so the rest of the system being initialized can
    # access it.
    App.State.timer = @timer
    @sessions = new Models.Sessions(data.sessions or [])
    @game = new Models.Game(data.game or {})
    super
    @state().change(data._state or 'attract')
    @publish()
    @trigger('state', @state().path())

  destroy: ->
    @off()
    @sessions.destroy()
    @game.destroy()
    @timer.destroy()
    super

  toJSON: (session) ->
    json = super
    json._state = @state().path()
    json.sessions = @sessions.toJSON(session)
    json.timer = @timer.toJSON(session)
    json.game = @game.toJSON(session)
    return json unless session

    _.pick json, 'id', 'game', '_state', 'sessions', 'timer'

  startGame: =>
    @timer.stop()
    @go('gameplay')

  initState: -> state @,
    joinGame: (id) ->
      @game.addPlayer(id: id)
      @trigger 'game:join'
    # we have no registered players or game
    attract:
      arrive: ->
        # on the first user added, go to startup
        @listenTo @game.players, 'add', ->
          @go('startup')
  
      exit: ->
        @stopListening @game.players, 'add'

    # the first player joined
    startup:
      arrive: ->

        @listenTo @timer, 'end', -> @go 'cleanup'
        @timer.limit = App.time.waitForPlayers
        @timer.start()

        @listenTo @game.state('recruit.ready'), 'arrive', =>
          # stop listening to the game reset timer
          @stopListening @timer, 'end'

          @timer.limit = App.time.playerAdded
          @timer.reset()

          @listenTo @timer, 'end', @startGame

          @listenTo @game.players, 'add', ->
            @timer.reset()

      exit: ->
        @stopListening @game.state('recruit.ready'), 'arrive'
        @stopListening @timer, 'end'
        @stopListening @game.players, 'add'

    # there is an active game running
    gameplay:
      next: 'cleanup'
      arrive: ->
        @game.startGame()
        @listenTo @game, 'game:end', => @go 'cleanup'

      exit: ->
        @stopListening @game, 'game:end'
    # the last game finished
    cleanup:
      arrive: ->
        @listenTo @timer, 'end', => @go 'attract'
        @timer.limit = App.time.gameCleanup
        @timer.start()

      exit: ->
        @stopListening @timer, 'end'
        @game.destroy()
        @game.clear()
        @game = new Models.Game()
