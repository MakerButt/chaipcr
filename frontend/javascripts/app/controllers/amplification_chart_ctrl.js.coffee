###
Chai PCR - Software platform for Open qPCR and Chai's Real-Time PCR instruments.
For more information visit http://www.chaibio.com

Copyright 2016 Chai Biotechnologies Inc. <info@chaibio.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
###
window.ChaiBioTech.ngApp.controller 'AmplificationChartCtrl', [
  '$scope'
  '$stateParams'
  'Experiment'
  'AmplificationChartHelper'
  'expName'
  '$interval'
  'Device'
  '$timeout'
  '$rootScope'
  'focus'
  ($scope, $stateParams, Experiment, helper, expName, $interval, Device, $timeout, $rootScope, focus ) ->

    Device.isDualChannel().then (is_dual_channel) ->
      $scope.is_dual_channel = is_dual_channel

      hasInit = false
      $scope.chartConfig = helper.chartConfig()
      $scope.chartConfig.channels = if is_dual_channel then 2 else 1
      $scope.chartConfig.axes.x.max = $stateParams.max_cycle || 1
      $scope.amplification_data = helper.paddData()
      $scope.well_data = []
      $scope.simple_well_data = []

      $scope.COLORS = helper.SAMPLE_TARGET_COLORS
      $scope.WELL_COLORS = helper.COLORS      
      AMPLI_DATA_CACHE = null
      retryInterval = null
      $scope.baseline_subtraction = true
      $scope.curve_type = 'linear'
      $scope.color_by = 'well'
      $scope.retrying = false
      $scope.retry = 0
      $scope.fetching = false
      $scope.channel_1 = true
      $scope.channel_2 = if is_dual_channel then true else false
      $scope.ampli_zoom = 0
      $scope.showOptions = true
      $scope.isError = false

      $scope.method = {name: 'Cy0'}
      $scope.baseline_sub = 'auto'

      $scope.baseline_method = {name: 'sigmoid'}
      
      $scope.cy0 = {name:'Cy0', desciption:'A C<sub>q</sub> calling method based on the max first derivative of the curve (recommended).'}
      $scope.cpd2 = {name:'cpD2', desciption:'A C<sub>q</sub> calling method based on the max second derivative of the curve.'}
      $scope.minFl = {name: 'Min Fluorescence', desciption:'The minimum fluorescence threshold for C<sub>q</sub> calling. C<sub>q</sub> values will not be called when the fluorescence is below this threshold.', value:null}
      $scope.minCq = {name: 'Min Cycle', desciption:'The earliest cycle to use in C<sub>q</sub> calling & baseline subtraction. Data for earlier cycles will be ignored.', value:null}
      $scope.minDf = {name: 'Min dF/dc', desciption:'The threshold which the first derivative of the curve must exceed for a C<sub>q</sub> to be called.', value:null}
      $scope.minD2f = {name: 'Min d<sup>2</sup>F/dc', desciption:'The threshold which the second derivative of the curve must exceed for a C<sub>q</sub> to be called.', value:null}
      $scope.baseline_auto = {name:'Auto', desciption:'Automatically detect the baseline cycles.'}
      $scope.baseline_manual = {name:'Manual', desciption:'Manually specify the baseline cycles.'}

      $scope.sigmoid = {name:'Sigmoid', desciption:'Calculate baseline by fitting a sigmoid curve to amplification data. Falls back to median method if sigmoid curve fitting fails.'}
      $scope.linear = {name:'Linear', desciption:'Calculate baseline by fitting a linear line to baseline cycles.'}
      $scope.median = {name:'Median', desciption:'Calculate baseline by taking the median value from baseline cycles.'}

      $scope.cyclesFrom = null
      $scope.cyclesTo = null
      $scope.hoverName = 'Min. Fluorescence'
      $scope.hoverDescription = 'This is a test description'
      $scope.samples = []
      $scope.types = []
      $scope.targets = []
      $scope.targetsSet = []
      $scope.targetsSetHided = []
      $scope.samplesSet = []
      $scope.editExpNameMode = []
      $scope.editExpTargetMode = []
      $scope.omittedIndexes = []
      $scope.well_targets = []

      $scope.label_cycle = ''
      $scope.label_RFU = ''
      $scope.label_dF_dC = ''
      $scope.label_D2_dc2 = ''

      $scope.index_target = 0
      $scope.index_channel = -1
      $scope.label_sample = null
      $scope.label_target = "No Selection"
      $scope.label_well = "No Selection"
      $scope.label_channel = ""

      $scope.has_init = false
      $scope.init_sample_color = '#ccc'
      $scope.isSampleMode = true

      $scope.bgcolor_target = {
        'background-color':'#666666'
      }
        
      $scope.bgcolor_wellSample = {
        'background-color':'#666666'
      }

      modal = document.getElementById('myModal')
      span = document.getElementsByClassName("close")[0]

      last_well_number = 0
      last_target_channel = 0
      last_target_assigned = 0

      $scope.registerOutsideHover = false;
      unhighlight_event = ''

      if !$scope.registerOutsideHover
        $scope.registerOutsideHover = angular.element(window).on 'mousemove', (e)->
          if !angular.element(e.target).parents('.well-switch').length and !angular.element(e.target).parents('.well-item-row').length 
            if unhighlight_event
              $rootScope.$broadcast unhighlight_event, {}
              unhighlight_event = ''
              last_well_number = 0
              last_target_channel = 0
              last_target_assigned = 0

          $scope.$apply()

      $scope.toggleOmitIndex = (well_item) ->
        omit_index = well_item.well_num.toString() + '_' + well_item.channel.toString()
        if $scope.omittedIndexes.indexOf(omit_index) != -1
          $scope.omittedIndexes.splice $scope.omittedIndexes.indexOf(omit_index), 1
        else
          $scope.omittedIndexes.push omit_index
        # alert $scope.omittedIndexes
        # return
        updateSeries()

      $scope.$watch '$viewContentLoaded', ->
        $rootScope.$broadcast 'event:start-resize-aspect-ratio'

      $scope.$watchCollection 'targetsSetHided', ->
        updateSeries()

      $scope.$on 'expName:Updated', ->
        $scope.experiment?.name = expName.name

      $scope.openOptionsModal = ->
        #$scope.showOptions = true
        #Device.openOptionsModal()
        $scope.errorCheck = false
        $scope.errorCheck = false
        $scope.errorCq = false
        $scope.errorDf = false
        $scope.errorD2f = false

        modal.style.display = "block"        

      $scope.close = ->
        modal.style.display = "none"
        $scope.getAmplificationOptions()

      $scope.check = ->
        $scope.errorCheck = false
        if !$scope.minFl.value
          $scope.hoverName = 'Error'
          $scope.hoverDescription = 'Min Fluorescence cannot be left empty'
          $scope.hoverOn = true
          $scope.errorCheck = true
          $scope.errorFl = true
        if !$scope.minCq.value
          $scope.hoverName = 'Error'
          $scope.hoverDescription = 'Min Cycles cannot be left empty'
          $scope.hoverOn = true
          $scope.errorCheck = true
          $scope.errorCq = true
        if $scope.minCq.value < 1 && $scope.minCq.value
          $scope.hoverName = 'Error'
          $scope.hoverDescription = 'Min Cycles should be greater than 0'
          $scope.hoverOn = true
          $scope.errorCheck = true
          $scope.errorCq = true
        if !$scope.minDf.value
          $scope.hoverName = 'Error'
          $scope.hoverDescription = 'Min dF/dc cannot be left empty'
          $scope.hoverOn = true
          $scope.errorCheck = true
          $scope.errorDf = true
        if !$scope.minD2f.value
          $scope.hoverName = 'Error'
          $scope.hoverDescription = 'Min d<sup>2</sup>F/dc cannot be left empty'
          $scope.hoverOn = true
          $scope.errorCheck = true
          $scope.errorD2f = true
        if $scope.baseline_sub != 'auto' && (!$scope.cyclesFrom || !$scope.cyclesTo)
          $scope.hoverName = 'Error'
          $scope.hoverDescription = 'Range for baseline cycles cannot be left empty'
          $scope.hoverOn = true
          $scope.errorCheck = true

        if !$scope.errorCheck
          if $scope.baseline_sub == 'auto'
            $scope.baseline_cycle_bounds = null
          else
            $scope.baseline_cycle_bounds = [parseInt($scope.cyclesFrom), parseInt($scope.cyclesTo)]
          Experiment
          .updateAmplificationOptions(
            $stateParams.id,
            {
              'cq_method':$scope.method.name,
              'min_fluorescence': parseInt($scope.minFl.value), 
              'min_reliable_cycle': parseInt($scope.minCq.value), 
              'min_d1': parseInt($scope.minDf.value), 
              'min_d2': parseInt($scope.minD2f.value), 
              'baseline_cycle_bounds': $scope.baseline_cycle_bounds,
              'baseline_method': $scope.baseline_method.name
            })
          .then (resp) ->
            $scope.amplification_data = helper.paddData()
            $scope.hasData = false
            for well_i in [0..15] by 1
              $scope.wellButtons["well_#{well_i}"].ct = 0
            $scope.close()
            fetchFluorescenceData()
          .catch (resp) ->
            if resp != 'canceled'
              $scope.hoverName = 'Error'
              $scope.hoverDescription = resp.data || 'Unknown error'
              $scope.hoverOn = true

      $scope.hover = (model) ->
      
        $scope.hoverName = model.name
        $scope.hoverDescription = model.desciption
        $scope.hoverOn = true
      
      $scope.hoverLeave = ->
        $scope.hoverOn = false

      $scope.getAmplificationOptions = ->
        Experiment.getAmplificationOptions($stateParams.id).then (resp) ->
          $scope.method.name = resp.data.amplification_option.cq_method
          $scope.baseline_method.name = resp.data.amplification_option.baseline_method
          $scope.minFl.value = resp.data.amplification_option.min_fluorescence
          $scope.minCq.value = resp.data.amplification_option.min_reliable_cycle
          $scope.minDf.value = resp.data.amplification_option.min_d1
          $scope.minD2f.value = resp.data.amplification_option.min_d2

          if resp.data.amplification_option.baseline_cycle_bounds is null
            $scope.baseline_sub = 'auto'
          else
            $scope.baseline_sub = 'cycles'
            $scope.cyclesFrom = resp.data.amplification_option.baseline_cycle_bounds[0]
            $scope.cyclesTo = resp.data.amplification_option.baseline_cycle_bounds[1]
        .catch (resp) ->
          $scope.hoverName = 'Error'
          $scope.hoverDescription = resp.data || 'Unknown error'
          $scope.hoverOn = true

      $scope.getAmplificationOptions()

      $scope.focusExpName = (index) ->
        $scope.editExpNameMode[index] = true
        focus('editExpNameMode')

      $scope.updateSampleNameEnter = (well_num, name) ->
        Experiment.updateWell($stateParams.id, well_num + 1, {'well_type':'sample','sample_name':name})
        $scope.editExpNameMode[well_num] = false


        if event.shiftKey
          $scope.focusExpName(well_num - 1)
        else
          $scope.focusExpName(well_num + 1)
        $scope.updateSamplesSet()
        updateSeries()

      $scope.updateSampleName = (well_num, name) ->
        Experiment.updateWell($stateParams.id, well_num + 1, {'well_type':'sample','sample_name':name})
        $scope.editExpNameMode[well_num] = false
        $scope.updateSamplesSet()
        updateSeries()

      $scope.focusExpTarget = (index) ->
        $scope.editExpTargetMode[index] = true
        focus('editExpTargetMode')

      $scope.updateTargetEnter = (well_num, target) ->
        Experiment.updateWell($stateParams.id, well_num + 1, {'well_type':'sample','targets':[target]})
        $scope.editExpTargetMode[well_num] = false
        if event.shiftKey
          $scope.focusExpTarget(well_num - 1)
        else
          $scope.focusExpTarget(well_num + 1)
        $scope.updateTargetsSet()
        updateSeries()

      $scope.updateTarget = (well_num, target) ->
        Experiment.updateWell($stateParams.id, well_num + 1, {'well_type':'sample','targets':[target]})
        $scope.editExpTargetMode[well_num] = false
        $scope.updateTargetsSet()
        updateSeries()
      
      $scope.updateTargetsSet = ->
        # $scope.targetsSet = []
        for i in [0...$scope.targets.length]
          if $scope.targets[i].id
            target = _.filter $scope.targetsSet, (item) ->
              item.id is $scope.targets[i].id
            if !target.length              
              $scope.targetsSet.push($scope.targets[i])

        for i in [$scope.targetsSet.length-1..0] by -1
          if $scope.targetsSet[i]?.id
            target = _.filter $scope.targets, (item) ->
              item.id is $scope.targetsSet[i].id
            if !target.length
              $scope.targetsSet.splice(i, 1)

      $scope.updateSamplesSet = ->
        $scope.samplesSet = []

        # for i in [0...16]
        #   if $scope.samples[i] and $scope.samplesSet.indexOf($scope.samples[i]) < 0
        #     $scope.samplesSet.push($scope.samples[i])

      $scope.$on 'event:switch-chart-well', (e, data, oldData) ->
        if !data.active
          $scope.onUnselectLine()

        channel_count = if $scope.is_dual_channel then 2 else 1
        wellScrollTop = (data.index * channel_count + channel_count) * 36 - document.querySelector('.table-container').offsetHeight
        angular.element(document.querySelector('.table-container')).animate { scrollTop: wellScrollTop }, 'fast'

      Experiment.get(id: $stateParams.id).then (data) ->
        maxCycle = helper.getMaxExperimentCycle(data.experiment)
        $scope.chartConfig.axes.x.max = maxCycle
        $scope.experiment = data.experiment

      $scope.$on 'status:data:updated', (e, data, oldData) ->
        return if !data
        return if !data.experiment_controller
        $scope.statusData = data
        $scope.state = data.experiment_controller.machine.state
        $scope.thermal_state = data.experiment_controller.machine.thermal_state
        $scope.oldState = oldData?.experiment_controller?.machine?.state || 'NONE'
        $scope.isCurrentExp = parseInt(data.experiment_controller.experiment?.id) is parseInt($stateParams.id)
        
        if $scope.isCurrentExp is true
          $scope.enterState = $scope.isCurrentExp

      retry = ->
        $scope.retrying = true
        $scope.retry = 5
        retryInterval = $interval ->
          $scope.retry = $scope.retry - 1
          if $scope.retry is 0
            $interval.cancel(retryInterval)
            $scope.retrying = false
            $scope.error = null
            fetchFluorescenceData()
        , 1000

      fetchFluorescenceData = ->
        gofetch = true
        gofetch = false if $scope.fetching
        gofetch = false if $scope.$parent.chart isnt 'amplification'
        gofetch = false if $scope.retrying
        
        if gofetch
          hasInit = true
          $scope.fetching = true

          # alert('h6')

          Experiment.getAmplificationData($stateParams.id)
          .then (resp) ->            
            $scope.has_init = true
            $scope.fetching = false
            $scope.error = null

            if (resp.status is 200 and resp.data?.partial and $scope.enterState) or (resp.status is 200 and !resp.data.partial)
              $scope.hasData = true
              $scope.amplification_data = helper.paddData()
            if (resp.status is 304)
              $scope.hasData = false
            if resp.status is 200 and !resp.data.partial
              $rootScope.$broadcast 'complete'
            if (resp.data.steps?[0].amplification_data and resp.data.steps?[0].amplification_data?.length > 1)
              $scope.chartConfig.axes.x.min = 1
              $scope.hasData = true
              data = resp.data.steps[0]

              $scope.well_data = helper.normalizeSummaryData(data.summary_data, data.targets, $scope.well_targets)
              $scope.targets = helper.normalizeWellTargetData($scope.well_data, $scope.targets, $scope.is_dual_channel)

              for i in [0..$scope.targets.length - 1] by 1
                $scope.targetsSetHided[$scope.targets[i]?.id] = true if $scope.targetsSetHided[$scope.targets[i]?.id] is undefined

              data.amplification_data?.shift()
              data.cq?.shift()
              data.amplification_data = helper.neutralizeData(data.amplification_data, $scope.targets, $scope.is_dual_channel)
              data.summary_data = helper.initialSummaryData(data.summary_data, data.targets)

              AMPLI_DATA_CACHE = angular.copy data
              $scope.amplification_data = data.amplification_data

              $scope.updateTargetsSet()
              updateButtonCts()
              updateSeries()

              $scope.simple_well_data = helper.normalizeSimpleSummaryData($scope.well_data, $scope.targetsSet)

              if !(($scope.experiment?.completion_status && $scope.experiment?.completed_at) or $scope.enterState)
                $scope.retrying = true

              # retry()
            if ((resp.data?.partial is true) or (resp.status is 202) or (resp.status is 304)) and !$scope.retrying
              retry()

          .catch (resp) ->
            if resp.status is 500
              $scope.error = resp.statusText || 'Unknown error'
            $scope.fetching = false
            return if $scope.retrying
            retry()
        else
          retry()

      updateButtonCts = ->
        for well_i in [0..15] by 1
          channel_1_well = _.find $scope.well_data, (item) ->
            item.well_num is well_i+1 and item.channel is 1

          channel_2_well = _.find $scope.well_data, (item) ->
            item.well_num is well_i+1 and item.channel is 2

          $scope.wellButtons["well_#{well_i}"].well_type = []
          $scope.wellButtons["well_#{well_i}"].well_type.push(if channel_1_well then channel_1_well.well_type else '')
          $scope.wellButtons["well_#{well_i}"].well_type.push(if channel_2_well then channel_2_well.well_type else '')

          cts = _.filter AMPLI_DATA_CACHE.summary_data, (ct) ->
            ct[1] is well_i+1

          $scope.wellButtons["well_#{well_i}"].ct = []
          for ct_i in [0..cts.length - 1] by 1
            $scope.wellButtons["well_#{well_i}"].ct.push(cts[ct_i][3])

        return
        # for well_i in [0..15] by 1
        #   cts = _.filter AMPLI_DATA_CACHE.cq, (ct) ->
        #     ct[1] is well_i+1
        #   $scope.wellButtons["well_#{well_i}"].ct = [cts[0][2]]
        #   $scope.wellButtons["well_#{well_i}"].ct.push cts[1][2] if cts[1]
        # return

      updateSeries = (buttons) ->
        buttons = buttons || $scope.wellButtons || {}
        $scope.chartConfig.series = []
        nonGreySeries = []
        subtraction_type = if $scope.baseline_subtraction then 'baseline' else 'background'
        channel_count = if $scope.is_dual_channel then 2 else 1
        channel_end = if $scope.channel_1 && $scope.channel_2 then 2 else if $scope.channel_1 && !$scope.channel_2 then 1 else if !$scope.channel_1 && $scope.channel_2 then 2
        channel_start = if $scope.channel_1 && $scope.channel_2 then 1 else if $scope.channel_1 && !$scope.channel_2 then 1 else if !$scope.channel_1 && $scope.channel_2 then 2

        for ch_i in [channel_start..channel_end] by 1
          for i in [0..15] by 1
            if $scope.omittedIndexes.indexOf(getWellDataIndex(i + 1, ch_i)) == -1
              if buttons["well_#{i}"]?.selected and $scope.targets[i * channel_count + (ch_i - 1)] and $scope.targets[i * channel_count + (ch_i - 1)].id and $scope.targetsSetHided[$scope.targets[i * channel_count + (ch_i - 1)].id]
                if $scope.color_by is 'well'
                  well_color = buttons["well_#{i}"].color
                else if $scope.color_by is 'target'
                  well_color = if $scope.targets[(ch_i - 1)+i*channel_count] then $scope.targets[(ch_i - 1)+i*channel_count].color else 'transparent'
                else if $scope.color_by is 'sample'
                  well_color = if $scope.samples[i] then $scope.samples[i].color else $scope.init_sample_color
                  if ($scope.is_dual_channel and !$scope.targets[i*channel_count].id and !$scope.targets[i*channel_count+1].id) or (!$scope.is_dual_channel and !$scope.targets[i].id)
                    well_color = 'transparent'
                else if ch_i is 1
                  well_color = '#00AEEF'
                else
                  well_color = '#8FC742'

                if $scope.color_by is 'sample'
                  if well_color is $scope.init_sample_color
                    $scope.chartConfig.series.push
                      dataset: "channel_#{ch_i}"
                      x: 'cycle_num'
                      y: "well_#{i}_#{subtraction_type}#{if $scope.curve_type is 'log' then '_log' else ''}"
                      dr1_pred: "well_#{i}_#{'dr1_pred'}"
                      dr2_pred: "well_#{i}_#{'dr2_pred'}"
                      color: well_color
                      cq: $scope.wellButtons["well_#{i}"]?.ct
                      well: i
                      channel: ch_i
                  else
                    nonGreySeries.push
                      dataset: "channel_#{ch_i}"
                      x: 'cycle_num'
                      y: "well_#{i}_#{subtraction_type}#{if $scope.curve_type is 'log' then '_log' else ''}"
                      dr1_pred: "well_#{i}_#{'dr1_pred'}"
                      dr2_pred: "well_#{i}_#{'dr2_pred'}"
                      color: well_color
                      cq: $scope.wellButtons["well_#{i}"]?.ct
                      well: i
                      channel: ch_i                   
                else
                  $scope.chartConfig.series.push
                    dataset: "channel_#{ch_i}"
                    x: 'cycle_num'
                    y: "well_#{i}_#{subtraction_type}#{if $scope.curve_type is 'log' then '_log' else ''}"
                    dr1_pred: "well_#{i}_#{'dr1_pred'}"
                    dr2_pred: "well_#{i}_#{'dr2_pred'}"
                    color: well_color
                    cq: $scope.wellButtons["well_#{i}"]?.ct
                    well: i
                    channel: ch_i
            else
              $scope.onUnselectLine()

        if $scope.color_by is 'sample'
          for i in [0..nonGreySeries.length - 1] by 1
            $scope.chartConfig.series.push(nonGreySeries[i])

      getWellDataIndex = (well_num, channel) ->
        return well_num.toString() + '_' + channel

      $scope.onUpdateProperties = (cycle, rfu, dF_dC, d2_dc2) ->
        $scope.label_cycle = cycle
        $scope.label_RFU = rfu
        $scope.label_dF_dC = dF_dC
        $scope.label_D2_dc2 = d2_dc2

      $scope.onZoom = (transform, w, h, scale_extent) ->
        $scope.ampli_scroll = {
          value: Math.abs(transform.x/(w*transform.k - w))
          width: w/(w*transform.k)
        }
        $scope.ampli_zoom = (transform.k - 1)/ (scale_extent)

      $scope.zoomIn = ->
        $scope.ampli_zoom = Math.min($scope.ampli_zoom * 2 || 0.001 * 2, 1)

      $scope.zoomOut = ->
        $scope.ampli_zoom = Math.max($scope.ampli_zoom * 0.5, 0.001)

      $scope.onSelectWell = (well_item, index) ->
        config = {}
        config.config = {}
        config.config.well = well_item.well_num - 1
        config.config.channel = well_item.channel

        dual_value = if $scope.is_dual_channel then 2 else 1
        omit_index = well_item.well_num.toString() + '_' + well_item.channel.toString()

        if $scope.wellButtons['well_' + (well_item.well_num - 1)].selected and $scope.omittedIndexes.indexOf(omit_index) == -1 and $scope.targetsSetHided[$scope.targets[index].id]
          for well_i in [0..$scope.well_data.length - 1]
            $scope.well_data[well_i].active = ($scope.well_data[well_i].well_num - 1 == config.config.well and $scope.well_data[well_i].channel == config.config.channel)

          for i in [0..15] by 1
            $scope.wellButtons["well_#{i}"].active = (i == config.config.well)
            if(i == config.config.well)
              $scope.index_target = i % 8
              if (i < 8) 
                $scope.index_channel = 1
              else 
                $scope.index_channel = 2

              $scope.label_channel = config.config.channel
              if i < $scope.targets.length
                if $scope.targets[i]!=null
                  $scope.label_target = $scope.targets[config.config.well * dual_value + config.config.channel - 1]
                else
                  $scope.label_target = ""
              else 
                $scope.label_target = ""

              if i < $scope.targets.length
                if $scope.samples[i]!=null
                  $scope.label_sample = $scope.samples[i].name if $scope.samples[i]
                else
                  $scope.label_sample = null
              else 
                $scope.label_sample = null

              # $scope.label_dF_dC = 
              # $scope.label_D2_dc2 = 
              wells = ['A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'B8']
              $scope.label_well = wells[i]

        if $scope.label_target.name
          $scope.bgcolor_target = { 'background-color':'black' }
        else 
          $scope.bgcolor_target = { 'background-color':'#666' }

      $scope.onSelectRow = (well_item, index) ->
        for well_i in [0..$scope.well_data.length - 1]
          $scope.well_data[well_i].highlight = false

        omit_index = well_item.well_num.toString() + '_' + well_item.channel.toString()
        if !$scope.has_init or (($scope.wellButtons['well_' + (well_item.well_num - 1)].selected) and ($scope.omittedIndexes.indexOf(omit_index) == -1) and ($scope.targetsSetHided[$scope.targets[index].id]))
          if !well_item.active
            $rootScope.$broadcast 'event:amp-select-row', {well: well_item.well_num, channel: well_item.channel}
          else
            $rootScope.$broadcast 'event:amp-unselect-row', {well: well_item.well_num, channel: well_item.channel}

      $scope.onSelectSimpleRow = (event, well_item, well_target) ->
        isTargetCell = angular.element(event.target).parents('td').hasClass('target-cell')
        if isTargetCell and well_target
          omit_index = well_item.well_num.toString() + '_' + well_target.channel.toString()
          if well_target.assigned and $scope.omittedIndexes.indexOf(omit_index) == -1          
            if !well_item.active or $scope.active_cell != omit_index
              $scope.active_cell = omit_index
              $rootScope.$broadcast 'event:amp-select-row', {well: well_item.well_num, channel: well_target.channel}
            else
              $rootScope.$broadcast 'event:amp-unselect-row', {well: well_item.well_num, channel: well_target.channel}

      $scope.isTargetHover = (well_item) ->
        for target_index in [0..well_item.targets.length - 1]
          if well_item.targets[target_index].selected
            return true
        return false

      $scope.onHoverRow = (event, well_item, index) ->
        is_active_line = false
        for well_i in [0..$scope.well_data.length - 1]
          if $scope.well_data[well_i].active
            is_active_line = true
            break

        if is_active_line or (last_well_number == well_item.well_num and last_target_channel == well_item.channel)
          return

        last_well_number = well_item.well_num
        last_target_channel = well_item.channel

        omit_index = well_item.well_num.toString() + '_' + well_item.channel.toString()
        if !$scope.has_init or (($scope.wellButtons['well_' + (well_item.well_num - 1)].selected) and ($scope.omittedIndexes.indexOf(omit_index) == -1) and ($scope.targetsSetHided[$scope.targets[index].id]))
          if !well_item.active
            $rootScope.$broadcast 'event:amp-highlight-row', { well_datas: [{well: well_item.well_num, channel: well_item.channel}], well_index: well_item.well_num - 1 }
            unhighlight_event = 'event:amp-unhighlight-row'

      $scope.onHoverSimpleRow = (event, well_item) ->
        is_active_line = false
        for well_i in [0..$scope.simple_well_data.length - 1]
          if $scope.simple_well_data[well_i].active
            is_active_line = true
            break

        tdElem = if angular.element(event.target).hasClass('target-cell') then angular.element(event.target) else angular.element(event.target).parents('td.target-cell')
        target_channel = angular.element(tdElem).data('channel')
        target_assigned = angular.element(tdElem).hasClass('assigned')

        if is_active_line or (last_well_number is well_item.well_num and last_target_channel is target_channel and last_target_assigned is target_assigned)
          return

        last_well_number = well_item.well_num
        last_target_channel = target_channel
        last_target_assigned = target_assigned

        if !(target_channel and target_assigned)
          if !well_item.active
            $rootScope.$broadcast 'event:amp-highlight-row', { well_datas: [{well: well_item.well_num, channel: 0}], well_index: well_item.well_num - 1 }
            unhighlight_event = 'event:amp-unhighlight-row'
        else
          omit_index = well_item.well_num.toString() + '_' + target_channel.toString()
          if last_target_assigned and $scope.omittedIndexes.indexOf(omit_index) == -1          
            if !well_item.active or $scope.active_cell != omit_index
              $scope.active_cell = omit_index              
              $rootScope.$broadcast 'event:amp-highlight-row', { well_datas: [{well: well_item.well_num, channel: target_channel}], well_index: well_item.well_num - 1 }
              unhighlight_event = 'event:amp-unhighlight-row'

      $scope.onHighlightLines = (configs, well_index) ->
        if well_index == -1
          well_index = configs[0].config.well
          
        for well_i in [0..$scope.well_data.length - 1]
          $scope.well_data[well_i].active = false
          $scope.well_data[well_i].highlight = false
        
        for well_i in [0..$scope.well_data.length - 1]
          for config, i in configs by 1            
            if ($scope.well_data[well_i].well_num - 1 == config.config.well and $scope.well_data[well_i].channel == config.config.channel)
              $scope.well_data[well_i].highlight = true
        
        for well_i in [0..$scope.simple_well_data.length - 1]
          $scope.simple_well_data[well_i].active = false
          $scope.simple_well_data[well_i].highlight = false
          for target_index in [0..$scope.simple_well_data[well_i].targets.length - 1]
            $scope.simple_well_data[well_i].targets[target_index].selected = false

        for well_i in [0..$scope.simple_well_data.length - 1]
          if configs.length == 1
            config = configs[0]
            if ($scope.simple_well_data[well_i].well_num - 1 == config.config.well)
              $scope.simple_well_data[well_i].highlight = true
              for target_index in [0..$scope.simple_well_data[well_i].targets.length - 1]
                if $scope.simple_well_data[well_i].targets[target_index].assigned and $scope.simple_well_data[well_i].targets[target_index].channel == config.config.channel
                  $scope.simple_well_data[well_i].targets[target_index].selected = true
          else if configs.length > 1
            if ($scope.simple_well_data[well_i].well_num - 1 == config.config.well)
              $scope.simple_well_data[well_i].highlight = true
              for target_index in [0..$scope.simple_well_data[well_i].targets.length - 1]
                $scope.simple_well_data[well_i].targets[target_index].selected = false

        for i in [0..15] by 1
          $scope.wellButtons["well_#{i}"].active = (i == well_index)

        dual_value = if $scope.is_dual_channel then 2 else 1
        config = configs[0]

        if !unhighlight_event && config
          if !$scope.isSampleMode
            wellScrollTop = (config.config.well * dual_value + config.config.channel - 1 + dual_value) * 36 - document.querySelector('.detail-mode-table tbody').offsetHeight
            angular.element('.detail-mode-table tbody').animate { scrollTop: wellScrollTop }, 'fast'
          else
            wellScrollTop = (config.config.well + config.config.channel - 1 + dual_value) * 36 - document.querySelector('.simple-mode-table tbody').offsetHeight
            angular.element('.simple-mode-table tbody').animate { scrollTop: wellScrollTop }, 'fast'

        return

      $scope.onUnHighlightLines = (configs) ->
        $scope.onUnselectLine()
        return

      $scope.onSelectLine = (config) ->
        $scope.bgcolor_target = { 'background-color':'black' }
        # $scope.bgcolor_wellSample = { 'background-color':'black' }

        # $scope.bgcolor_target = { 'background-color':config.config.color }
        dual_value = if $scope.is_dual_channel then 2 else 1

        for well_i in [0..$scope.well_data.length - 1]
          $scope.well_data[well_i].active = ($scope.well_data[well_i].well_num - 1 == config.config.well and $scope.well_data[well_i].channel == config.config.channel)

        for well_i in [0..$scope.simple_well_data.length - 1]
          $scope.simple_well_data[well_i].active = false
          $scope.simple_well_data[well_i].highlight = false
          for target_index in [0..$scope.simple_well_data[well_i].targets.length - 1]
            $scope.simple_well_data[well_i].targets[target_index].selected = false

        for well_i in [0..$scope.simple_well_data.length - 1]
          if ($scope.simple_well_data[well_i].well_num - 1 == config.config.well)
            $scope.simple_well_data[well_i].active = ($scope.simple_well_data[well_i].well_num - 1 == config.config.well)
            for target_index in [0..$scope.simple_well_data[well_i].targets.length - 1]
              if $scope.simple_well_data[well_i].targets[target_index].assigned and $scope.simple_well_data[well_i].targets[target_index].channel == config.config.channel
                $scope.simple_well_data[well_i].targets[target_index].selected = true

        for i in [0..15] by 1
          $scope.wellButtons["well_#{i}"].active = (i == config.config.well)
          if(i == config.config.well)
            $scope.index_target = i % 8
            if (i < 8) 
              $scope.index_channel = 1
            else 
              $scope.index_channel = 2

            $scope.label_channel = config.config.channel
            if i < $scope.targets.length
              if $scope.targets[i]!=null
                $scope.label_target = $scope.targets[config.config.well * dual_value + config.config.channel - 1]
              else
                $scope.label_target = ""
            else 
              $scope.label_target = ""

            if i < $scope.targets.length
              if $scope.samples[i]!=null
                $scope.label_sample = $scope.samples[i]?.name
              else
                $scope.label_sample = null
            else 
              $scope.label_sample = null

            # $scope.label_dF_dC = 
            # $scope.label_D2_dc2 = 
            wells = ['A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'B8']
            $scope.label_well = wells[i]

        if !unhighlight_event          
          if !$scope.isSampleMode
            wellScrollTop = (config.config.well * dual_value + config.config.channel - 1 + dual_value) * 36 - document.querySelector('.detail-mode-table tbody').offsetHeight
            angular.element('.detail-mode-table tbody').animate { scrollTop: wellScrollTop }, 'fast'
          else
            wellScrollTop = (config.config.well + config.config.channel - 1 + dual_value) * 36 - document.querySelector('.simple-mode-table tbody').offsetHeight
            angular.element('.simple-mode-table tbody').animate { scrollTop: wellScrollTop }, 'fast'
          
      $scope.onUnselectLine = ->
        for well_i in [0..$scope.well_data.length - 1]
          $scope.well_data[well_i].active = false
          $scope.well_data[well_i].highlight = false

        for well_i in [0..$scope.simple_well_data.length - 1]
          $scope.simple_well_data[well_i].active = false
          $scope.simple_well_data[well_i].highlight = false
          for target_index in [0..$scope.simple_well_data[well_i].targets.length - 1]
            $scope.simple_well_data[well_i].targets[target_index].selected = false


        for i in [0..15] by 1
          $scope.wellButtons["well_#{i}"].active = false

        $scope.label_target = "No Selection"
        $scope.label_well = "No Selection"
        $scope.label_channel = ""

        $scope.label_cycle = ''
        $scope.label_RFU = ''
        $scope.label_dF_dC = ''
        $scope.label_D2_dc2 = ''

        $scope.label_sample = null
        $scope.bgcolor_target = {
          'background-color':'#666666'
        }
        $scope.bgcolor_wellSample = {
          'background-color':'#666666'
        }

      $scope.$watch 'baseline_subtraction', (val) ->
        updateSeries()
        
      $scope.$watch 'channel_1', (val) ->
        updateSeries()

      $scope.$watch 'channel_2', (val) ->
        updateSeries()

      $scope.$watch 'curve_type', (type) ->
        $scope.chartConfig.axes.y.scale = type
        updateSeries()

      $scope.$watchCollection 'wellButtons', ->
        updateSeries()

      $scope.$watch ->
        $scope.$parent.chart
      , (chart) ->
        if chart is 'amplification'
          $scope.expTargets = []
          $scope.lookupTargets = []
          Experiment.getTargets($stateParams.id).then (resp_target) ->
            for i in [0...resp_target.data.length]
              $scope.expTargets[i] = resp_target.data[i].target
              $scope.lookupTargets[resp_target.data[i].target.id] = $scope.COLORS[i % $scope.COLORS.length]

            $scope.expSamples = []
            Experiment.getSamples($stateParams.id).then (response) ->
              for i in [0...response.data.length]
                $scope.expSamples[i] = response.data[i].sample

              $scope.well_targets = []
              Experiment.getWellLayout($stateParams.id).then (resp) ->
                for i in [0...resp.data.length]
                  $scope.samples[i] = if resp.data[i].samples then resp.data[i].samples[0] else null
                  if $scope.samples[i]
                    for j in [0...$scope.expSamples.length]
                      if $scope.samples[i].id == $scope.expSamples[j].id
                        $scope.samples[i].color = $scope.COLORS[j % $scope.COLORS.length]
                        break
                      else
                        $scope.samples[i].color = $scope.init_sample_color
                  if $scope.is_dual_channel
                    $scope.well_targets[2*i] = if resp.data[i].targets && resp.data[i].targets[0] then resp.data[i].targets[0]  else null
                    $scope.well_targets[2*i+1] = if resp.data[i].targets && resp.data[i].targets[1] then resp.data[i].targets[1] else null

                    if $scope.well_targets[2*i]
                      $scope.well_targets[2*i].color = if $scope.well_targets[2*i] then $scope.lookupTargets[$scope.well_targets[2*i].id] else 'transparent'
                    if $scope.well_targets[2*i+1]
                      $scope.well_targets[2*i+1].color = if $scope.well_targets[2*i+1] then $scope.lookupTargets[$scope.well_targets[2*i+1].id] else 'transparent'
                  else
                    $scope.well_targets[i] = if resp.data[i].targets && resp.data[i].targets[0] then resp.data[i].targets[0]  else null
                    if $scope.well_targets[i]
                      $scope.well_targets[i].color = if $scope.well_targets[i] then $scope.lookupTargets[$scope.well_targets[i].id] else 'transparent'

                $scope.well_data = helper.blankWellData($scope.is_dual_channel, $scope.well_targets)
                $scope.targets = helper.blankWellTargetData($scope.well_data)
                for i in [0..$scope.targets.length - 1] by 1
                  $scope.targetsSetHided[$scope.targets[i]?.id] = true  if $scope.targetsSetHided[$scope.targets[i]?.id] is undefined

                $scope.updateSamplesSet()
                $scope.updateTargetsSet()
                updateSeries()
                
                fetchFluorescenceData()

              $timeout ->
                $rootScope.$broadcast 'event:start-resize-aspect-ratio'
                $scope.showAmpliChart = true
              , 1000
        else
          $scope.showAmpliChart = false
          $scope.showStandardChart = false

      $scope.$on '$destroy', ->
        $interval.cancel(retryInterval) if retryInterval

        # store well buttons
        wellSelections = {}
        for well_i in [0..15] by 1
          wellSelections["well_#{well_i}"] = $scope.wellButtons["well_#{well_i}"].selected

        $.jStorage.set('selectedWells', wellSelections)
        $.jStorage.set('selectedExpId', $stateParams.id)

      $scope.showPlotTypeList = ->
        document.getElementById("plotTypeList").classList.toggle("show")

      $scope.showColorByList = ->
        document.getElementById("colorByList_ampli").classList.toggle("show")
      
      # $scope.targetGridTop = ->
      #   document.getElementById("curve-plot").clientHeight + 30
      $scope.targetGridTop = ->
        Math.max(document.getElementById("curve-plot").clientHeight + 30, 412 + 30)

      $scope.onChangeViewMode = ->
        $scope.isSampleMode = !$scope.isSampleMode
        $rootScope.$broadcast 'event:switch-view-mode'
        last_well_number = 0
        last_target_channel = 0
        last_target_assigned = 0

]
