# Shared model code.
#
# These form the base agreed upon data structures that will be extended
# by the front-end and/or backend.
App = require('./app.coffee')
Backbone = require('backbone')

Models = App.module "Models"

# Singular representation of all the various
# contact mechanisms available.
#
# We are multi-plexed over REST/WSS/SIP/Tropo,
# so we need to handle cases like multiple tabs etc.
#
# Sessions might or might not be listening in to the
# current game.
class Models.Session extends Backbone.Model {}

class Models.Sessions extends Backbone.Collection
  model: Models.Session

# A player who has joined an active or upcoming
# game.
class Models.Player extends Models.Session
  defaults:
    session: null
    role: null
    state: null
    vote: null

class Models.Players extends Models.Sessions
  model: Models.Player

# A game that is running or will be starting.
class Models.Game extends Backbone.Model
  defaults:
    players: new Models.Players()
    startTime: null
    round: 0
    phaseTime: 0
    state: null

# The world acts as the container for the other
# pieces of state.
class Models.World extends Backbone.Model
  defaults:
    game: null
    state: null
    sessions: new Models.Sessions()

module.exports = Models
