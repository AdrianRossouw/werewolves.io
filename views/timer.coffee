Backbone = require('backbone')
App = require('../app')
Views = App.module "Views"

class Views.Timer extends Backbone.Marionette.ItemView
  tagName: 'span'
  className: 'timer'
  template: =>
    @model.remaining() / 1000

  modelEvents:
    'tick': 'render'

