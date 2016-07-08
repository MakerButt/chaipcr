/*
 * Chai PCR - Software platform for Open qPCR and Chai's Real-Time PCR instruments.
 * For more information visit http://www.chaibio.com
 *
 * Copyright 2016 Chai Biotechnologies Inc. <info@chaibio.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

angular.module("canvasApp").factory('objectModified', [
  'ExperimentLoader',
  'previouslySelected',
  'previouslyHoverd',
  'scrollService',
  'circleManager',
  function(ExperimentLoader, previouslySelected, previouslyHoverd, scrollService, circleManager) {

    this.init = function(C, $scope, that) {

      var me, step;
      /**************************************
          When the dragging of the object is finished
      ***************************************/
      this.canvas.on('object:modified', function(evt) {

        switch(evt.target.name) {

          case "controlCircleGroup":

            ExperimentLoader.changeTemperature($scope)
              .then(function(data) {
                console.log(data);
            });
          break;

          case "moveStep":

            var indicate = evt.target;
            step = indicate.parent;
            C.stepIndicator.endPosition = indicate.left;
            C.stepIndicator.processMovement(step, C);
            C.canvas.renderAll();
          break;

          case "moveStage":

            var stageIndicator = evt.target;
            var stage = stageIndicator.parent;
            stageIndicator.setVisible(false);
            C.stageIndicator.processMovement(stage, C, circleManager);
            C.canvas.renderAll();
          break;
        }
      });
    };
    return this;
  }
]);
