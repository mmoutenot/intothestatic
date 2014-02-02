
var CRT = function(videos) {
  this.$el_video = $('<video width="640px" height="640px"></video>');
  this.el_video = this.$el_video[0];

  this.$el_details = $('<div class="details"></div>');
  this.el_details = this.$el_details[0];

  this.current = null;
  this.videos = videos || {};
  this.queue = [];
  this.$el_video.on('ended', _.bind(this.onEnded, this));
  this.$el_video.on('loadedmetadata', _.bind(this.onLoadedMetadata, this));
  this.$el_video.on('canplay', _.bind(this.el_video.play, this.el_video));
  this.$window = $(window);
  this.$window.on('resize', _.bind(this.resize, this));
}

function createSourceElement(source) {
  return '<source type="video/mp4" src="' + source + '"></source>';
}

CRT.prototype.updateDetails = function(){
  this.$el_details.html('');
  this.$el_details.append('<img class="profile_picture" src=' + this.current.details.profile_picture + '>');
  this.$el_details.append('<p class="username"><a target="_blank" href="http://instagram.com/'
      + this.current.details.username + '">' + this.current.details.username + '</p>');
  this.$el_details.append('<p class="post">'+this.current.details.post.text+'</p>');
  console.log(this.current.details.location);
}

CRT.prototype.displayNextPreview = function(){
  if (this.queueDepth()){
    var next = this.queue[0];
    console.log('coming up next: ' + next.id);
  }
}

CRT.prototype.play = function(video_data) {
  var source = video_data.sources.hi;
  if (!source) throw new Error('no video ' + source);

  this.$el_video.find('source').remove();
  this.$el_video.append(createSourceElement(source));
  this.el_video.loop = null;
  this.el_video.play();
  this.el_video.load();
  this.current = video_data;
  console.log('loading/playing ' + source);

  this.updateDetails(video_data);
  this.displayNextPreview();

  return this;
}

/*
 * enqueue data in format:
 * {
 *   id : 1,
 *   preview : "",
 *   sources : {
 *     hi : "",
 *     lo : ""
 *   },
 *   details : {
 *     username : "",
 *     post : {},
 *     location : "",
 *     profile_picture : ""
 *   }
 * }
 */
CRT.prototype.enqueue = function(video_data) {
  if (!this.current) return this.play(video_data);

  this.queue.push(video_data);
  if (this.queueDepth() == 1) this.displayNextPreview();
  return this;
}

CRT.prototype.clearQueue = function() {
  this.queue = [];
}

CRT.prototype.queueDepth = function() {
  return this.queue.length;
}

CRT.prototype.playNext = function() {
  var next = this.queue.shift();
  if (next) this.play(next);
  else this.current = null;
}

CRT.prototype.onEnded = function(e) {
  this.playNext();
}

CRT.prototype.fullscreen = function(val) {
  if (typeof val == 'undefined') return this.isFullscreen;
  this.isFullscreen = val;
  this.resize();
  return this;
}

CRT.prototype.resize = function() {
  if (!this.isFullscreen) {
    return this.$el_video.css({
      height: '',
      width: '',
      top: '',
      left: '',
      position: ''
    });
  }

  var vWidth = this.el_video.videoWidth;
  var vHeight = this.el_video.videoHeight;

  if (!vWidth || !vHeight) return console.log('vWidth/vHeight unknown');

  var vRatio = vWidth / vHeight
  , wWidth = this.$window.width()
  , wHeight = this.$window.height()
  , wRatio = wWidth / wHeight
  , width
  , height;

  if (wRatio < vRatio ) {
    width = wWidth;
    height = width / vRatio;
  } else {
    height = wHeight;
    width = height * vRatio;
  }

  this.$el_video.css({
    width: width,
    height: height,
    top: 0,
    left: 0,
    position: 'fixed'
  });
}

CRT.prototype.onLoadedMetadata = function() {
  this.resize();
}
