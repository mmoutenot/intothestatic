enqueueVideo = (v) ->
  console.log v
  video_data =
    id: v._id
    instagram_id: v.instagramId
    preview: v.preview
    sources:
      hi: v.sources.hi
      lo: v.sources.lo

    details:
      username: v.user.username
      profile_picture: v.user.profile_picture
      caption: v.caption
      location: v.location

  crt.enqueue video_data

processNewMedia = (data) ->
  console.log "New videos received"
  $(data).each (index, media) ->
    enqueueVideo media

introduction = ->
  $input = $("input")[0]
  deleteLastLetter $input

deleteLastLetter = ($input) ->
  tag = $input.value
  delay = 1000 * Math.random()
  $input.focus()
  if tag.length > 0
    setTimeout (->
      $input.value = tag.slice(0, tag.length - 1)
      deleteLastLetter $input
    ), delay + 200
  else
    setDefaultChannel $input

setDefaultChannel = ($input) ->
  tag = $input.value
  delay = 800 * Math.random()
  $input.focus()
  unless tag.length is defaultChannel.length
    setTimeout (->
      $input.value += defaultChannel[tag.length]
      setDefaultChannel $input
    ), delay + 100
  else
    $("input").trigger "enterKey"

playNextVideo = ->
  crt.playNext()

getVideoByTagAndId = (tagName, id) ->
  $.get("/tag/" + tagName + "/video/" + id).done (data) ->
    data["videos"].forEach (v) ->
      enqueueVideo v

enqueueRecentVideosForTag = (tagName) ->
  enqueueVideosForTag tagName, null

enqueueVideosForTag = (tagName, minId) ->
  $.ajax
    type: 'GET'
    url: '/tag/' + tagName + '?minID=' + minId
    success: (data) ->
      data['videos'].forEach (v) ->
        enqueueVideo v
    error: (XMLHttpRequest, textStatus, errorThrown) ->
      if XMLHttpRequest.status == 401
        console.log 'Attempted to create a subscription while unauthed.'

crt = new window.CRT()
defaultChannel = tag

$().ready ->
  # setTimeout(introduction(), 2500);
  $("input").attr "value", tag
  $("a#next").click ->
    playNextVideo()
    enqueueVideosForTag tag, crt.getMinId()

  # we want to make sure we enqueue the video first before we enqueue channel's videos
  getVideoByTagAndId tag, video_id  if video_id
  enqueueRecentVideosForTag tag  if tag
  $("input").bind "enterKey", (e) ->
    newTag = $(this)[0].value
    crt.clearQueue()
    tag = newTag
    console.log "tag submitted: " + newTag

    # get backlog of videos to start playing
    enqueueRecentVideosForTag tag

  $("input").keyup (e) ->
    $(this).trigger "enterKey"  if e.keyCode is 13
    
    # create a hidden div with input text and find width
    $("#hidden").html $(this).val()
    width = $("#hidden").width() + 50

    # set width of input container based on width variable
    if width < 600
      container = $(this).parent()
      $(container).css width: width

  # add modal and overlay on click
  $("#modal-btn, #overlay, #exit-modal").click ->
    $("body").toggleClass "overlay-active"
    return
    
  $("#video_box").append crt.$el_video
  $("#info-box").prepend crt.$el_details