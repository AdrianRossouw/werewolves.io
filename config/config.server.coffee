module.exports =
  defaults:
    secret: 'sasquatch'
    token: "22656a3121261b4db6509f369c89e7067a36eff14b6a1fd5f0438699b894211590fdca2edd37de9fd1fdd7e2"
    port: 8000
  production:
    host: "werewolves.io"
    port: 8000
    socketUrl: 'https://werewolves.io'
  development:
    host: "localhost"
  staging:
    host: "staging"
