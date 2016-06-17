var Ollert = (function() {
  var initDrawer = function() {
    refreshDrawer();
    $("body").toggleClass("has-drawer");
    var hammertime = new Hammer($("body")[0]);
    hammertime.on('swipeleft', function(ev) {
      if ($("#config-drawer").hasClass("open")) {
        $(".drawer-controls a").click();
      }
    });
    hammertime.on('swiperight', function(ev) {
      if (!$("#config-drawer").hasClass("open")) {
        $(".drawer-controls a").click();
      }
    });

    tempNotifyUsersAboutDrawer();
  };

  var tempNotifyUsersAboutDrawer = function () {
    if (window['localStorage'] && window['localStorage'].getItem('hasAcknowledgedDrawer') != "true") {
      setTimeout(function() {
        $(".drawer-controls a").addClass("shake");
      }, 2500);
    }

    $(".drawer-controls a").on("click", function() {
      window['localStorage'].setItem('hasAcknowledgedDrawer', true);
    });
  };

  var refreshDrawer = function () {
    loadBoards();
  };

  var loadBoards = function() {
    resetBoards("Loading boards, please wait...");
    $.ajax({
      url: "/boards",
      method: "get",
      headers: {
        Accept: 'application/json'
      },
      dataType: "json",
      success: loadBoardsCallback,
      error: function(request, status, error) {
        resetBoards(request.status === 400 ? 'No boards' : 'Error. Try reloading!');
      }
    });
    
  };

  var resetBoards = function(text) {
    if (text) {
      $("#config-drawer-board-list").append($("<span>" + text + "</span>"));
    } else {
      $("#config-drawer-board-list").empty();
    }
  };

  var newProject = function(last_board_id,orgName){
    window.location = "/new_board?org_id=nil&last_board_id="+last_board_id+"&orgName="+orgName;
  };
  var newProjectOrg = function(org_id,orgName){
    window.location = "/new_board?last_board_id=nil&org_id="+org_id+"&orgName="+orgName;
  };

  var loadOrganizationsCallback = function(data){
    var appender="";
    var orgData = data['data'];
    var orgName;
    for (i = 0; i < orgData.length; i++) {
      orgName = orgData[i]['displayName'];
      appender=appender+"<li role=\"presentation\"><b>" + orgName + "</b><ul></ul><button onclick=\"Ollert.newProjectOrg('"+orgData[i]['id']+"','"+orgName+"')\">Nuevo Proyecto</button></li>"
    }
    $("#config-drawer-board-list").append(appender);
  };

  var loadBoardsCallback = function(data) {
    resetBoards();
    var boardData = data['data'], boardItem, board, organization, boards;
    for (var orgName in boardData) {
      organization = boardData[orgName];
      organizationBoards = $("<ul/>");
      for (var j = 0; j < organization.length; ++j) {
        board = organization[j];
        item = $("<li/>", {
          role: "presentation"
        });
        item.append($("<a href=\"/boards/" + board.id + "\">" + board.name + "</a>"));
        organizationBoards.append(item);
      }
      var section = $("<li role=\"presentation\"><b>" + orgName + "</b></li>").append(organizationBoards)
      var botonAgregar = $("<button onclick=\"Ollert.newProject('"+board.id+"','"+orgName+"')\">Nuevo Proyecto</button>");
      var section2 = section.append(botonAgregar);
      $("#config-drawer-board-list").append(section2);
      

    }
    $.ajax({
      url: "/organizations",
      method: "get",
      headers: {
        Accept: 'application/json'
      },
      dataType: "json",
      success: loadOrganizationsCallback,
      error: function(request, status, error) {
        resetBoards(request.status === 400 ? 'No organizations' : 'Error. Try reloading!');
      }
    });
  };

  var loadAvatar = function(gravatar_hash) {
    $(".settings-link > img").attr("src", "http://www.gravatar.com/avatar/" + gravatar_hash + "?s=40");
  };

  return {
    initDrawer: initDrawer,
    refreshDrawer: refreshDrawer,
    loadAvatar: loadAvatar,
    newProject: newProject,
    newProjectOrg: newProjectOrg
  };
})();
