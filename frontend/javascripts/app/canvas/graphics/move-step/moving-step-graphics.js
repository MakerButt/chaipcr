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

angular.module("canvasApp").service('movingStepGraphics', [
    'Line',
    'constants',
    function(Line, constants) {
        this.offset = 41;
        // Make steg looks good just after clicking move-step, steps well spaced , and other stages moved aways making space.
        this.backupStageModel = null;

        this.initiateMoveStepGraphics = function(currentStep, C) {
            
            this.backupStageModel = angular.copy(currentStep.parentStage.model); 
            this.arrangeStepsOfStage(currentStep, C);
            this.setWidthOfStage(currentStep.parentStage);
            this.setLeftOfStage(currentStep.parentStage);
        };

        this.setWidthOfStage = function(baseStage) {
            //baseStage.setNewWidth(-60);
            baseStage.myWidth = baseStage.myWidth - (this.offset * 2);
            baseStage.stageRect.setWidth(baseStage.myWidth);
            baseStage.stageRect.setCoords();
            baseStage.roof.setWidth(baseStage.myWidth).setCoords();
            baseStage.stageGroup.setLeft(baseStage.stageGroup.left + this.offset).setCoords();
            baseStage.dots.setLeft(baseStage.dots.left + this.offset).setCoords();
        };

        this.setLeftOfStage = function(baseStage) {
            baseStage.left = baseStage.left + this.offset;
        };

        this.arrangeStepsOfStage = function(step, C) {
            
            var startingStep = step.previousStep;
            
            while(startingStep) {
                this.moveLittleRight(startingStep);
                startingStep = startingStep.previousStep;
            }
           
            startingStep = step.nextStep;
            while(startingStep) {
                this.moveLittleLeft(startingStep);
                startingStep = startingStep.nextStep;
            }
            
            C.canvas.renderAll();
        };

        this.squeezeStep = function(step, C) {
            // Should be moved, because this is not about graphics
            step.parentStage.deleteFromStage(step.index, step.ordealStatus);
            if(step.parentStage.childSteps.length === 0) {
                step.parentStage.wireStageNextAndPrevious();
                selected = (step.parentStage.previousStage) ? step.parentStage.previousStage.childSteps[step.parentStage.previousStage.childSteps.length - 1] : step.parentStage.nextStage.childSteps[0];
                step.parentStage.parent.allStageViews.splice(step.parentStage.index, 1);
                selected.parentStage.updateStageData(-1);
                C.canvas.renderAll();
            }    
        };

        this.moveLittleRight = function(step) {
            
            step.left = step.left + this.offset;
            step.moveStep(0, false);
            step.circle.moveCircleWithStep();
        };

        this.moveLittleLeft = function(step) {
            
            step.left = step.left - this.offset;
            step.moveStep(0, false);
            step.circle.moveCircleWithStep();
        };

        return this;
    }
]);