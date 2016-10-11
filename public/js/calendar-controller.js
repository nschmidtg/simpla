var CalendarController = (function () {
  var initialize = function (mun_id, token) {
    loadCharts(mun_id, token);
  };

  var loadCharts = function (mun_id, token) {
    CalendarFullChartBuilder.build(mun_id, token);
  };

  
  return {
    init: initialize
  }
})();
