/*
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
*/
window.ChaiBioTech.ngApp

.service('SecondsDisplay', [
  '$window',
  function ($window) {
    this.getSecondsComponents = function(secs) {
      var days, hours, mins, seconds;
      secs = secs > 0 ? secs : 0;
      secs = Math.round(secs);
      mins = Math.floor(secs / 60);
      seconds = secs - mins * 60;
      hours = Math.floor(mins / 60);
      mins = mins - hours * 60;
      days = Math.floor(hours / 24);
      hours = hours - days * 24;
      return {
        days: days || 0,
        hours: hours || 0,
        mins: mins || 0,
        seconds: seconds || 0
      };
    };
    this.display1 = (function(_this) {
      return function(seconds) {
        var sec, text;
        sec = _this.getSecondsComponents(seconds);
        text = '';
        if (sec.days > 0) {
          text = text + " " + sec.days + " d";
        }
        if (sec.hours > 0) {
          text = text + " " + sec.hours + " hr";
        }
        if (sec.mins > 0) {
          text = text + " " + sec.mins + " min";
        }
        if (sec.days === 0 && sec.hours === 0 && sec.mins === 0) {
          text = text + " " + sec.seconds + " sec";
        }
        return text;
      };
    })(this);
    this.display2 = (function(_this) {
      return function(seconds) {
        var sec, text;
        sec = _this.getSecondsComponents(seconds);
        text = '';
        if (sec.days < 10) {
          sec.days = "0" + sec.days;
        }
        if (sec.hours < 10) {
          sec.hours = "0" + sec.hours;
        }
        if (sec.mins < 10) {
          sec.mins = "0" + sec.mins;
        }
        if (sec.seconds < 10) {
          sec.seconds = "0" + sec.seconds;
        }
        return "" + ((parseInt(sec.days)) > 0 ? sec.days + ':' : '') + ((parseInt(sec.hours)) > 0 || parseInt(sec.days) > 0 ? sec.hours + ':' : '') + sec.mins + ":" + sec.seconds;
      };
    })(this);
    this.display3 = (function(_this) {
      return function(seconds) {
        var text;
        seconds = _this.getSecondsComponents(seconds);
        text = '';
        if (seconds.days > 0) {
          text = text + " " + seconds.days + "d";
        }
        if (seconds.hours > 0) {
          text = text + " " + seconds.hours + "hr";
        }
        if (seconds.days === 0 && seconds.mins > 0) {
          text = text + " " + seconds.mins + "m";
        }
        if (seconds.days === 0 && seconds.hours === 0) {
          text = text + " " + seconds.seconds + "s";
        }
        return text;
      };
    })(this);

    this.display4 = (function(_this) {
      return function(seconds) {
        var sec, text;
        var hasAnd = false;
        sec = _this.getSecondsComponents(seconds);
        text = '';
        text = sec.seconds + ' seconds';
        if (sec.mins > 0) text = sec.mins + ' minutes' + (text.length > 0 ? (hasAnd? ', ': ' and ') : '' ) + text;
        if (sec.hours > 0) text = sec.hours + ' hours' + (text.length > 0 ? (hasAnd? ', ': ' and ') : '' ) + text;
        if (sec.days > 0) text = sec.days + ' days' + (text.length > 0 ? (hasAnd? ', ': ' and ') : '' ) + text;
        return text;
      };
    })(this);


  }
]);

// ---
// generated by coffee-script 1.9.2