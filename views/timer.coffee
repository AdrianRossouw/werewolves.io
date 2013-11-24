Backbone = require('backbone')
App = require('../app')
Views = App.module "Views"

class Views.Timer extends Backbone.Marionette.ItemView
  tagName: 'span'
  className: 'timer'
  template: =>
    "#{Math.round(@model.remaining() / 1000)} seconds remaining"

  modelEvents:
    'tick': 'render'
    'change': 'render'

  onRender: ->
    if @model.state().name is 'active'
      @$el.removeClass 'hide'
    else
      @$el.addClass 'hide'

