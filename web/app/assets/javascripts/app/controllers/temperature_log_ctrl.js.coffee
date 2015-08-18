window.ChaiBioTech.ngApp.controller 'TemperatureLogCtrl', [
  '$scope'
  '$stateParams'
  ($scope, $stateParams) ->

    $scope.init = ->

      Status.startSync()

      $scope.$watch ->
        Status.getData()
      , (val) ->
        if val
          $scope.isCurrentExperiment = parseInt(val.experimentController?.expriment?.id) is parseInt($stateParams.id)
          if $scope.isCurrentExperiment and $scope.scrollState >= 1
            $scope.autoUpdateTemperatureLogs()
          else
            $scope.stopInterval()

      $scope.resolutionOptions = [
        60
        10 * 60
        20 * 60
        30 * 60
        60 * 60
        60 * 60 * 24
      ]

      $scope.resolution = $scope.resolutionOptions[0]

      $scope.temperatureLogs = []
      $scope.temperatureLogsCache = []
      $scope.calibration = 800
      $scope.scrollState = 0
      $scope.updateInterval = null

      Experiment
      .getTemperatureData($stateParams.id, resolution: 1000)
      .success (data) =>
        if data.length > 0
          $scope.temperatureLogsCache = angular.copy data
          $scope.temperatureLogs = angular.copy data
          $scope.updateScale()
          $scope.resizeTemperatureLogs()
          $scope.updateScrollWidth()
          $scope.updateData()
        else
          $scope.autoUpdateTemperatureLogs()

    $scope.init()

    $scope.updateData = ->
      if $scope.temperatureLogsCache?.length > 0
        left_et_limit = $scope.temperatureLogsCache[$scope.temperatureLogsCache.length-1].temperature_log.elapsed_time - ($scope.resolution*1000)

        maxScroll = 0
        for temp_log in $scope.temperatureLogs
          if temp_log.temperature_log.elapsed_time <= left_et_limit
            ++ maxScroll
          else
            break

        scrollState = Math.round $scope.scrollState * maxScroll
        if $scope.scrollState < 0 then scrollState = 0
        if $scope.scrollState > 1 then scrollState = maxScroll
        left_et = $scope.temperatureLogs[scrollState].temperature_log.elapsed_time

        right_et = left_et + ($scope.resolution*1000)

        data = _.select $scope.temperatureLogs, (temp_log) ->
          et = temp_log.temperature_log.elapsed_time
          et >= left_et and et <= right_et

        $scope.updateChart data

    $scope.updateScale = ->
      scales = _.map $scope.temperatureLogsCache, (temp_log) ->
        temp_log = temp_log.temperature_log
        greatest = Math.max.apply Math, [
          parseFloat temp_log.lid_temp
          parseFloat temp_log.heat_block_zone_1_temp
          parseFloat temp_log.heat_block_zone_2_temp
        ]
        greatest

      max_scale = Math.max.apply Math, scales
      $scope.options.axes.y.max = Math.ceil(max_scale/10)*10

    $scope.updateScrollWidth = ->

      if $scope.temperatureLogsCache.length > 0

        $scope.greatest_elapsed_time = $scope.temperatureLogsCache[$scope.temperatureLogsCache.length - 1].temperature_log.elapsed_time

        $scope.widthPercent = $scope.resolution*1000/$scope.greatest_elapsed_time
        if $scope.widthPercent > 1
          $scope.widthPercent = 1
      else
        $scope.widthPercent = 1

      elem.find('.scrollbar').css width: "#{$scope.widthPercent*100}%"

    $scope.resizeTemperatureLogs = ->
      resolution = $scope.resolution
      if $scope.resolution> $scope.greatest_elapsed_time/1000 then resolution = $scope.greatest_elapsed_time/1000
      chunkSize = Math.round resolution / $scope.calibration
      temperature_logs = angular.copy $scope.temperatureLogsCache
      chunked = _.chunk temperature_logs, chunkSize
      averagedLogs = _.map chunked, (chunk) ->
        i = Math.floor(chunk.length/2)
        return chunk[i]

      averagedLogs.unshift temperature_logs[0]
      averagedLogs.push temperature_logs[temperature_logs.length-1]
      $scope.temperatureLogs = averagedLogs

    $scope.updateResolution = =>
      if $scope.temperatureLogsCache.length > 0

        if ($scope.resolution)
          $scope.resizeTemperatureLogs()
          $scope.updateScrollWidth()
          $scope.updateData()

        else #view all
          $scope.resolution = $scope.greatest_elapsed_time/1000
          $scope.updateScrollWidth()
          $scope.updateChart angular.copy $scope.temperatureLogs

    $scope.$watch 'widthPercent', ->
      if $scope.widthPercent is 1 and $scope.isCurrentExperiment
        $scope.autoUpdateTemperatureLogs()

    $scope.$watch 'scrollState', ->
      if $scope.scrollState and $scope.temperatureLogs and $scope.data
        $scope.updateData()

        if $scope.scrollState >= 1 and $scope.isCurrentExperiment
          $scope.autoUpdateTemperatureLogs()
        else
          $scope.stopInterval()

    $scope.updateChart = (temperature_logs) ->
      $scope.data = ChartData.temperatureLogs(temperature_logs).toN3LineChart()

    $scope.autoUpdateTemperatureLogs = =>
      if !$scope.updateInterval and $scope.isCurrentExperiment and Status.getData().experimentController?.machine?.state is 'Running'
        $scope.updateInterval = $interval () ->
          Experiment
          .getTemperatureData($stateParams.id, resolution: 1000)
          .success (data) ->
            $scope.temperatureLogsCache = angular.copy data
            $scope.temperatureLogs = angular.copy data
            $scope.updateScale()
            $scope.resizeTemperatureLogs()
            $scope.updateScrollWidth()
            $scope.updateData()

        , 10000

      else if !$scope.isCurrentExperiment
        $scope.stopInterval()

    $scope.stopInterval = =>
      $interval.cancel $scope.updateInterval if $scope.updateInterval
      $scope.updateInterval = null

    elem.on '$destroy', ->
      Status.stopSync()
      $scope.stopInterval()

    $scope.options = {
      axes: {
        x: {
          key: 'elapsed_time',
          ticksFormatter: (t) -> SecondsDisplay.display2(t)
          ticks: 8
        },
        y: {
          key: 'heat_block_zone_temp'
          type: 'linear'
          min: 0
          max: 0
        }
      },
      margin: {
        left: 30
      },
      series: [
        {y: 'heat_block_zone_temp', color: 'steelblue'},
        {y: 'lid_temp', color: 'lightsteelblue'}
      ],
      lineMode: 'linear',
      tension: 0.7,
      tooltip: {
        mode: 'scrubber',
        formatter: (x, y, series) ->
          if series.y is 'lid_temp'
            return "#{SecondsDisplay.display2(x)} | Lid Temp: #{y}"
          else if series.y is 'heat_block_zone_temp'
            return "#{SecondsDisplay.display2(x)} | Heat Block Zone Temp: #{y}"
          else
            return ''
      },
      drawLegend: false,
      drawDots: false,
      hideOverflow: false,
      columnsHGap: 5
    }

]