Backbone = require('backbone')
App = require('../app')
Views = App.module "Views"

class Views.Timer extends Backbone.Marionette.ItemView
  tagName: 'span'
  className: 'timer'
  template: =>
    return 'stopped' if @model.state().name is 'stopped'
    "#{Math.round(@model.remaining() / 1000)} seconds remaining"

  modelEvents:
    'tick': 'render'
    'change': 'render'

  onRender: ->
    @$el.toggleClass 'paused', @model.state().name == 'paused'
    @$el.toggleClass 'stopped', @model.state().name == 'stopped'
    @$el.toggleClass 'active', @model.state().name == 'active'
