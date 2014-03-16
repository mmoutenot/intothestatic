createSourceElement = (source) ->
  "<source type=\"video/mp4\" src=\"" + source + "\"></source>"

class window.CRT
  constructor: (videos) ->
    @$el_video = $("<video width=\"640px\" height=\"640px\"></video>")
    @el_video = @$el_video[0]
    @$el_details = $("<div id=\"user-info\"></div>")
    @el_details = @$el_details[0]
    @current = null
    @lastPlayed = null
    @videos = videos or {}
    @queue = []
    @$el_video.on "ended", _.bind(@onEnded, this)
    @$el_video.on "loadedmetadata", _.bind(@onLoadedMetadata, this)
    @$el_video.on "canplay", _.bind(@el_video.play, @el_video)
    @$window = $(window)
    @$window.on "resize", _.bind(@resize, this)

  updateDetails: ->
    @$el_details.html ""
    @$el_details.append "<img class=\"profile-picture\" src=" + @current.details.profile_picture + ">"
    @$el_details.append "<h4 class=\"username\"><a target=\"_blank\" href=\"http://instagram.com/" + @current.details.username + "\">" + @current.details.username + "</p>"
    @$el_details.append "<p class=\"caption\">" + @current.details.caption + "</p>"  if @current.details.caption

  displayNextPreview: ->
    if @queueDepth()
      next = @queue[0]
      console.log "coming up next: " + next.id

  play: (video_data) ->
    source = video_data.sources.lo
    throw new Error("no video " + source)  unless source
    @$el_video.find("source").remove()
    @$el_video.append createSourceElement(source)
    @el_video.loop = null
    @el_video.play()
    @el_video.load()
    @current = video_data
    console.log "loading/playing " + source
    @updateDetails video_data
    @displayNextPreview()
    this

  #
  # * enqueue data in format:
  # * {
  # *   id : 1,
  # *   preview : "",
  # *   sources : {
  # *     hi : "",
  # *     lo : ""
  # *   },
  # *   details : {
  # *     username : "",
  # *     post : {},
  # *     location : "",
  # *     profile_picture : ""
  # *   }
  # * }
  #
  enqueue: (video_data) ->
    return @play(video_data) unless @current
    @queue.push video_data
    @displayNextPreview()  if @queueDepth() is 1
    this

  clearQueue: ->
    @queue = []

  queueDepth: ->
    @queue.length

  getMinId: ->
    if @queueDepth() > 0
      @queue[@queue.length - 1].id
    else if @lastPlayed
      @lastPlayed.id
    else
      null

  playNext: ->
    @lastPlayed = @current  if @current
    next = @queue.shift()
    if next
      @play next
      $("#next").html "next"
    else
      @current = null
      $("#next").html "ref"

  onEnded: (e) ->
    @playNext()

  fullscreen: (val) ->
    return @isFullscreen  if typeof val is "undefined"
    @isFullscreen = val
    @resize()
    this

  resize: ->
    unless @isFullscreen
      return @$el_video.css(
        height: ""
        width: ""
        top: ""
        left: ""
        position: ""
      )
    vWidth = @el_video.videoWidth
    vHeight = @el_video.videoHeight
    return console.log("vWidth/vHeight unknown")  if not vWidth or not vHeight
    vRatio = vWidth / vHeight
    wWidth = @$window.width()
    wHeight = @$window.height()
    wRatio = wWidth / wHeight
    width = undefined
    height = undefined
    if wRatio < vRatio
      width = wWidth
      height = width / vRatio
    else
      height = wHeight
      width = height * vRatio
    @$el_video.css
      width: width
      height: height
      top: 0
      left: 0
      position: "fixed"

  onLoadedMetadata: ->
    @resize()

