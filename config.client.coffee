module.exports =
  defaults:
    deployHost: "nodesque.2013.nodeknockout.com"
    protocol: 'https'
  production:
    hostname: "nodesque.2013.nodeknockout.com"
  development:
    hostname: "localhost"
    protocol: 'http'
    port: 8000
  staging:
    hostname: "staging"
    protocol: 'https'
    port: null 
