import Toybox.Application;
import Toybox.WatchUi;

class LiveApp extends Application.AppBase {
    var _view;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        _view = new LiveField();
        return [_view];
    }

    function onSettingsChanged() {
        if (_view != null) {
            _view.reloadSettings();
        }
    }
}
