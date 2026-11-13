import Toybox.Activity;
import Toybox.FitContributor;
import Toybox.Math;
import Toybox.WatchUi;

class LapField extends WatchUi.SimpleDataField {
    var _tracker;
    var _vma;
    var _fit;
    var _knownLap = true;

    function initialize() {
        SimpleDataField.initialize();
        label = "Lap %VMA";
        _tracker = new LapTracker();
        reloadSettings();
        _fit = createField("lap_vma_percent", 0, FitContributor.DATA_TYPE_UINT16,
            {:mesgType => FitContributor.MESG_TYPE_LAP, :units => "%"});
        _fit.setData(65535);
        var info = Activity.getActivityInfo();
        // When added mid-activity we cannot reconstruct the current lap start.
        _knownLap = info == null || info.timerTime == null || info.timerTime == 0;
    }

    function reloadSettings() { _vma = VmaSettings.vma(); }

    function onTimerReset() {
        _tracker.reset();
        _knownLap = true;
        _fit.setData(65535);
    }

    function onTimerLap() {
        // Called AFTER the lap FIT record is written. Never reset the outgoing
        // lap value before that write. Read fresh counters for the next lap.
        var info = Activity.getActivityInfo();
        if (info != null && info.elapsedDistance != null && info.timerTime != null) {
            _tracker.boundary(info.elapsedDistance, info.timerTime);
            _knownLap = true;
        } else {
            _knownLap = false;
        }
        _fit.setData(65535);
    }

    function compute(info) {
        if (!_knownLap) {
            return "--";
        }
        var value = _tracker.value(info.elapsedDistance, info.timerTime, _vma);
        _fit.setData(value == null ? 65535 : Math.round(value).toNumber());
        return value == null ? "--" : Math.round(value).toNumber();
    }
}
