App = require('../app')
Voice = App.module "Voice"
State = App.module "State"
tropo = require('tropo-webapi')

# Main script entry point for the voip
# channel.
#
# This will be fired for all changes in
# world state, and will pass in a normalized
# state, relative to the session.
Voice.script = (tropo, env) ->

  switch env.world.state().path()
    when 'attract', 'startup'
      @intro tropo, env

    when 'gameplay'
      switch env.game.state().name
        when 'firstNight'
          @firstNight tropo, env

        when 'firstDay'
          @firstDay tropo, env

        when 'night'
          @night tropo, env

        when 'day'
          @day tropo, env

        else @spectate tropo

    when 'cleanup'
      switch env.game.state().path()
        when 'victory.werewolves'
          @wolvesWin tropo, env

        when 'victory.villagers'
          @villagersWin tropo, env

        else @awake tropo

    else @awake tropo

# Play an audio file over the voip channel.
Voice.audio = (tropo, name) ->
  tropo.say "http://hosting.tropo.com/5010929/www/audio/#{name}.mp3"

# Session is placed in a conference where everyone is muted.
Voice.asleep = (tropo) ->
  tropo.say 'you go to sleep'
  tropo.conference "asleep", true, "asleep", false, null, '#'

# Session can listen and speak to others currently awake.
Voice.awake = (tropo) ->
  tropo.say 'you wake up'
  tropo.conference "awake", null, "awake", false, null, '#'

# Session can only listen in to conversations, not talk.
Voice.spectate = (tropo) ->
  tropo.say 'you are spectating'
  tropo.conference "awake", true, "awake", false, null, '#'

# switch the players to the mute/active conference
Voice.awakeByRole = (tropo, player) ->
  return @spectate(tropo) unless player

  switch player.state().name
    when 'dead'
      @spectate(tropo)

    when 'eating'
      @awake(tropo)

    else @asleep(tropo)

# introductory, to be played in attract mode
Voice.intro = (tropo, env) ->
  @audio tropo, "Introduction"
  @awake tropo

# To be played on the first night
Voice.firstNight = (tropo, env) ->

  switch env?.player?.role
    when 'villager'
      tropo.say 'you are a villager'

    when 'werewolf'
      tropo.say 'you are a werewolf'

    when 'seer'
      tropo.say 'you are the seer'

  # for everyone
  tropo.say 'the first night'

  # for specific roles again
  switch env?.player?.role
    when 'villager'
      tropo.say 'kill somebody'

    when 'seer'
      tropo.say 'dream about somebody'

  @awakeByRole tropo, env.player

# first day
Voice.firstDay = (tropo, env) ->
  tropo.say 'first day'
  @awake(tropo)

# each subsequent night
Voice.night = (tropo, env) ->
  tropo.say 'next night'
  @awakeByRole(tropo, env.player)

# each subsequent day
Voice.day = (tropo, env) ->
  tropo.say 'next day'
  @awake tropo

##### victory conditions
Voice.wolvesWin = (tropo, env) ->
  tropo.say 'wolves win'
  @awake tropo

Voice.villagersWin = (tropo, env) ->
  tropo.say 'villagers win'
  @awake tropo
