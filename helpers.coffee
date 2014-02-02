settings = require './settings'
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

maybeCreateSubscription = (tagName, instagram_access_token) ->
  if instagram_access_token
    redisClient.sadd 'tokens:' + tagName, instagram_access_token
  subscription_exists = false
  redisClient.sismember ['subscriptions', tagName], (err, reply) ->
    subscription_exists = reply
    if subscription_exists
      debug 'subscription for ' + tagName + ' already exists'
      return

    settings.inst.tags.subscribe(
      object_id: tagName
      access_token: instagram_access_token
      callback_url: settings.SUB_CALLBACK + tagName
      complete: (data, pagination) ->
        redisClient.sadd 'subscriptions', tagName
      error: (errorMessage, errorObject, caller) ->
        debug errorMessage
    )

backfillTag = (tagName, num, maxID, access_token) ->
  redisClient.llen 'media:objects:' + tagName, (error, tagCount) ->

    debug 'TAG COUNT: ' + tagCount
    debug 'MAX ID: ' + maxID
    return if tagCount >= num

    settings.inst.tags.recent(
      name : tagName
      max_id : maxID
      access_token : access_token
      complete : (data, pagination) ->

        videos = (media for media in data when media['type'] == 'video')

        if videos.length > 0
          redisClient.publish 'channel:' + tagName, JSON.stringify(videos)

        newTagCount = tagCount + videos.length
        if newTagCount < num && typeof maxID != 'undefined'
          backfillTag(tagName, num, pagination['next_max_id'], access_token)

      error : (errorMessage, errorObject, caller) ->
        debug errorMessage
        setMaxID tagName, ''
    )

# Each update that comes from settings.inst merely tells us that there's new
# data to go fetch. The update does not include the data. So, we take the
# tag ID from the update, and make the call to the API.
processTag = (tagName) ->
  getMinID tagName, (error, minID) ->
    getRandAccessToken tagName, (error, access_token) ->
      if minID == "XXX"
        debug 'Request for ' + tagName + ' already in progress'
        return

      setMinID tagName, 'XXX'

      settings.inst.tags.recent(
        name : tagName
        min_id : minID
        access_token : access_token
        complete : (data, pagination) ->
          setMinID tagName, pagination['min_tag_id']
          recentVideos = (media for media in data when media['type'] == 'video')
          if recentVideos.length > 0
            redisClient.publish 'channel:' + tagName, JSON.stringify(recentVideos)
        error : (errorMessage, errorObject, caller) ->
          setMinID tagName, ''
          debug errorMessage
      )

getMedia = (tagName, callback) ->
  # This function gets the most recent media stored in redis
  redisClient.lrange 'media:objects:' + tagName, 0, 14, (error, media) ->
    debug 'getMedia: got ' + media.length + ' items'

    # if there are no existing videos, let's backfill a dozen to start playing
    if media.length == 0
      getRandAccessToken tagName, (error, access_token) ->
        debug 'Backfilling tag: ' + tagName
        backfillTag tagName, 15, '', access_token

    # Parse each media JSON to send to callback
    media = media.map((json) ->
      JSON.parse json
    )
    callback error, tagName, media

# In order to only ask for the most recent media, we store the MAXIMUM ID
# of the media for every tag we've fetched. This way, when we get an
# update, we simply provide a min_id parameter to the settings.inst API that
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

getRandAccessToken = (tagName, callback) ->
  redisClient.srandmember 'tokens:' + tagName, callback

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
