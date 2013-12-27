#   Instagram real-time updates demo app.

url           = require 'url'
redis         = require 'redis'
settings      = require './settings'
helpers       = require './helpers'
subscriptions = require './subscriptions'
io            = require 'socket.io'

app = settings.app
app.get '/callbacks/tag/:tagName', (request, response) ->
  # The GET callback for each subscription verification.
  helpers.debug 'GET ' + request.url
  params = url.parse(request.url, true).query
  response.send params['hub.challenge'] or 'No hub.challenge present'

app.post '/callbacks/tag/:tagName', (request, response) ->
  tagName = request.params.tagName
  helpers.debug 'PUT /callbacks/tag/' + tagName

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
    helpers.processTag tagName, update  if update['object'] is 'tag'
  helpers.debug 'Processed ' + updates.length + ' updates'
  response.send 'OK'

# Render the home page
app.get '/', (request, response) ->
  helpers.getMedia (error, media) ->
    response.render 'tv.jade',
      videos: media

# app.listen settings.appPort
