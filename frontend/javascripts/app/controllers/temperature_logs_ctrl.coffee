App.controller 'TemperatureLogCtrl', [
  '$scope'
  'Experiment'
  'TemperatureLogService'
  'SecondsDisplay'
  'Status'
  '$interval'
  '$stateParams'
  '$rootScope'
  '$timeout'
  ($scope, Experiment, TemperatureLogService, SecondsDisplay, Status, $interval, $stateParams, $rootScope, $timeout) ->

    $scope.options = TemperatureLogService.chartConfig
    greatest_elapsed_time = 0
    $scope.resolution = 0

    getExperiment = (cb) ->
      Experiment.get(id: $stateParams.id)
      .then (data) ->
        $scope.experiment = data.experiment
        cb(data.experiment) if cb

    init = ->

      updateScrollWidth = ->
        widthPercent = $scope.resolution/greatest_elapsed_time
        widthPercent = if widthPercent > 1 then 1 else (if widthPercent < 0 then 0 else widthPercent)
        angular.element('#temp-logs-scrollbar .scrollbar').css width: "#{widthPercent*100}%"
        $rootScope.$broadcast 'scrollbar:width:changed'

      fetchTemperatureLogs = ->
        Experiment.getTemperatureData($stateParams.id)
        .then (data) ->
          return if !data
          return if data.length is 0
          greatest_elapsed_time = data[data.length-1].temperature_log.elapsed_time/1000
          greatest_elapsed_time = if greatest_elapsed_time < 5*60 then 60*5 else greatest_elapsed_time
          $scope.data = TemperatureLogService.parseData(data)
          updateResolutionOptions()
          moveData()

      updateResolutionOptions = ->
        $scope.resolutionOptions = []
        zoom_calibration = 10
        zoom_denomination = greatest_elapsed_time / zoom_calibration
        if greatest_elapsed_time < 60*5
          $scope.resolutionOptions.push(60*5)

        for zoom in [zoom_calibration..1] by -1
          $scope.resolutionOptions.push(parseFloat((zoom*zoom_denomination).toFixed(2)) )

        updateCurrentResolution()
        updateScrollWidth()

      updateCurrentResolution = ->
        $scope.resolution = $scope.resolutionOptions[$scope.resolutionIndex || 0]

      updateChart = (opts) ->
        opts = opts || {}
        $scope.options.axes.x.min = opts.min_x || 0
        $scope.options.axes.x.max = opts.max_x || 0
        $timeout ->
          $scope.$broadcast '$reload:n3:charts'
        , 500

      moveData = ->
        console.log 'moveData'
        newConfig = TemperatureLogService.moveData(greatest_elapsed_time, $scope.resolution, $scope.scrollState)
        console.log newConfig
        updateChart(newConfig)

      $scope.$on 'status:data:updated', (e, val) ->
        if val
          $scope.scrollState = $scope.scrollState || 'FULL'
          $scope.isCurrentExperiment = parseInt(val.experiment_controller?.expriment?.id) is parseInt($stateParams.id)
          if $scope.isCurrentExperiment and ($scope.scrollState >= 1 || $scope.scrollState is 'FULL' || greatest_elapsed_time <= 5*60) and (val.experiment_controller?.machine.state is 'lid_heating' || val.experiment_controller?.machine.state is 'running')
            $scope.autoUpdateTemperatureLogs()
          else
            $scope.stopInterval()

      $scope.autoUpdateTemperatureLogs = =>
        if !$scope.updateInterval
          fetchTemperatureLogs()
          $scope.updateInterval = $interval fetchTemperatureLogs, 10000

      $scope.stopInterval = =>
        $interval.cancel $scope.updateInterval if $scope.updateInterval
        $scope.updateInterval = null

      $scope.getLegend = ->
        TemperatureLogService.legend

      $scope.$watch 'resolutionIndex', ->
        return if !$scope.resolutionOptions or $scope.resolutionOptions.length is 0
        updateCurrentResolution()
        updateScrollWidth()
        moveData()

      $scope.$watch 'scrollState', ->
        moveData()

      $scope.$watch ->
        $scope.RunExperimentCtrl.chart
      , (chart) ->
        if chart is 'temperature-logs'
          if !$scope.data
            fetchTemperatureLogs()
          else
            $timeout ->
              $rootScope.$broadcast '$reload:n3:charts'
            , 1000

    getExperiment ->
      init()

]