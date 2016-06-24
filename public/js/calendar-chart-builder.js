var CalendarChartBuilder = (function() {
  var optionsBuild;
  var buildChart = function(options) {
    // $('#calendar-container').highcharts({
    //     chart: {
    //         type: 'column'
    //     },
    //     title: {
    //         text: 'World\'s largest cities per 2014'
    //     },
    //     subtitle: {
    //         text: 'Source: <a href="http://en.wikipedia.org/wiki/List_of_cities_proper_by_population">Wikipedia</a>'
    //     },
    //     xAxis: {
    //         type: 'category',
    //         labels: {
    //             rotation: -45,
    //             style: {
    //                 fontSize: '13px',
    //                 fontFamily: 'Verdana, sans-serif'
    //             }
    //         }
    //     },
    //     yAxis: {
    //         min: 0,
    //         title: {
    //             text: 'Population (millions)'
    //         }
    //     },
    //     legend: {
    //         enabled: false
    //     },
    //     tooltip: {
    //         pointFormat: 'Population in 2008: <b>{point.y:.1f} millions</b>'
    //     },
    //     series: [{
    //         name: 'Population',
    //         data: options.cards,
    //         dataLabels: {
    //             enabled: true,
    //             rotation: -90,
    //             color: '#FFFFFF',
    //             align: 'right',
    //             format: '{point.y:.1f}', // one decimal
    //             y: 10, // 10 pixels down from the top
    //             style: {
    //                 fontSize: '13px',
    //                 fontFamily: 'Verdana, sans-serif'
    //             }
    //         }
    //     }]
    // });

// events: [
//         {
//             title  : options.cards[0].name,
//             start  : '2016-06-06'
//         },
//         {
//             title  : 'event2',
//             start  : '2010-01-05',
//             end    : '2010-01-07'
//         },
//         {
//             title  : 'event3',
//             start  : '2010-01-09T12:30:00',
//             allDay : false // will make the time show
//         }
//     ]




    var eventos='[';
    eventos=eventos+'{"title": "'+options.cards[0].name+'","start": "'+options.cards[0].due+'"}';
    for(i=1;i<options.cards.length;i++){
        eventos=eventos+',{"title": "'+options.cards[i].name+'","start": "'+options.cards[i].due+'"}';
    }
    eventos=eventos+']';
    optionsBuild=eventos;
    $('#calendar-container').fullCalendar({
    events: jQuery.parseJSON(eventos)
});
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
