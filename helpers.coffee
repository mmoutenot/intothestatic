crypto = require 'crypto'
request = require 'request'
extend = require 'node.extend'

# models
Video = require './models/video'
ObjectId = require('mongoose').Types.ObjectId

settings = require './settings'

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
  debug 'in maybeCreateSubscription, access_token: ' + instagram_access_token
  if instagram_access_token
    redisClient.sadd 'tokens:' + tagName, instagram_access_token
  subscription_exists = false
  redisClient.sismember ['subscriptions', tagName], (err, reply) ->
    subscription_exists = reply
    if subscription_exists
      debug 'subscription for ' + tagName + ' already exists'
      return

    params =
      object_id: tagName
      callback_url: settings.SUB_CALLBACK + tagName
      complete: (data, pagination) ->
        redisClient.sadd 'subscriptions', tagName
      error: (errorMessage, errorObject, caller) ->
        debug 'maybeCreateSubscription: ' + errorMessage

    params = extend({}, params, access_token: instagram_access_token) if instagram_access_token
    settings.inst.tags.subscribe params

backfillTag = (tagName, num, maxInstagramId, instagram_access_token) ->
  redisClient.llen 'media:objects:' + tagName, (error, tagCount) ->

    debug 'TAG COUNT: ' + tagCount
    debug 'MAX Id: ' + maxInstagramId
    return if tagCount >= num

    params =
      name : tagName
      max_id : maxInstagramId
      complete : (data, pagination) ->
        videos = (saveVideo media for media in data when media['type'] == 'video')

        newTagCount = tagCount + videos.length
        if newTagCount < num && typeof maxInstagramId != 'undefined'
          backfillTag(tagName, newTagCount, pagination['next_max_id'], instagram_access_token)

      error : (errorMessage, errorObject, caller) ->
        debug 'error backfilling tag: ' + errorMessage

    params = extend({}, params, access_token: instagram_access_token) if instagram_access_token
    settings.inst.tags.recent params

# Each update that comes from settings.inst merely tells us that there's new
# data to go fetch. The update does not include the data. So, we take the
# tag Id from the update, and make the call to the API.
processTag = (tagName) ->
  debug 'Processing tag: ' + tagName
  getMinInstagramId tagName, (error, minInstagramId) ->
    getRandAccessToken tagName, (error, instagram_access_token) ->
      if minInstagramId == "XXX"
        debug 'Request for ' + tagName + ' already in progress'
        return

      setMinInstagramId tagName, 'XXX'

      debug 'ACCESS_TOKEN: ' + instagram_access_token
      params =
        name : tagName
        min_id : minInstagramId
        complete : (data, pagination) ->
          setMinInstagramId tagName, pagination['min_tag_id']
          videos = (saveVideo(media) for media in data when media['type'] == 'video')
        error : (errorMessage, errorObject, caller) ->
          setMinInstagramId tagName, ''
          debug 'processTag: ' + errorMessage

      params = extend({}, params, access_token: instagram_access_token) if instagram_access_token
      settings.inst.tags.recent params

getVideo = (id, callback) ->
  debug 'finding video with _id: ' + id
  Video.findOne(_id: new ObjectId(id)).exec (err, video) ->
    if err
      debug 'Error getting video: ' + err
    else
      debug 'found video: ' + video
      callback err, video

getVideos = (tagName, minId, callback) ->
  # get all videos for a tag created since the passed in minId
  if minId
    debug 'getting videos since: ' + minId
    query = Video.find(
      tags: tagName
      _id: { $gt: minId }
    ).sort('+received_at').limit(100)
  else
    debug 'getting recent videos'
    query = Video.find(tags: tagName).sort('+received_at').limit(20)

  query.exec (err, videos) ->
    debug 'Error in getVideos: ' + err if err
    # if there are no existing videos, let's backfill a dozen to start playing
    if videos.length == 0
      getRandAccessToken tagName, (error, instagram_access_token) ->
        debug 'Backfilling tag: ' + tagName
        backfillTag tagName, 30, '', instagram_access_token

    callback err, tagName, videos

    # Parse each media JSON to send to callback
    # media = videos.map((json) ->
    #   JSON.parse json
    # )
    # callback error, tagName, videos

saveVideo = (media) ->
  videoData =
    instagram_id: media['id']
    external_created_at: media['created_time']
    user:
      profile_picture: media['user']['profile_picture']
      username: media['user']['username']
      full_name: media['user']['full_name']
    preview: media['images']['standard_resolution']
    sources:
      hi: media['videos']['standard_resolution']['url']
      lo: media['videos']['low_resolution']['url']
    tags: media['tags']

  videoData = extend({}, videoData,
    caption: media['caption']['text']
  ) if media['caption']

  videoData = extend({}, videoData,
    location:
      latitude: media['location']['latitude']
      longitude: media['location']['longitude']
      name: media['location']['name']
  ) if media['location']

  video = new Video videoData
  video.save (err, video) ->
    return console.error 'error saving video: ' + err if err
  return video

# In order to only ask for the most recent media, we store the MAXIMUM Id
# of the media for every tag we've fetched. This way, when we get an
# update, we simply provide a min_id parameter to the settings.inst API that
# fetches all media that have been posted *since* the min_id.
#
# You might notice there's a fatal flaw in this logic: We create
# media objects once your upload finishes, not when you click 'done' in the
# app. This means that if you take longer to press done than someone else
# who will trigger an update on your same tag, then we will skip
# over your media.

getMinInstagramId = (tagName, callback) ->
  redisClient.get 'min-instagram-id:channel:' + tagName, callback

setMinInstagramId = (tagName, min_tag_instagram_id) ->
  try
    if not min_tag_instagram_id then min_tag_instagram_id = ''
    debug 'setting min_tag_instagram_id: ' + min_tag_instagram_id
    redisClient.set 'min-instagram-id:channel:' + tagName, min_tag_instagram_id
  catch e
    console.log 'Error parsing min instagram Id'
    console.log e

getRandAccessToken = (tagName, callback) ->
  redisClient.srandmember 'tokens:' + tagName, callback

getCurrentSubscriptions = (callback) ->
  subscriptions = redisClient.lrange 'subscriptions', 0, -1, (error, media) ->
    callback error, tagName, media


########################################
# Requires and Exports
########################################
redis = require 'redis'
redisClient = redis.createClient(settings.REDIS_PORT, settings.REDIS_HOST)

exports.isValidRequest          = isValidRequest
exports.debug                   = debug
exports.maybeCreateSubscription = maybeCreateSubscription
exports.processTag              = processTag
exports.getVideo                = getVideo
exports.getVideos               = getVideos
exports.getMinInstagramId       = getMinInstagramId
exports.setMinInstagramId       = setMinInstagramId
