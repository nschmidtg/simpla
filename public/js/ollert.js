var Ollert = (function() {

  var teams = [];
  var info = [];
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
  var editProject = function(last_board_id,orgName,board_name){
    window.location = "/new_board?org_id=nil&last_board_id="+last_board_id+"&orgName="+orgName+"&board_name="+board_name+"&edit=true";
  };
  var newProject = function(last_board_id,orgName){
    window.location = "/new_board?org_id=nil&last_board_id="+last_board_id+"&orgName="+orgName+"&edit=false";
  };
  var newProjectOrg = function(org_id,orgName){
    window.location = "/new_board?last_board_id=nil&org_id="+org_id+"&orgName="+orgName;
  };

  var loadBoardsCallback = function(data) {
    resetBoards();
    var boardData = data['data'], boardItem, board, organization, boards;
    
    

    var count = 0;
    var entroAlta = false;
    var entroBaja = false;
    var entroNo = false;
    var entro=false;
    
      for (var orgName in boardData) {
        if((orgName.includes("- Alta Prioridad") ) || (orgName.includes("- Baja Prioridad") ) || (orgName.includes("- No Priorizados") )){
          if(orgName.includes("- Alta Prioridad")){
            entroAlta=true;
          }
          else if(orgName.includes("- Baja Prioridad")){
            entroBaja=true;
          }
          else if(orgName.includes("- No Priorizados")){
            entroNo=true;
          }
          entro=true;
          organization = boardData[orgName];
          organizationBoards = $("<ul/>");
          
          teams.push(orgName);
        
          for (var j = 0; j < organization.length; ++j) {
            board = organization[j];
            item = $("<li/>", {
              role: "presentation1"
            });
            item.append($("<a style='display: inline-block;margin-left: -30px !important;overflow-wrap: break-word;    max-width: 250px;' href=\"/boards/" + board.id + "\">" + board.name + "</a><a onclick=\"Ollert.editProject('"+board.id+"','"+orgName+"','"+board.name+"')\" style='display: inline-block;float: right;padding: 5px !important;'><span class='glyphicon glyphicon-pencil' aria-hidden='true' style=''></span></a>"));
            organizationBoards.append(item);
          }
          var section = $("<li class='org' id=\""+orgName+"\" role=\"presentation2\"><b>" + orgName + "</b></li>").append(organizationBoards)
          var botonAgregar = $("<button onclick=\"Ollert.newProject('"+board.id+"','"+orgName+"')\">Nuevo Proyecto</button>");
          var section2 = section.append(botonAgregar);
          $("#config-drawer-board-list").append(section2);
        }
        

      }
      if(entro==true){
        count=count+1;
        entro=false;
      }
    
    teams.sort(function(a, b){
      if(a.toString() < b.toString()) return -1;
      if(a.toString() > b.toString()) return 1;
      return 0;
    });
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

  var loadOrganizationsCallback = function(data){
    var appender="";
    var orgData = data['data'];
    var orgName;
    for (i = 0; i < orgData.length; i++) {
      orgName = orgData[i]['displayName'];
      var esta=false;
      for(t = 0; t< teams.length; t++){
        if(teams[t]==orgName){
          esta=true;
          break;
        }
      }
      if(esta==false){
        if(orgName.includes("- Alta Prioridad") || orgName.includes("- Baja Prioridad") || orgName.includes("- No Priorizados")){
          appender=appender+"<li class='org' role=\"presentation\"><b>" + orgName + "</b><ul style='padding-left: 0px;'></ul><button onclick=\"Ollert.newProjectOrg('"+orgData[i]['id']+"','"+orgName+"')\">Nuevo Proyecto</button></li>"
        
        }
      }  
    }
    $("#config-drawer-board-list").append(appender);
    var nodos=$(".org");
    for(var t=0;t<nodos.length;t++){
      for(var i=0;i<nodos.length;i++){
        if(i!=1 && nodos[i].id.includes("- Baja Prioridad")){
          $("#config-drawer-board-list").append(nodos[i]);
        }
        if(i!=2 && nodos[i].id.includes("- No Priorizados")){
          $("#config-drawer-board-list").append(nodos[i]);
        }
      }
    }
  };

  

  var loadAvatar = function(gravatar_hash) {
    $(".settings-link > img").attr("src", "http://www.gravatar.com/avatar/" + gravatar_hash + "?s=40");
  };

  return {
    initDrawer: initDrawer,
    refreshDrawer: refreshDrawer,
    loadAvatar: loadAvatar,
    newProject: newProject,
    newProjectOrg: newProjectOrg,
    editProject: editProject,
    teams: teams,
    info: info
  };
})();
