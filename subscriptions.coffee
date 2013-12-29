redis    = require 'redis'
fs       = require 'fs'
jade     = require 'jade'
settings = require './settings'
helpers  = require './helpers'

app = settings.app
io  = settings.io

subscriptionPattern = 'channel:*'

# We use Redis's pattern subscribe command to listen for signals
# notifying us of new updates.
redisClient = redis.createClient(settings.REDIS_PORT, settings.REDIS_HOST)

pubSubClient = redis.createClient(settings.REDIS_PORT, settings.REDIS_HOST)
pubSubClient.psubscribe subscriptionPattern

pubSubClient.on 'pmessage', (pattern, channel, message) ->
  helpers.debug 'Handling pmessage'

  # Every time we receive a message, we check to see if it matches
  # the subscription pattern. If it does, then go ahead and parse it.
  if pattern is subscriptionPattern
    try
      data = JSON.parse(message)['data']

      # Channel name is really just a 'humanized' version of a slug
      # san-francisco turns into san francisco. Nothing fancy, just
      # works.
      channelName = channel.split(':')[1].replace(/-/g, ' ')
    catch e
      return

    # Store individual media JSON for retrieval by homepage later
    for index of data
      media = data[index]
      media.meta = {}
      media.tag = channelName
      redisClient.lpush 'media:objects', JSON.stringify(media)

    # Send out whole update to the listeners
    update =
      type: 'newMedia'
      media: data
      channelName: channelName

    io.sockets.emit('newMedia-'+channelName, data)
    # for sessionId of io.sockets.clients
    #   socket.clients[sessionId].send JSON.stringify(update)

io.sockets.on "connection", (socket) ->
  socket.emit "greet",
    greeting: "hello"
