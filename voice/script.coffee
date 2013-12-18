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
    when 'startup'
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

strings = require('./strings')

Voice.say = (tropo, key) ->
  text = strings[key] or 'text not found'
  tropo.say text, null, null, null, null, "simon"

# Play an audio file over the voip channel.
Voice.audio = (tropo, name) ->
  tropo.say "http://hosting.tropo.com/5010929/www/audio/#{name}.mp3"

# Session is placed in a conference where everyone is muted.
Voice.asleep = (tropo) ->
  @say tropo, 'voiceDisabled'
  tropo.conference "asleep", true, "asleep", false, null, '#'

# Session can listen and speak to others currently awake.
Voice.awake = (tropo) ->
  @say tropo, 'voiceEnabled'
  tropo.conference "awake", null, "awake", false, null, '#'

# Session can only listen in to conversations, not talk.
Voice.spectate = (tropo) ->
  @say tropo, 'muted'
  tropo.conference "awake", true, "awake", false, null, '#'

# switch the players to the mute/active conference
Voice.awakeNight = (tropo, player) ->
  return @spectate(tropo) unless player

  switch player.state().name
    when 'dead'
      @spectate(tropo)

    when 'eating'
      @awake(tropo)

    else @asleep(tropo)

# switch the players to the mute/active conference
Voice.awakeDay = (tropo, player) ->
  return @spectate(tropo) unless player

  switch player.state().name
    when 'dead'
      @spectate(tropo)
    else @awake(tropo)

# introductory, to be played in attract mode
Voice.intro = (tropo, env) ->
  @audio tropo, "Introduction"
  @awake tropo

Voice.nightInstruct = (tropo, env) ->
  # for specific roles again
  switch env?.player?.role
    when 'villager'
      @say tropo, 'villagerInstruct'

    when 'werewolf'
      @say tropo, 'wolfInstruct'

    when 'seer'
      @say tropo, 'seerInstruct'

Voice.voteResult = (tropo, env) ->
  if env.player?.id is env.death?.id
    return @say tropo, 'lynchYou'

  if env.lastRound?.state().name is 'survived'
    return @say tropo, 'lynchTied'

  # for specific roles again
  switch env?.death?.role
    when 'villager'
      @say tropo, 'lynchVillager'
    when 'werewolf'
      @say tropo, 'lynchWolf'
    when 'seer'
      @say tropo, 'lynchSeer'

Voice.killResult = (tropo, env) ->
  if env.lastRound?.state().name is 'survived'
    return @say tropo, 'wolvesTied'


# To be played on the first night
Voice.firstNight = (tropo, env) ->
  @say tropo, 'firstNight'

  switch env?.player?.role
    when 'villager'
      @say tropo, 'villagerTutorial'
    when 'werewolf'
      @say tropo, 'wolfTutorial'
    when 'seer'
      @say tropo, 'seerTutorial'

  @nightInstruct tropo, env
  @awakeNight tropo, env.player

# first day
Voice.firstDay = (tropo, env) ->
  @killResult tropo, env
  @say tropo, 'firstDay'
  @awakeDay tropo, env.player

# each subsequent night
Voice.night = (tropo, env) ->
  @voteResult tropo, env
  @say tropo, 'night'
  @nightInstruct tropo, env
  @awakeNight tropo, env.player

# each subsequent day
Voice.day = (tropo, env) ->
  @say tropo, 'day'
  @awakeDay tropo, env.player

##### victory conditions
Voice.wolvesWin = (tropo, env) ->
  @say tropo, 'wolvesWin'
  @awake tropo

Voice.villagersWin = (tropo, env) ->
  @say tropo, 'villagersWin'
  @awake tropo
