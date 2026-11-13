import Toybox.Activity;
import Toybox.Application;
import Toybox.Test;

class TestActivityInfo {
    var timerState = Activity.TIMER_STATE_ON;
    var currentSpeed = 3.125;
    var timerTime = 1000;
    var elapsedDistance = 0.0;
    function initialize() {}
}

(:test, :liveTest)
function liveFieldLifecycle(logger) {
    var field = Application.getApp()._view;
    Test.assert(field != null);
    field.onTimerReset();
    field.onTimerPause();
    field.onTimerStop();
    var info = Activity.getActivityInfo();
    if (info != null && info.timerState != Activity.TIMER_STATE_ON) {
        Test.assert(field.compute(info).equals("--"));
    }
    field.reloadSettings();
    var sample = new TestActivityInfo();
    Test.assert(field.compute(sample) == 75);
    sample.currentSpeed = 15.0 / 3.6;
    sample.timerTime = 2000;
    Test.assert(field.compute(sample) == 88);
    sample.timerState = Activity.TIMER_STATE_PAUSED;
    Test.assert(field.compute(sample).equals("--"));
    sample.timerState = Activity.TIMER_STATE_ON;
    sample.timerTime = 3000;
    Test.assert(field.compute(sample) == 100);
    sample.currentSpeed = 0.0;
    Test.assert(field.compute(sample).equals("--"));
    sample.currentSpeed = null;
    Test.assert(field.compute(sample).equals("--"));
    return true;
}

(:test, :lapTest)
function lapFieldLifecycle(logger) {
    var field = Application.getApp()._view;
    Test.assert(field != null);
    field.onTimerReset();
    field.onTimerLap();
    var info = Activity.getActivityInfo();
    if (info != null) { field.compute(info); }
    field.reloadSettings();
    field.onTimerReset();
    var sample = new TestActivityInfo();
    sample.elapsedDistance = 1000.0;
    sample.timerTime = 240000;
    Test.assert(field.compute(sample) == 100);
    sample.timerState = Activity.TIMER_STATE_PAUSED;
    Test.assert(field.compute(sample) == 100);
    sample.elapsedDistance = null;
    Test.assert(field.compute(sample).equals("--"));
    return true;
}

(:test, :paceTest)
function paceFieldLifecycle(logger) {
    var field = Application.getApp()._view;
    Test.assert(field != null);
    Test.assert(field.compute(null).equals("4:33-5:20"));
    field.reloadSettings();
    Test.assert(field.compute(null).equals("4:33-5:20"));
    return true;
}
