game =
  startup:
    phaseTime: 300000
    startTime: 1384027686714
    players: [
      { name: 'Edward', role: 'werewolf' }
      { name: 'Gaylord', role: 'seer' }
      { name: 'Arturo', role: 'villager' }
      { name: 'Dafydd', role: 'villager' }
      { name: 'Florence', role: 'villager' }
      { name: 'Juniper', role: 'villager' }
      { name: 'Colwyn', role: 'villager' }
    ]
  rounds: []

game.rounds.push
  actions:
    night: [
      { action: 'seen', player: 'Gaylord', target: 'Arturo' }
    ]
    day:[
      { action: 'lynch', player: 'Edward', target: 'Gaylord' }
      { action: 'lynch', player: 'Gaylord', target: 'Edward' }
      { action: 'lynch', player: 'Arturo', target: 'Colwyn' }
      { action: 'lynch', player: 'Dafydd', target: 'Juniper' }
      { action: 'lynch', player: 'Florence', target: 'Colwyn' }
      { action: 'lynch', player: 'Juniper', target: 'Colwyn' }
      { action: 'lynch', player: 'Colwyn', target: 'Juniper' }
    ]
  deaths:
    night: false
    day: 'Arturo'
      
module.exports = game
