module.exports =
  defaults:
    secret: 'sasquatch'
    token: "24622b46a3c1f64c80645d07062768367fed91bcdb53eaaa2fdfd03494d6fde2204b7d471db81435b209af71"
    port: 8000
  production:
    host: "werewolves.io"
    port: 8000
    token: "24622b46a3c1f64c80645d07062768367fed91bcdb53eaaa2fdfd03494d6fde2204b7d471db81435b209af71"
    socketUrl: 'https://werewolves.io'
  development:
    host: "localhost"
    token: "20bbb2ad90024c438de275b0e4a04719dd6ec4c6721751b72c3859032b3d72889c825e28ca3e9c7089b8a41a"
  staging:
    host: "staging"
    token: "24622b46a3c1f64c80645d07062768367fed91bcdb53eaaa2fdfd03494d6fde2204b7d471db81435b209af71"
