module.exports =
  defaults:
    appId: 'app:9990074845'
    apiKey: "24622b46a3c1f64c80645d07062768367fed91bcdb53eaaa2fdfd03494d6fde2204b7d471db81435b209af71"
    deployHost: "nodesque.2013.nodeknockout.com"
    protocol: 'https'
  production:
    hostname: "nodesque.2013.nodeknockout.com"
    apiKey: "225d706e4a9b9549915e498cca3c3207d0c4f4bc38aed4e31fdb06753aef960c92b16853f76c4f3274c19de7"
    appId: 'app:9990060651'
    protocol: 'http'
    port: null
  staging:
    hostname: "staging"
    protocol: 'https'
    port: null
  development:
    hostname: "localhost"
    protocol: 'http'
    port: 8000
