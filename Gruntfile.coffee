_ = require('underscore')

module.exports = (grunt) ->
  vPkg = [
    "jquery", "underscore", "state", "buzz", "phono", "backbone.projections",
    "backbone", "backbone.marionette", "url", "backbone.picky"
    "socket.io-client", "underscore.deferred", "debug", "Nonsense"
  ]

  shim = ["jquery", "buzz", "phono", "backbone.picky"]

  vAlias = for pkg in _.difference(vPkg, shim)
    "#{pkg}:"

  grunt.initConfig
    watch:
      all:
        files: ["*/*.coffee", "templates/*.jade", "css/*.css", "css/*.less"]
        tasks: ["browserify:templates", "browserify:client", "less", "concat"]
        options:
          atBegin: ["default"]
          livereload: true
    nodemon:
      dev:
        options:
          file: "./server.js"
          ignoredFiles: ["README.md", "node_modules/**"]
          watchedFolders: [
            'build/js',
            'views',
            'build/css',
            'voice',
            'models',
            'socket',
            'bots',
            'app',
            'state'
          ]
          watchedExtensions: ["coffee", "jade", 'css']

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
          sourceMap: true
          sourceMapFile: 'css/style.less'
          paths: [__dirname + "/bower_components/lesshat/build/"]
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
            buzz:
              path: "bower_components/buzz/dist/buzz.min.js"
              exports: "buzz"
              depends:
                jquery: "$"
            phono:
              path: "bower_components/phono/releases/master/jquery.phono.js"
              exports: "phono"
              depends:
                jquery: "$"
            "backbone.picky":
              path: "bower_components/backbone.picky/lib/backbone.picky.js"
              exports: "Backbone"
              depends:
                backbone: "Backbone"
                underscore: "_"

      templates:
        files:
          "build/js/templates.js": ["templates/*.jade", "!templates/*.server.jade"]
        options:
          debug: true
          transform: ['jadeify2']
          aliasMappings:
            src: ['templates/*.jade', "!templates/*.server.jade"]

      client:
        src: ["app/app.client.coffee"],
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
            'build/js/client.js']
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

