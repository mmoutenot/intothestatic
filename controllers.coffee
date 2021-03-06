url     = require 'url'
redis   = require 'redis'
settings = require './settings'
helpers = require './helpers'
subscriptions = require './subscriptions'

app = settings.app
app.get '/callbacks/tag/:tagName', (request, response) ->
  helpers.debug 'GET ' + request.url

  # The GET callback for each subscription verification.
  params = url.parse(request.url, true).query
  response.send params['hub.challenge'] or 'No hub.challenge present'

app.post '/callbacks/tag/:tagName', (request, response) ->
  tagName = request.params.tagName
  helpers.debug 'POST /callbacks/tag/' + tagName

  # The POST callback for Instagram to call every time there's an update
  # to one of our subscriptions.

  # First, let's verify the payload's integrity
  unless helpers.isValidRequest(request)
    helpers.debug 'failed request validation'
    response.send 'FAIL'
    return

  # Go through and process each update. Note that every update doesn't
  # include the updated data - we use the data in the update to query
  # the Instagram API to get the data we want.
  updates = request.body
  for index of updates
    update = updates[index]
    helpers.processTag tagName if update['object'] is 'tag'
  helpers.debug 'Processed ' + updates.length + ' updates'
  response.send 'OK'

# Render the home page
app.get '/', (request, response) ->
  helpers.debug 'GET /'

  tagName = 'video'
  external_auth_url = settings.inst.oauth.authorization_url(
    scope: 'basic'
    display: 'touch'
  )
  authed = typeof request.session.instagram_access_token != 'undefined'
  helpers.debug 'instagram access token: ' + request.session.instagram_access_token
  # helpers.getCurrentSubscriptions
  response.render 'tv.jade',
    tag: tagName,
    authed: authed
    external_auth_url: external_auth_url

app.get '/tag/:tagName', (request, response) ->
  tagName = request.params.tagName
  minId = request.query.minId
  instagram_access_token = request.session.instagram_access_token

  if minId
    helpers.debug 'GET /tag/' + tagName + '?minId=' + minId
  else
    helpers.debug 'GET /tag/' + tagName

  helpers.checkIfSubscriptionExists tagName, (err, reply) ->
    subscriptionAlreadyExists = reply
    if !subscriptionAlreadyExists
      return response.send(401) if !instagram_access_token
      helpers.createSubscription(tagName, request.session.instagram_access_token)

    helpers.getVideos tagName, minId, (error, tagName, media) ->
      response.json(
        tag: tagName,
        videos: media
      )

app.get '/channel/:tagName/video/:id', (request, response) ->
  tagName = request.params.tagName
  videoId = request.params.id

  external_auth_url = settings.inst.oauth.authorization_url(
    scope: 'basic'
    display: 'touch'
  )
  authed = typeof request.session.instagram_access_token != 'undefined'

  response.render 'tv.jade',
    tag: tagName
    video_id: videoId
    authed: authed
    external_auth_url: external_auth_url

app.get '/tag/:tagName/video/:id', (request, response) ->
  tagName = request.params.tagName
  videoId = request.params.id

  helpers.getVideo videoId, (error, video) ->
    helpers.debug error if error
    response.json(
      tag:tagName,
      videos:[video]
    )

app.get '/channel/:tagName', (request, response) ->
  tagName = request.params.tagName
  minId = request.query.minId

  helpers.debug 'GET /' + tagName

  external_auth_url = settings.inst.oauth.authorization_url(
    scope: 'basic'
    display: 'touch'
  )

  authed = typeof request.session.instagram_access_token != 'undefined'
  helpers.debug 'instagram access token: ' + request.session.instagram_access_token

  helpers.getVideos tagName, minId, (error, tagName, media) ->
    response.render 'tv.jade',
      tag: tagName
      authed: authed
      external_auth_url: external_auth_url

app.get '/oauth/callback', (request, response) ->
  helpers.debug 'GET /oauth/callback'

  settings.inst.oauth.ask_for_access_token
    request: request
    response: response
    complete: (params, response) ->
      request.session.instagram_access_token = params['access_token']
      request.session.instagram_user = params['user']
      response.redirect '/'
    error: (errorMessage, errorObject, caller, response) ->

