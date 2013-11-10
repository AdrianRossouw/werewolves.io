module.exports =
  defaults:
    appId: 'app:9990067291'
    apiKey: "2265cd3df8d1654ab141efc3cb95d0c4c2ec958034ee4353d1fb022571cdc11ae79339062bd5012a65801aab"
    deployHost: "werewolves.io"
    protocol: 'https'
  production:
    hostname: "werewolves.io"
    apiKey: "225d706e4a9b9549915e498cca3c3207d0c4f4bc38aed4e31fdb06753aef960c92b16853f76c4f3274c19de7"
    appId: 'app:9990067290'
    protocol: 'https'
  staging:
    hostname: "staging"
    appId: "app:9990067289"
    apiKey: "22656a3121261b4db6509f369c89e7067a36eff14b6a1fd5f0438699b894211590fdca2edd37de9fd1fdd7e2"
    protocol: 'https'
    port: null
  development:
    hostname: "localhost"
    protocol: 'http'
    port: 8000
