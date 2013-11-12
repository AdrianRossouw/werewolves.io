App      = require('../app')
state    = require('state')
_        = require('underscore')
Backbone = require('backbone')
Models   = App.module "Models"

# The world acts as the container for the other
# pieces of state.
class Models.World extends Models.BaseModel
  @attribute 'game'
  @attribute 'sessions'
  state s = @::,
    attract: state 'initial'
    gameplay: state

module.exports = Models
