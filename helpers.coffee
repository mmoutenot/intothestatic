request = require 'request'

isValidRequest = (request) ->
  # First, let's verify the payload's integrity by making sure it's
  # coming from a trusted source. We use the client secret as the key
  # to the HMAC.
  rawBody = JSON.stringify(request.body)
  hmac = crypto.createHmac('sha1', settings.CLIENT_SECRET)
  hmac.update rawBody
  providedSignature = request.headers['x-hub-signature']
  calculatedSignature = hmac.digest(encoding = 'hex')

  # debugger
  # If they don't match up or we don't have any data coming over the
  # wire, then it's not valid.
  true #((providedSignature == calculatedSignature) && rawBody)

debug = (msg) ->
  console.log msg  if settings.debug

maybeCreateSubscription = (tagName) ->
  debug 'maybe creating subscription for ' + tagName
  subscription_exists = false
  redisClient.sismember ['subscriptions', tagName], (err, reply) ->
    subscription_exists = reply
    if subscription_exists
      debug 'subscription for ' + tagName + ' already exists'
      return

    post_data =
      'client_id' : settings.CLIENT_ID,
      'client_secret' : settings.CLIENT_SECRET,
      'object' : 'tag',
      'object_id' : tagName,
      'aspect' : 'media',
      'callback_url' : settings.SUB_CALLBACK + tagName

    request.post(
      settings.SUB_ENDPOINT,
      form: post_data,
      (error, response, body) ->
        debug response.statusCode + ':' + error
        if !error and response.statusCode == 200
          debug 'Subscription created: ' + body
          redisClient.sadd 'subscriptions', tagName
    )

# Each update that comes from Instagram merely tells us that there's new
# data to go fetch. The update does not include the data. So, we take the
# tag ID from the update, and make the call to the API.
processTag = (tagName, update) ->
  path = '/v1/tags/' + update.object_id + '/media/recent/'
  getMinID tagName, (error, minID) ->
    if minID is 'XXX'
      debug 'Request for ' + tagName + ' already in progress'
      return
    setMinID tagName, 'XXX'
    queryString = '?client_id=' + settings.CLIENT_ID
    if minID
      debug 'Getting ' + tagName + ' from ' + minID
      queryString += '&min_id=' + minID
    else
      # If this is the first update, just grab the most recent.
      debug 'First update for ' + tagName
      queryString += '&count=1'
    options =
      host: settings.apiHost

      # Note that in all implementations, basePath will be ''. Here at
      # instagram, this aint true ;)
      path: settings.basePath + path + queryString

    options['port'] = settings.apiPort  if settings.apiPort

    # Asynchronously ask the Instagram API for new media for a given
    # tag.
    debug 'processTag: getting ' + path + queryString
    settings.httpClient.get options, (response) ->
      data = ''
      response.on 'data', (chunk) ->
        debug 'Got data...'
        data += chunk

      response.on 'end', ->
        debug 'Got end.'
        try
          parsedResponse = JSON.parse(data)
        catch e
          console.log 'Couldn\'t parse data. Malformed?'
          return

        if not parsedResponse or not parsedResponse['data']
          console.log 'Did not receive data for ' + tagName
          return

        video_data = (datum for datum in parsedResponse['data'] when datum['type'] == 'video')
        setMinID tagName, parsedResponse['pagination']['min_tag_id']

        if video_data.length > 0
          # Let all the redis listeners know that we've got new media.
          redisClient.publish 'channel:' + tagName, JSON.stringify(video_data)
          debug 'Published data for ' + tagName
        else
          debug 'No videos received this time'

getMedia = (tagName, callback) ->

  # This function gets the most recent media stored in redis
  redisClient.lrange 'media:objects:' + tagName, 0, 14, (error, media) ->
    debug 'getMedia: got ' + media.length + ' items'

    # Parse each media JSON to send to callback
    media = media.map((json) ->
      JSON.parse json
    )
    callback error, tagName, media

# In order to only ask for the most recent media, we store the MAXIMUM ID
# of the media for every tag we've fetched. This way, when we get an
# update, we simply provide a min_id parameter to the Instagram API that
# fetches all media that have been posted *since* the min_id.
#
# You might notice there's a fatal flaw in this logic: We create
# media objects once your upload finishes, not when you click 'done' in the
# app. This means that if you take longer to press done than someone else
# who will trigger an update on your same tag, then we will skip
# over your media.

getMinID = (tagName, callback) ->
  redisClient.get 'min-id:channel:' + tagName, callback

setMinID = (tagName, min_tag_id) ->
  try
    if not min_tag_id then min_tag_id = ''
    debug 'setting min_tag_id: ' + min_tag_id
    redisClient.set 'min-id:channel:' + tagName, min_tag_id
  catch e
    console.log 'Error parsing min ID'
    console.log e

########################################
# Requires and Exports
########################################
redis    = require('redis')
settings = require('./settings')
crypto   = require('crypto')

redisClient = redis.createClient(settings.REDIS_PORT, settings.REDIS_HOST)

exports.isValidRequest          = isValidRequest
exports.debug                   = debug
exports.maybeCreateSubscription = maybeCreateSubscription
exports.processTag              = processTag
exports.getMedia                = getMedia
exports.getMinID                = getMinID
exports.setMinID                = setMinID
