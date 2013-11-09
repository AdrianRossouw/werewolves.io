App = require('./app.coffee')
Backbone = require('backbone')

Views = App.module "Views"

class Views.Sidebar extends Backbone.Marionette.ItemView
  template: require('./templates/sidebar.jade')

module.exports = Views
