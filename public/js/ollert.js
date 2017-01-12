var Ollert = (function() {

  var teams = [];
  var info = [];
  var esAdmin=false;
  var loadAvatar = function(gravatar_hash) {
    $(".settings-link > img").attr("src", "http://www.gravatar.com/avatar/" + gravatar_hash + "?s=40");
  };

  return {
    loadAvatar: loadAvatar,
    info: info,
    esAdmin: esAdmin
  };
})();
