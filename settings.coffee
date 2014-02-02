# http://expressjs.com/migrate.html
express = require 'express'
app     = express()

appPort = process.env.IG_APP_PORT or 3000

http   = require 'http'
server = http.createServer(app).listen appPort
io     = require('socket.io').listen server
ig     = require('instagram-node').instagram()

exports.io            = io
exports.app           = app
exports.appPort       = appPort
exports.server        = server
exports.CLIENT_ID     = process.env.IG_CLIENT_ID or 'CLIENT_ID'
exports.CLIENT_SECRET = process.env.IG_CLIENT_SECRET or 'CLIENT_SECRET'
exports.SUB_ENDPOINT  = 'https://api.instagram.com/v1/subscriptions'
exports.SUB_CALLBACK  = 'http://9904515.ngrok.com/callbacks/tag/'
exports.httpClient    = ((if process.env.IG_USE_INSECURE then require('http') else require('https')))
exports.apiHost       = process.env.IG_API_HOST or 'api.instagram.com'
exports.apiPort       = process.env.IG_API_PORT or null
exports.basePath      = process.env.IG_BASE_PATH or ''
exports.REDIS_PORT    = 6486
exports.REDIS_HOST    = '127.0.0.1'
exports.debug         = true

app.set 'view engine', 'jade'

# set up instagram client
Instagram = require 'instagram-node-lib'
Instagram.set('client_id', exports.CLIENT_ID)
Instagram.set('client_secret', exports.CLIENT_SECRET)
Instagram.set('redirect_uri', 'http://9904515.ngrok.com/oauth/callback')
exports.inst = Instagram

RedisStore = require('connect-redis')(express)

app.configure ->
  app.use express.cookieParser()
  app.use express.session(
    store: new RedisStore(
      host: exports.REDIS_HOST
      port: exports.REDIS_PORT
      db: 2
      pass: ''
    )
    secret: process.env.SESSION_SECRET or '1asdfkljh32rsadfa34'
  )

  app.use express.methodOverride()
  app.use express.bodyParser()
  app.use app.router
  app.use express.static(__dirname + '/public/')

  ig.use(client_id: exports.CLIENT_ID, client_secret: exports.CLIENT_SECRET)

app.configure 'development', ->
  app.use express.logger()
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true
  )

app.configure 'production', ->
  app.use express.errorHandler()
