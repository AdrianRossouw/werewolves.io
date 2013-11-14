game =
  startTime: 1384027686714
  _state: 'round.day'
  players: [
    { id: 'Edward', name: 'Edward', role: 'werewolf' }
    { id: 'Gaylord', name: 'Gaylord', role: 'seer' }
    { id: 'Arturo', name: 'Arturo', role: 'villager' }
    { id: 'Dafydd', name: 'Dafydd', role: 'villager' }
    { id: 'Florence', name: 'Florence', role: 'villager' }
    { id: 'Juniper', name: 'Juniper', role: 'villager' }
    { id: 'Colwyn', name: 'Colwyn', role: 'villager' }
  ]
  rounds: []

game.rounds.push
  id: 'night1'
  phase: 'night'
  number: 0
  activeTotal: 1
  actions: [
    { action: 'seen', id: 'Gaylord', target: 'Arturo' }
  ]
  death: false


game.rounds.push
  id: 'day1'
  phase: 'day'
  number: 1
  activeTotal: 7
  actions: [
    { action: 'lynch', id: 'Edward', target: 'Gaylord' }
    { action: 'lynch', id: 'Gaylord', target: 'Edward' }
    { action: 'lynch', id: 'Arturo', target: 'Colwyn' }
    { action: 'lynch', id: 'Dafydd', target: 'Juniper' }
    { action: 'lynch', id: 'Florence', target: 'Colwyn' }
    { action: 'lynch', id: 'Juniper', target: 'Colwyn' }
    { action: 'lynch', id: 'Colwyn', target: 'Juniper' }
  ]
  death: 'Arturo'

game.rounds.push
  id: 'night2'
  phase: 'night'
  number: 1
  activeTotal: 2
  actions: [
    { action: 'seen', id: 'Gaylord', target: 'Edward'}
    { action: 'eaten', id: 'Edward', target: 'Arturo'}
  ]
  death: 'Arturo'

game.rounds.push
  id: 'day2'
  phase: 'day'
  number: 3
  activeTotal: 6
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
