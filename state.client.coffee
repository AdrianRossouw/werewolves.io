# Client-side application state
#
# Inherits and decorates the shared application state

App = require('./app.coffee')
State = require('./state.coffee')
Models = require('./models.coffee')

# TODO: set the world state based on a dump given to us
# TODO: provide mechanisms to apply partial state updates

App.addInitializer (opts) ->
  @world = new Models.World()
  @world.game = new Models.Game
    state: 'day'
    round: 1
    phaseTime: 300000
    startTime: Date.now - 650000

  @world.game.players.add
    name: 'Edward'
    role: 'werewolf'
    vote: 'Gaylord'

  @world.game.players.add
     name: 'Gaylord'
     role: 'seer'
     vote: 'Edward'
     seen: ['Colwyn']

   @world.game.players.add
     name: 'Arturo'
     role: 'villager'
     vote: 'Colwyn'

   @world.game.players.add
     name: 'Dafydd'
     role: 'villager'
     vote: 'Juniper'


   @world.game.players.add
     name: 'Florence'
     role: 'villager'
     vote: 'Colwyn'


   @world.game.players.add
     name: 'Juniper'
     role: 'villager'
     vote: 'Colwyn'


   @world.game.players.add
     name: 'Colwyn'
     role: 'villager'
     vote: 'Juniper'

module.exports = State
