var SettingsController = function() {
  function initialize() {
    $("#trello-connect").on("click", connectToTrello);
    $("#email-info").popover();
  };


  function connectToTrello() {
    TrelloController.authorize(onSuccessfulConnect);
  };

  var onSuccessfulConnect = function() {
    var ind = new LoadingIndicator($("#trello-connect-status span"));
    ind.show("Saving...");

    $("#trello-connect").disable();
    $.ajax({
      url: "/settings/trello/connect",
      data: {
        token: Trello.token()
      },
      method: "PUT",
      success: function(member) {
        member = jQuery.parseJSON(member);
        ind.success("Currently connected to Trello as <strong>" + member["username"] +
          "</strong>");
        Ollert.loadAvatar(member["gravatar_hash"]);
      },
      error: function(xhr) {
        ind.error(
          xhr.responseText +
          " (" +
          xhr.status +
          ": " +
          xhr.statusText +
          ")"
        );
      },
      complete: function() {
        $("#trello-connect").enable();
      }
    });
  };

  return {
    init: initialize
  };
}();
