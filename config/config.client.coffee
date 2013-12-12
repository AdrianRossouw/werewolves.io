module.exports =
  defaults:
    appId: 'app:9990043172'
    apiKey: "24622b46a3c1f64c80645d07062768367fed91bcdb53eaaa2fdfd03494d6fde2204b7d471db81435b209af71"
    deployHost: "werewolves.io"
    protocol: 'https'
    port: null
  production:
    hostname: "werewolves.io"
    protocol: 'https'
  staging:
    hostname: "staging"
    protocol: 'https'
  development:
    hostname: "localhost"
    protocol: 'http'
    port: 8000
