import Toybox.Test;
import Toybox.Math;

function closeTo(actual, expected) {
    return actual != null && actual > expected - 0.001 && actual < expected + 0.001;
}

(:test)
function conversion(logger) {
    Test.assert(closeTo(VmaMath.percent(15.0 / 3.6, 15.0), 100.0));
    Test.assert(closeTo(VmaMath.percent(3.125, 15.0), 75.0));
    Test.assert(VmaMath.percent(null, 15) == null);
    Test.assert(VmaMath.percent(3, 0) == null);
    Test.assert(VmaMath.percent(-1, 15) == null);
    Test.assert(VmaMath.percent(0, 15) == 0);
    return true;
}

(:test)
function smoothing(logger) {
    var window = new SpeedWindow();
    Test.assert(window.add(3.0, 0) == 3.0);
    Test.assert(window.add(4.0, 1000) == 3.5);
    Test.assert(window.add(5.0, 2000) == 4.0);
    Test.assert(window.add(6.0, 3000) == 5.0);
    Test.assert(window.add(9.0, 3000) == 6.0);
    Test.assert(window.add(0.0, 4000) == null);
    Test.assert(window.add(3.0, 5000) == 3.0);
    Test.assert(window.add(null, 6000) == null);
    Test.assert(window.add(6.0, 7000) == 6.0);
    Test.assert(window.add(4.0, 11000) == 4.0);
    Test.assert(window.add(2.0, 0) == 2.0);
    return true;
}

(:test)
function lapAverage(logger) {
    var lap = new LapTracker();
    Test.assert(lap.value(0.0, 0, 15) == null);
    Test.assert(closeTo(lap.value(1000.0, 240000, 15), 100));
    lap.boundary(1000.0, 240000);
    Test.assert(lap.value(1000.0, 240000, 15) == null);
    Test.assert(closeTo(lap.value(1500.0, 480000, 15), 50));
    // While paused, timerTime and distance do not advance.
    Test.assert(closeTo(lap.value(1500.0, 480000, 15), 50));
    lap.boundary(1500.0, 480000);
    Test.assert(closeTo(lap.value(2000.0, 600000, 15), 100));
    lap.reset();
    Test.assert(closeTo(lap.value(500.0, 120000, 15), 100));
    lap.boundary(2000.0, 600000);
    Test.assert(closeTo(lap.value(500.0, 120000, 15), 100));
    Test.assert(lap.value(null, 120000, 15) == null);
    return true;
}

(:test)
function paceFormatting(logger) {
    Test.assert(VmaMath.pace(15.0, 75.0).equals("5:20"));
    Test.assert(VmaMath.pace(15.0, 88.0).equals("4:33"));
    Test.assert(VmaMath.pace(12.01, 100.0).equals("5:00"));
    Test.assert(VmaMath.paceRange(15.0, 75.0, 88.0).equals("4:33-5:20"));
    Test.assert(VmaMath.paceRange(15.0, 88.0, 75.0).equals("--"));
    Test.assert(VmaMath.paceRange(0.0, 75.0, 88.0).equals("--"));
    return true;
}
