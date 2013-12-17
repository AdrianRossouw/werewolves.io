Backbone = require('backbone')
App = require('../app')
Views = App.module "Views"

class Views.Timer extends Backbone.Marionette.ItemView
  tagName: 'span'
  className: 'timer'
  template: => ''

  modelEvents:
    'tick': 'render'
    'change': 'render'

  onRender: ->
    @$el.toggleClass 'paused', @model.state().name == 'paused'
    @$el.toggleClass 'stopped', @model.state().name == 'stopped'
    @$el.toggleClass 'active', @model.state().name == 'active'

    if @model.state().name == 'active'
      pcnt = @model.remaining() / @model.limit * 100
      @$el.toggleClass 'much-time', pcnt >= 50
      @$el.toggleClass 'some-time', 50 > pcnt > 25
      @$el.toggleClass 'little-time', pcnt <= 25
      @$el.css 'width', "#{pcnt}%"
