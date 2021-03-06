_ = require('underscore')

game =
  _state: 'round.day'
  players: []
  rounds: []

timer =
  _state: 'inactive.stopped'
  limit: '30000'

game.players.push { id: 'Edward', name: 'Edward', role: 'werewolf' }
game.players.push { id: 'Narrator', name: 'Narrator', role: 'villager' }
game.players.push { id: 'Gaylord', name: 'Gaylord', role: 'seer' }
game.players.push { id: 'Arturo', name: 'Arturo', role: 'villager' }
game.players.push { id: 'Dafydd', name: 'Dafydd', role: 'villager' }
game.players.push { id: 'Florence', name: 'Florence', role: 'villager' }
game.players.push { id: 'Juniper', name: 'Juniper', role: 'villager' }
game.players.push { id: 'Colwyn', name: 'Colwyn', role: 'villager' }


playerStates =
  Narrator: 'dead'
  Edward: 'alive.day.lynching'
  Gaylord: 'alive.day.lynching'
  Arturo: 'dead'
  Dafydd: 'alive.day.lynching'
  Florence: 'alive.day.lynching'
  Juniper: 'alive.day.lynching'
  Colwyn: 'dead'

game.players = _(game.players).map (p) ->
  p._state = playerStates[p.id]
  p

game.rounds.push
  id: 'night1'
  phase: 'night'
  number: 0
  activeTotal: 1
  _state: 'complete.died'
  actions: [
    { action: 'eat', id: 'Edward', target: 'Narrator' }
    { action: 'see', id: 'Gaylord', target: 'Arturo' }
  ]
  death: 'Narrator'


game.rounds.push
  id: 'day1'
  phase: 'day'
  number: 1
  activeTotal: 7
  _state: 'complete.died'
  actions: [
    { action: 'lynch', id: 'Edward', target: 'Gaylord' }
    { action: 'lynch', id: 'Gaylord', target: 'Edward' }
    { action: 'lynch', id: 'Arturo', target: 'Colwyn' }
    { action: 'lynch', id: 'Dafydd', target: 'Juniper' }
    { action: 'lynch', id: 'Florence', target: 'Colwyn' }
    { action: 'lynch', id: 'Juniper', target: 'Colwyn' }
    { action: 'lynch', id: 'Colwyn', target: 'Juniper' }
  ]
  death: 'Colwyn'

game.rounds.push
  id: 'night2'
  phase: 'night'
  number: 2
  activeTotal: 2
  _state: 'complete.died'
  actions: [
    { action: 'see', id: 'Gaylord', target: 'Edward'}
    { action: 'eat', id: 'Edward', target: 'Arturo'}
  ]
  death: 'Arturo'

game.rounds.push
  id: 'day2'
  phase: 'day'
  number: 3
  activeTotal: 5
  _state: 'votes.all'
  actions: [
    { action: 'lynch', id: 'Juniper', target: 'Edward'}
    { action: 'lynch', id: 'Edward', target: 'Juniper'}
    { action: 'lynch', id: 'Florence', target: 'Dafydd'}
    { action: 'lynch', id: 'Dafydd', target: 'Florence'}
    { action: 'lynch', id: 'Gaylord', target: 'Edward'}
  ]
  death: 'Edward'

module.exports =
  game: game
  timer: timer
