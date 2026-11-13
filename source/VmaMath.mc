import Toybox.Lang;
import Toybox.Math;

module VmaMath {
    function percent(speed, vma) {
        if (speed == null || vma == null || vma <= 0 || speed < 0) {
            return null;
        }
        return speed * 360.0 / vma;
    }

    function average(distance, milliseconds, vma) {
        if (distance == null || milliseconds == null || distance < 0 || milliseconds <= 0) {
            return null;
        }
        return percent(distance * 1000.0 / milliseconds, vma);
    }

    function pace(vma, percentage) {
        if (vma <= 0 || percentage <= 0) {
            return "--";
        }
        var seconds = Math.round(360000.0 / (vma * percentage)).toNumber();
        return (seconds / 60).toNumber().format("%d") + ":" + (seconds % 60).format("%02d");
    }

    function paceRange(vma, low, high) {
        if (low <= 0 || high < low || vma <= 0) {
            return "--";
        }
        // Fastest pace first, as in Garmin's pace target ranges.
        return pace(vma, high) + "-" + pace(vma, low);
    }
}

// Keep samples by timer timestamp, not by compute-call count. Data fields can
// receive duplicate calls; callbacks can also be delayed or skip a second.
class SpeedWindow {
    var _times as Array = [];
    var _speeds as Array = [];

    function initialize() {
        reset();
    }

    function reset() {
        _times = [];
        _speeds = [];
    }

    function add(speed, time) {
        if (speed == null || time == null || speed <= 0) {
            reset();
            return null;
        }
        var size = _times.size();
        if (size > 0 && (time < _times[size - 1] || time - _times[size - 1] >= 3000)) {
            reset();
            size = 0;
        }
        while (size > 0 && time - _times[0] >= 3000) {
            _times.remove(_times[0]);
            _speeds.remove(_speeds[0]);
            size--;
        }
        if (size > 0 && time == _times[size - 1]) {
            _speeds[size - 1] = speed;
        } else {
            _times.add(time);
            _speeds.add(speed);
        }
        var total = 0.0;
        for (var i = 0; i < _speeds.size(); i++) {
            total += _speeds[i];
        }
        return total / _speeds.size();
    }
}

class LapTracker {
    var _distance = 0.0;
    var _time = 0;

    function initialize() {}

    function reset() {
        _distance = 0.0;
        _time = 0;
    }

    function boundary(distance, time) {
        if (distance != null && time != null) {
            _distance = distance;
            _time = time;
        }
    }

    function value(distance, time, vma) {
        if (distance == null || time == null) {
            return null;
        }
        if (distance < _distance || time < _time) {
            reset();
        }
        return VmaMath.average(distance - _distance, time - _time, vma);
    }
}
