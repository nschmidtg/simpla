var CalendarChartBuilder = (function() {
  var optionsBuild;
  var buildChart = function(options) {
    
    var eventos='[';
    var date;
    date=new Date(options.cards[0].due);
    eventos=eventos+'{"title": "'+options.cards[0].name.replace(/\"/g, "'")+'","start": "'+date+'"}';
    for(i=1;i<options.cards.length;i++){
        date=new Date(options.cards[i].due);
        eventos=eventos+',{"title": "'+options.cards[i].name.replace(/\"/g, "'")+'","start": "'+date+'"}';
    }
    eventos=eventos+']';
    optionsBuild=eventos;
    $('#calendar-container').fullCalendar({
    events: jQuery.parseJSON(eventos),
    firstDay: 1,
    lang: 'es',
    eventRender: function(event, element) {
          $(element).popover({title: event.title, trigger: 'hover',container: 'body', placement: 'auto', delay: {"show": 100,"hide": 100 }});             
        }
});
    $('#calendar-container').height('100%');
    $('.analysis-block-md').height('100%');
  }

  var load = function(boardId, token) {
    var container = $("#calendar-container");
    container.height(container.height() - 10);

    $.ajax({
      url: "/api/v1/calendar/" + boardId,
      data: {
        token: token
      },
      success: function(data) {
        $('#calendar-spinner').hide();
        optionsBuild=data;
        buildChart(jQuery.parseJSON(data));
      },
      error: function(xhr) {
        $("#calendar-spinner").hide();
        container.text(xhr.responseText);
      }
    });
  }

  return {
    build: load,
    optionsBuild: optionsBuild
  }
}());
