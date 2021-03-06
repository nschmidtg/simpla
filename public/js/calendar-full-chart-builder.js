
var optionsBuild;
var CalendarFullChartBuilder = (function() {
  
  var buildChart = function(options) {
    
    var eventos='[';
    var date;
    console.log(options);
    date=new Date(options[0].due);
    eventos=eventos+'{"title": "'+options[0].name.replace(/\"/g, "'")+'","start": "'+date+'","description": "'+options[0].boardName.replace(/\"/g, "'").split(' |')[0]+'"}';
    for(i=1;i<options.length;i++){
        date=new Date(options[i].due);
        eventos=eventos+',{"title": "'+options[i].name.replace(/\"/g, "'")+'","start": "'+date+'","description": "'+options[i].boardName.replace(/\"/g, "'").split(' |')[0]+'"}';
    }
    eventos=eventos+']';
    optionsBuild=eventos;
    $('#calendar-container').fullCalendar({
    events: jQuery.parseJSON(eventos),
    firstDay: 1,
    lang: 'es',
    eventRender: function(event, element) {
          $(element).popover({html: true, title: "<b>"+event.description+"</b>", content: event.title, trigger: 'hover',container: 'body', placement: 'auto', delay: {"show": 100,"hide": 100 }});             
        }
});
    $('#calendar-container').height('100%');
    $('.analysis-block-md').height('100%');
  }

  var load = function(mun_id, token) {
    var container = $("#calendar-container");
    container.height(container.height() - 10);

    $.ajax({
      url: "/api/v1/calendarFull/" + mun_id,
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
