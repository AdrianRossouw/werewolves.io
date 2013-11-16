require('coffee-script');
App = require('./app/app.server.coffee');

App.start(App.config());

module.exports = App;
