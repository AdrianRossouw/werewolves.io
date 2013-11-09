# https://github.com/nko4/website/blob/master/module/README.md#nodejs-knockout-deploy-check-ins
require("nko") "XttLxcKtsOS2vf3i"
isProduction = (process.env.NODE_ENV is "production")
http = require("http")
port = ((if isProduction then 80 else 8000))

# http://blog.nodeknockout.com/post/35364532732/protip-add-the-vote-ko-badge-to-your-app
http.createServer((req, res) ->
  voteko = "<iframe src=\"http://nodeknockout.com/iframe/nodesque\" frameborder=0 scrolling=no allowtransparency=true width=115 height=25></iframe>"
  res.writeHead 200,
    "Content-Type": "text/html"

  res.end "<html><body>" + voteko + "</body></html>\n"
).listen port, (err) ->
  if err
    console.error err
    process.exit -1
  
  # if run as root, downgrade to the owner of this file
  if process.getuid() is 0
    require("fs").stat __filename, (err, stats) ->
      return console.error(err)  if err
      process.setuid stats.uid

  console.log "Server running at http://0.0.0.0:" + port + "/"
