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

Voice.say = (tropo, text) ->
  tropo.say text, null, null, null, null, "simon"

# Play an audio file over the voip channel.
Voice.audio = (tropo, name) ->
  @say tropo, "http://hosting.tropo.com/5010929/www/audio/#{name}.mp3"

# Session is placed in a conference where everyone is muted.
Voice.asleep = (tropo) ->
  @say tropo, 'voice chat disabled'
  tropo.conference "asleep", true, "asleep", false, null, '#'

# Session can listen and speak to others currently awake.
Voice.awake = (tropo) ->
  @say tropo, 'voice chat enabled'
  tropo.conference "awake", null, "awake", false, null, '#'

# Session can only listen in to conversations, not talk.
Voice.spectate = (tropo) ->
  @say tropo, 'you are muted'
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

Voice.nightInstruct = (tropo, env) ->
  # for specific roles again
  switch env?.player?.role
    when 'villager'
      @say tropo, 'you are asleep in your bed'

    when 'werewolf'
      @say tropo, 'The werewolves shed their human skin and choose their unwitting meal for the night ...'

    when 'seer'
      @say tropo, 'The Seer awakes, having had a a dream concerning the true nature of one person …'

Voice.voteResult = (tropo, env) ->
  if env.player?.id is env.death?.id
    return @say tropo, "The final counts for most-likely-to-dance-on-the-end-of-a-rope are in, and the winner is … you!"

  if env.lastRound?.state().name is 'survived'
    return @say tropo, "Unable to reach a decision, the villagers return to their homes. The upside of this is that no one died today, sadly, the downside is the same."

  # for specific roles again
  switch env?.player?.role
    when 'villager'
      @say tropo, 'Having sent one of your own to an untimely demise, you return to your homes, grief-stricken and down-hearted, unless of course you never liked them in the first place.'

    when 'werewolf'
      @say tropo, "As the trap opens below them, the villager's screams become savage growls, sharp teeth appear and then swiftly recede as their neck is broken. You have rooted out a wolf. Celebrate cautiously, there may yet be more."

    when 'seer'
      @say tropo, 'Strung up your Seer? Oh dear, oh dear, oh dear.'

Voice.killResult = (tropo, env) ->
  if env.lastRound?.state().name is 'survived'
    return @say tropo, "Unable to agree on their victim, the werewolves slip back into their human disguises and disperse for the night. For once, a peaceful night passes in the village of Fangley."


# To be played on the first night
Voice.firstNight = (tropo, env) ->
  # for everyone
  @say tropo, "Night falls on the Village, and all are struck with an urgent need to lie down and sleep, a well-know side-effect of the locally brewed cider, which is not called Narcolep's Nectar for nothing."

  switch env?.player?.role
    when 'villager'
      @say tropo, 'If you were dealt a card that looks like this, and are wondering where you are on the food chain, it grieves me to inform you: you are it., though you are not without a voice. Each morning a vote shall be called to determine which of your fellow citizens could be shape-shifting abominations. Use your vote wisely, consult with your peers, and shave that beard off right now!'

    when 'werewolf'
      @say tropo, "If you were dealt a card that look like this, you are one of the shape-shifting abominations plaguing this picturesque little village. Each night you and your fellow monsters will be asked to choose a suitable snack. Move stealthily and don't forget to floss. Also, shave that beard off right now!"

    when 'seer'
      @say tropo, 'If you were dealt a card that looks like this, you have been given the power to tell the food from the feeders. Every night you will have a dream, revealing the true nature of one of the other players. Be careful with how you share the knowledge gained, an obvious Seer will receive special attention from those who wish to remain unseen.'


  @nightInstruct tropo, env

  @awakeByRole tropo, env.player

# first day
Voice.firstDay = (tropo, env) ->
  @killResult tropo, env
  @say tropo, 'The effects of the local tipple wear off, and you all awake to find one of you number has been brutally mangled and enthusiastically munched upon during the course of the night. The rational explanation is that they were attacked by wild animals. For every rational explanation, there is also an irrational one. The killers are among you, cast your votes now …'
  @awake(tropo)

# each subsequent night
Voice.night = (tropo, env) ->
  @voteResult tropo, env
  @say tropo, 'Dark, brooding clouds blot out the sun, a storm is brewing to the North. Perhaps the rain will wash away the stains of terror and apprehension, or only hide the movements of those who mean you harm … most of you will only know by dawn, after a dreamless, fitful sleep.'
  @nightInstruct tropo, env
  @awakeByRole(tropo, env.player)

# each subsequent day
Voice.day = (tropo, env) ->
  @say tropo, 'The sun rises lazily this day, poking feeble rays through the early morning mist. The mist parts to reveal a mangled hand, a severed leg, and another headless torso, covered in bite-marks and what appears to be barbecue sauce. These furry bastards have become as bold as brass. Stern measures, dear ladies and gentlemen, will definitely need to be taken.'
  @awake tropo

##### victory conditions
Voice.wolvesWin = (tropo, env) ->
  @say tropo, 'After greedily crunching on the bones of the very last villager, the Wolves turn their gazes north, where, in the distance, they see a whisp of chimney smoke spiralling up into the night sky. The Wolves slip into the woods, and follow the smell of the woodsmoke. Food, glorious food.'
  @awake tropo

Voice.villagersWin = (tropo, env) ->
  @say tropo, 'As the final werewolf breathes its last on the gallows, the remaining villagers dance for joy, singing jubilantly, each vowing to themselves never to forget the lessons they have learned: Facial hair marks you for extermination, and sometimes wild speculation is as effective as actual information.'
  @awake tropo
