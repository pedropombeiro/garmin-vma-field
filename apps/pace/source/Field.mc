import Toybox.WatchUi;

class PaceField extends WatchUi.SimpleDataField {
    var _range;

    function initialize() {
        SimpleDataField.initialize();
        reloadSettings();
    }

    function reloadSettings() {
        var low = VmaSettings.readPositive("lowPercent", 75.0);
        var high = VmaSettings.readPositive("highPercent", 88.0);
        label = low.format("%.0f") + "-" + high.format("%.0f") + "% /km";
        _range = VmaMath.paceRange(VmaSettings.vma(), low, high);
    }

    function compute(info) { return _range; }
}
