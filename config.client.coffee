module.exports =
  defaults:
    deployHost: "nodesque.2013.nodeknockout.com"
    protocol: 'https'
  production:
    hostname: "nodesque.2013.nodeknockout.com"
  staging:
    hostname: "staging"
    protocol: 'https'
    port: null
  development:
    hostname: "localhost"
    protocol: 'http'
    port: 8000
