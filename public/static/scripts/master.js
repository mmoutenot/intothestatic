(function() {
  var crt, defaultChannel, deleteLastLetter, enqueueRecentVideosForTag, enqueueVideo, enqueueVideosForTag, getVideoByTagAndId, introduction, playNextVideo, processNewMedia, setDefaultChannel;

  enqueueVideo = function(v) {
    var video_data;
    console.log(v);
    video_data = {
      id: v._id,
      instagram_id: v.instagramId,
      preview: v.preview,
      sources: {
        hi: v.sources.hi,
        lo: v.sources.lo
      },
      details: {
        username: v.user.username,
        profile_picture: v.user.profile_picture,
        caption: v.caption,
        location: v.location
      }
    };
    return crt.enqueue(video_data);
  };

  processNewMedia = function(data) {
    console.log("New videos received");
    return $(data).each(function(index, media) {
      return enqueueVideo(media);
    });
  };

  introduction = function() {
    var $input;
    $input = $("input")[0];
    return deleteLastLetter($input);
  };

  deleteLastLetter = function($input) {
    var delay, tag;
    tag = $input.value;
    delay = 1000 * Math.random();
    $input.focus();
    if (tag.length > 0) {
      return setTimeout((function() {
        $input.value = tag.slice(0, tag.length - 1);
        return deleteLastLetter($input);
      }), delay + 200);
    } else {
      return setDefaultChannel($input);
    }
  };

  setDefaultChannel = function($input) {
    var delay, tag;
    tag = $input.value;
    delay = 800 * Math.random();
    $input.focus();
    if (tag.length !== defaultChannel.length) {
      return setTimeout((function() {
        $input.value += defaultChannel[tag.length];
        return setDefaultChannel($input);
      }), delay + 100);
    } else {
      return $("input").trigger("enterKey");
    }
  };

  playNextVideo = function() {
    return crt.playNext();
  };

  getVideoByTagAndId = function(tagName, id) {
    return $.get("/tag/" + tagName + "/video/" + id).done(function(data) {
      return data["videos"].forEach(function(v) {
        return enqueueVideo(v);
      });
    });
  };

  enqueueRecentVideosForTag = function(tagName) {
    return enqueueVideosForTag(tagName, null);
  };

  enqueueVideosForTag = function(tagName, minId) {
    return $.ajax({
      type: 'GET',
      url: '/tag/' + tagName + '?minID=' + minId,
      success: function(data) {
        return data['videos'].forEach(function(v) {
          return enqueueVideo(v);
        });
      },
      error: function(XMLHttpRequest, textStatus, errorThrown) {
        if (XMLHttpRequest.status === 401) {
          return console.log('Attempted to create a subscription while unauthed.');
        }
      }
    });
  };

  crt = new window.CRT();

  defaultChannel = tag;

  $().ready(function() {
    $("input").attr("value", tag);
    $("a#next").click(function() {
      playNextVideo();
      return enqueueVideosForTag(tag, crt.getMinId());
    });
    if (video_id) {
      getVideoByTagAndId(tag, video_id);
    }
    if (tag) {
      enqueueRecentVideosForTag(tag);
    }
    $("input").bind("enterKey", function(e) {
      var newTag, tag;
      newTag = $(this)[0].value;
      crt.clearQueue();
      tag = newTag;
      console.log("tag submitted: " + newTag);
      return enqueueRecentVideosForTag(tag);
    });
    $("input").keyup(function(e) {
      var container, width;
      if (e.keyCode === 13) {
        $(this).trigger("enterKey");
      }
      $("#hidden").html($(this).val());
      width = $("#hidden").width() + 50;
      if (width < 600) {
        container = $(this).parent();
        return $(container).css({
          width: width
        });
      }
    });
    $("#modal-btn, #overlay, #exit-modal").click(function() {
      $("body").toggleClass("overlay-active");
    });
    $("#video_box").append(crt.$el_video);
    return $("#info-box").prepend(crt.$el_details);
  });

}).call(this);
