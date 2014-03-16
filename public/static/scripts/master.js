var crt = new CRT();

function enqueueVideo(v){
  console.log(v);
  video_data = {
    'id' : v._id,
    'instagram_id' : v.instagramId,
    'preview' : v.preview,
    'sources' : {
      'hi' : v.sources.hi,
      'lo' : v.sources.lo
    },
    'details' : {
      'username' : v.user.username,
      'profile_picture' : v.user.profile_picture,
      'caption' : v.caption,
      'location' : v.location
    }
  }
  crt.enqueue(video_data);
}

function processNewMedia(data){
  console.log("New videos received");
  $(data).each(function(index, media){
    enqueueVideo(media);
  });
}

function introduction() {
  var $input = $('input')[0];
  deleteLastLetter($input);
}

var defaultChannel = tag;
function deleteLastLetter($input) {
  var tag = $input.value;
  var delay = 1000 * Math.random();
  $input.focus();
  if (tag.length > 0){
    setTimeout(function(){
      $input.value = tag.slice(0, tag.length-1);
      deleteLastLetter($input);
    }, delay + 200);
  } else {
    setDefaultChannel($input);
  }
}

function setDefaultChannel($input) {
  var tag = $input.value;
  var delay = 800 * Math.random();
  $input.focus();
  if (tag.length != defaultChannel.length){
    setTimeout(function(){
      $input.value+=defaultChannel[tag.length];
      setDefaultChannel($input);
    }, delay + 100);
  } else {
    $('input').trigger("enterKey");
  }
}

function playNextVideo(){
  crt.playNext();
}

function getVideoByTagAndId(tagName, id){
    $.get('/tag/' + tagName + '/video/' + id)
      .done(function(data) {
          data['videos'].forEach(function(v){
            enqueueVideo(v);
          });
      });
}

function enqueueRecentVideosForTag(tagName){
  enqueueVideosForTag(tagName, null);
}

function enqueueVideosForTag(tagName, minId){
    $.get('/tag/' + tagName,
        { minId: minId }
      ).done(function(data) {
      data['videos'].forEach(function(v){
        enqueueVideo(v);
      });
    });
}

$().ready(function() {
  // setTimeout(introduction(), 2500);
  $('input').attr('value', tag);

  $('a#next').click(playNextVideo);

  // we want to make sure we enqueue the video first before we enqueue channel's videos
  if (video_id) {
    getVideoByTagAndId(tag, video_id);
  }

  if (tag){
    // enqueueRecentVideosForTag(tag);
  }

  $('input').bind("enterKey",function(e){
    var newTag = $(this)[0].value;
    crt.clearQueue();
    tag = newTag;
    console.log('tag submitted: ' + newTag);

    // get backlog of videos to start playing
    enqueueRecentVideosForTag(tag);
  });

  $('input').keyup(function(e){
    $('#hidden').html($(this).val());
    var width = $('#hidden').width() + 50;
    
    // change width of parent div based on length of input
    if (width < 600) {
      var container = $(this).parent();
      $(container).css({
        width: width
      });
    }

    if(e.keyCode == 13) {
      $(this).trigger("enterKey");
    }
  });

  $('#video_box').append(crt.$el_video);
  $('#info-box').prepend(crt.$el_details);

  $('#modal-btn, #overlay, #exit-modal').click(function() {
    $('body').toggleClass('overlay-active');
  });


});

