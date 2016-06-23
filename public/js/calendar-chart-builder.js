var CalendarChartBuilder = (function() {
  var optionsBuild;
  var buildChart = function(options) {
    $('#calendar-container').highcharts({
        chart: {
            type: 'column'
        },
        title: {
            text: 'World\'s largest cities per 2014'
        },
        subtitle: {
            text: 'Source: <a href="http://en.wikipedia.org/wiki/List_of_cities_proper_by_population">Wikipedia</a>'
        },
        xAxis: {
            type: 'category',
            labels: {
                rotation: -45,
                style: {
                    fontSize: '13px',
                    fontFamily: 'Verdana, sans-serif'
                }
            }
        },
        yAxis: {
            min: 0,
            title: {
                text: 'Population (millions)'
            }
        },
        legend: {
            enabled: false
        },
        tooltip: {
            pointFormat: 'Population in 2008: <b>{point.y:.1f} millions</b>'
        },
        series: [{
            name: 'Population',
            data: options.cards,
            dataLabels: {
                enabled: true,
                rotation: -90,
                color: '#FFFFFF',
                align: 'right',
                format: '{point.y:.1f}', // one decimal
                y: 10, // 10 pixels down from the top
                style: {
                    fontSize: '13px',
                    fontFamily: 'Verdana, sans-serif'
                }
            }
        }]
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
    build: load
  }
}());
