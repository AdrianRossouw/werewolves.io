_ = require('underscore')

module.exports = (grunt) ->
  vPkg = [
    "jquery", "underscore", "state",
    "backbone", "backbone.marionette",
    "socket.io-client", "underscore.deferred"
  ]

  shim = ["jquery"]

  vAlias = for pkg in _.difference(vPkg, shim)
    "#{pkg}:"

  grunt.initConfig
    watch:
      all:
        files: ["*.coffee", "views/*.jade", "templates/*.jade", "css/*.css", "css/*.less"]
        tasks: ["browserify:templates", "browserify:client", "less", "concat"]
        options:
          atBegin: ["default"]
          livereload: true

    nodemon:
      dev:
        options:
          file: "server.coffee"
          ignoredFiles: ["README.md", "node_modules/**"]
          watchedFolders: ['build/js', 'views', 'build/css']
          watchedExtensions: ["coffee", "jade", 'js', 'css']

    concurrent:
      dev:
        tasks: ["watch:all", "nodemon:dev"]
        options:
          logConcurrentOutput: true
    less:
      dist:
        files:
          "build/css/style.css": ["css/style.less"]
        options:
          paths: ["bower_components/bootstrap/less"]

    browserify:
      vendor:
        files:
          "build/js/vendor.js": vPkg
        options:
          alias: vAlias
          shim:
            jquery:
              path: "bower_components/jquery/jquery.min.js"
              exports: "$"


      templates:
        files:
          "build/js/templates.js": ["templates/*.jade"]
        options:
          transform: ['jadeify2']
          aliasMappings:
            src: ['templates/*.jade']

      client:
        src: ["client.coffee"],
        dest: "build/js/client.js"
        options:
          debug: true
          transform: ['coffeeify']
          external: vPkg.concat ["templates/*.jade"]

    uglify:
      vendor:
        files:
          'build/js/vendor.min.js': ['build/js/vendor.js']
      templates:
        files:
          'build/js/templates.min.js': ['build/js/templates.js']
      client:
        files:
          'build/js/client.min.js': ['build/js/client.js']


    cssmin:
      dist:
        files:
          "build/css/style.min.css": ["build/css/style.css"]

    concat:
      dev:
        files:
          'build/js/app.js': [
            'build/js/vendor.js',
            'build/js/templates.js',
            'build/js/client.js'
          ]
          'build/js/app.min.js': [
            'build/js/vendor.min.js',
            'build/js/templates.min.js',
            'build/js/client.min.js']

  
  grunt.loadNpmTasks "grunt-browserify"
  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-contrib-less"
  grunt.loadNpmTasks "grunt-contrib-cssmin"
  grunt.loadNpmTasks "grunt-nodemon"
  grunt.loadNpmTasks "grunt-concurrent"
 
  grunt.registerTask "browserify:all", [
    "browserify:vendor",
    "browserify:templates",
    "browserify:client"]


  grunt.registerTask "uglify:all", [
    "uglify:vendor",
    "uglify:templates",
    "uglify:client"]



  # Default task(s).
  grunt.registerTask "default", [
    "browserify:all",
    "less",
    "cssmin",
    'uglify:all',
    'concat']

