# Shared model code.
#
# These form the base agreed upon data structures that will be extended
# by the front-end and/or backend.
App = require('./app.coffee')
Backbone = require('backbone')
state = require('state')
Models = App.module "Models"

# Create model attribute getter/setter property.
# From : http://srackham.wordpress.com/2011/10/16/getters-and-setters-for-backbone-model-attributes/
class BaseModel extends Backbone.Model
  @attribute = (attr) ->

    Object.defineProperty @prototype, attr,
      get: -> @get attr
      set: (value) ->
        attrs = {}
        attrs[attr] = value
        @set attrs


# Singular representation of all the various
# contact mechanisms available.
#
# We are multi-plexed over REST/WSS/SIP/Tropo,
# so we need to handle cases like multiple tabs etc.
#
# Sessions might or might not be listening in to the
# current game.
class Models.Session extends BaseModel
  state s = @::,
    offline: state 'initial'
    online: state
      socket: state
      sip: state
      voice: state


class Models.Sessions extends Backbone.Collection
  model: Models.Session

# A player who has joined an active or upcoming
# game.
class Models.Player extends BaseModel
  @attribute 'session'
  @attribute 'role'
  @attribute 'vote'
  state s = @::,
    lobby: state, 'initial'
    spectacting: state
    dead: state
    alive: state
      lynching: state
      seeing: state
      eating: state
      sleeping: state
        

class Models.Players extends Models.Sessions
  model: Models.Player

# A game that is running or will be starting.
class Models.Game extends BaseModel
  @attribute 'players'
  @attribute 'startTime'
  @attribute 'rounds'
  @attribute 'phaseTime'
  state s = @::,
    recruit: state 'initial'
    begin: state
    day: state
    night: state
    victory: state
      wolves: state
      villagers: state
    cleanup: state 'final'

# The world acts as the container for the other
# pieces of state.
class Models.World extends BaseModel
  @attribute 'game'
  @attribute 'sessions'
  state s = @::,
    attract: state 'initial'
    gameplay: state

module.exports = Models
