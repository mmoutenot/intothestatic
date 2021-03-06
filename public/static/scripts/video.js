// Generated by CoffeeScript 1.7.1
(function() {
  var createSourceElement;

  createSourceElement = function(source) {
    return "<source type=\"video/mp4\" src=\"" + source + "\"></source>";
  };

  window.CRT = (function() {
    function CRT(videos) {
      this.$el_video = $("<video width=\"640px\" height=\"640px\"></video>");
      this.el_video = this.$el_video[0];
      this.$el_details = $("<div id=\"user-info\"></div>");
      this.el_details = this.$el_details[0];
      this.current = null;
      this.lastPlayed = null;
      this.videos = videos || {};
      this.queue = [];
      this.$el_video.on("ended", _.bind(this.onEnded, this));
      this.$el_video.on("loadedmetadata", _.bind(this.onLoadedMetadata, this));
      this.$el_video.on("canplay", _.bind(this.el_video.play, this.el_video));
      this.$window = $(window);
      this.$window.on("resize", _.bind(this.resize, this));
      this.videosAlreadyPlayed = {};
    }

    CRT.prototype.updateDetails = function() {
      this.$el_details.html("");
      this.$el_details.append("<img class=\"profile-picture\" src=" + this.current.details.profile_picture + ">");
      this.$el_details.append("<h4 class=\"username\"><a target=\"_blank\" href=\"http://instagram.com/" + this.current.details.username + "\">" + this.current.details.username + "</p>");
      if (this.current.details.caption) {
        return this.$el_details.append("<p class=\"caption\">" + this.current.details.caption + "</p>");
      }
    };

    CRT.prototype.displayNextPreview = function() {
      var next;
      if (this.queueDepth()) {
        next = this.queue[0];
        return console.log("coming up next: " + next.id);
      }
    };

    CRT.prototype.twitterShareLink = function(videoId) {
      var twitterShareUrl;
      twitterShareUrl = "https://twitter.com/share?url=http://intothestatic.com/channel/";
      twitterShareUrl += window.tag;
      twitterShareUrl += "/video/";
      twitterShareUrl += videoId;
      twitterShareUrl += "&text=Found%20this%20video%20on%20the%20%23";
      twitterShareUrl += window.tag;
      return twitterShareUrl += "%20channel%20via%20@intothestatic";
    };

    CRT.prototype.play = function(video_data) {
      var source;
      source = video_data.sources.lo;
      if (!source) {
        throw new Error("no video " + source);
      }
      this.$el_video.find("source").remove();
      this.$el_video.append(createSourceElement(source));
      this.el_video.loop = null;
      this.el_video.play();
      this.el_video.load();
      this.current = video_data;
      console.log("loading/playing " + source);
      $('#twitter-share').attr('href', this.twitterShareLink(video_data.id));
      this.updateDetails(video_data);
      this.videosAlreadyPlayed[video_data.id] = true;
      this.displayNextPreview();
      return this;
    };

    CRT.prototype.enqueue = function(video_data) {
      if (!this.current) {
        return this.play(video_data);
      }
      this.queue.push(video_data);
      if (this.queueDepth() === 1) {
        this.displayNextPreview();
      }
      return this;
    };

    CRT.prototype.clearQueue = function() {
      return this.queue = [];
    };

    CRT.prototype.queueDepth = function() {
      return this.queue.length;
    };

    CRT.prototype.getMinId = function() {
      if (this.queueDepth() > 0) {
        return this.queue[this.queue.length - 1].id;
      } else if (this.lastPlayed) {
        return this.lastPlayed.id;
      } else {
        return null;
      }
    };

    CRT.prototype.playNext = function() {
      var next;
      next = this.queue.shift();
      if (next) {
        if (this.videosAlreadyPlayed[next.id]) {
          this.playNext();
        }
        this.play(next);
        this.lastPlayed = next;
        console.log(this.videosAlreadyPlayed);
        return $("#next").html("next");
      } else {
        this.current = null;
        return $("#next").html("<img height=\"50px\" width=\"50px\"src=\"/static/images/refresh-icon.png\">");
      }
    };

    CRT.prototype.onEnded = function(e) {
      return this.playNext();
    };

    CRT.prototype.fullscreen = function(val) {
      if (typeof val === "undefined") {
        return this.isFullscreen;
      }
      this.isFullscreen = val;
      this.resize();
      return this;
    };

    CRT.prototype.resize = function() {
      var height, vHeight, vRatio, vWidth, wHeight, wRatio, wWidth, width;
      if (!this.isFullscreen) {
        return this.$el_video.css({
          height: "",
          width: "",
          top: "",
          left: "",
          position: ""
        });
      }
      vWidth = this.el_video.videoWidth;
      vHeight = this.el_video.videoHeight;
      if (!vWidth || !vHeight) {
        return console.log("vWidth/vHeight unknown");
      }
      vRatio = vWidth / vHeight;
      wWidth = this.$window.width();
      wHeight = this.$window.height();
      wRatio = wWidth / wHeight;
      width = void 0;
      height = void 0;
      if (wRatio < vRatio) {
        width = wWidth;
        height = width / vRatio;
      } else {
        height = wHeight;
        width = height * vRatio;
      }
      return this.$el_video.css({
        width: width,
        height: height,
        top: 0,
        left: 0,
        position: "fixed"
      });
    };

    CRT.prototype.onLoadedMetadata = function() {
      return this.resize();
    };

    return CRT;

  })();

}).call(this);
