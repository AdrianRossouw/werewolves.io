_ = require('underscore')

game =
  startTime: 1384027686714
  _state: 'round.day'
  players: []
  rounds: []

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
  Edward: 'alive.lynching'
  Gaylord: 'alive.lynching'
  Arturo: 'dead'
  Dafydd: 'alive.lynching'
  Florence: 'alive.lynching'
  Juniper: 'alive.lynching'
  Colwyn: 'dead'

_(playerStates).each (state, id) ->
  _(game.players).findWhere(id: id)._state = state


game.rounds.push
  id: 'night1'
  phase: 'night'
  number: 0
  activeTotal: 1
  _state: 'complete.died'
  actions: [
    { action: 'eaten', id: 'Edward', target: 'Narrator' }
    { action: 'seen', id: 'Gaylord', target: 'Arturo' }
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
    { action: 'seen', id: 'Gaylord', target: 'Edward'}
    { action: 'eaten', id: 'Edward', target: 'Arturo'}
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
