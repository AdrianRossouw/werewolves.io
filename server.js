require('coffee-script');
App = require('./app/app.server.coffee');

App.start(App.config());
App.Socket.start(App.config());
module.exports = App;
