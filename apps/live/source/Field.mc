import Toybox.Activity;
import Toybox.FitContributor;
import Toybox.Math;
import Toybox.WatchUi;

class LiveField extends WatchUi.SimpleDataField {
    var _window;
    var _vma;
    var _fit;

    function initialize() {
        SimpleDataField.initialize();
        label = "%VMA";
        _window = new SpeedWindow();
        reloadSettings();
        _fit = createField("vma_percent", 0, FitContributor.DATA_TYPE_UINT16,
            {:mesgType => FitContributor.MESG_TYPE_RECORD, :units => "%"});
        _fit.setData(65535);
    }

    function reloadSettings() {
        _vma = VmaSettings.vma();
        _window.reset();
    }

    function onTimerStop() { _window.reset(); }
    function onTimerPause() { _window.reset(); }
    function onTimerReset() { _window.reset(); }

    function compute(info) {
        if (info.timerState != Activity.TIMER_STATE_ON) {
            _window.reset();
            _fit.setData(65535);
            return "--";
        }
        var speed = _window.add(info.currentSpeed, info.timerTime);
        var value = VmaMath.percent(speed, _vma);
        // Unknown speed remains missing in FIT, rather than inventing a zero.
        // A stationary athlete does have a known zero speed.
        var recorded = info.currentSpeed == 0 ? 0 : value;
        // 0xFFFF is FIT's invalid sentinel for UINT16, not a plotted zero.
        _fit.setData(recorded == null ? 65535 : Math.round(recorded).toNumber());
        return value == null ? "--" : Math.round(value).toNumber();
    }
}
