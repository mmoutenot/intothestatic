express = require 'express'
exports.express = express

#################
# database setup
#################
# Mongo
mongoHostname = process.env.MONGO_URL || 'mongodb://localhost/test'
mongoose = require 'mongoose'
mongoose.connect mongoHostname
exports.mongoose = mongoose

db = mongoose.connection
db.on "error", console.error.bind(console, "connection error:")
db.once "open", callback = ->
  console.log 'connected to mongodb'

# Redis
exports.REDIS_PORT = process.env.REDIS_PORT || 6379
exports.REDIS_HOST = process.env.REDIS_HOST || '127.0.0.1'
exports.REDIS_URL = process.env.REDIS_URL

RedisStore = require('connect-redis')(express)
exports.redisStore = RedisStore

#################
# webserver setup
#################
appPort = process.env.PORT or 3000
http = require 'http'

app = express()
app.set 'view engine', 'jade'
server = http.createServer(app).listen appPort

exports.app         = app
exports.server      = server
exports.appPort     = appPort
exports.httpClient  = require 'http'
exports.HOSTNAME    = process.env.IG_HOSTNAME
exports.debug       = true

#################
# socket setup
#################
io = require 'socket.io'
io = io.listen server

exports.io = io

#################
# instagram setup
#################
exports.CLIENT_ID     = process.env.IG_CLIENT_ID or 'CLIENT_ID'
exports.CLIENT_SECRET = process.env.IG_CLIENT_SECRET or 'CLIENT_SECRET'
exports.SUB_ENDPOINT  = 'https://api.instagram.com/v1/subscriptions'
exports.SUB_CALLBACK  = exports.HOSTNAME + '/callbacks/tag/'
Instagram = require 'instagram-node-lib'
exports.inst = Instagram
