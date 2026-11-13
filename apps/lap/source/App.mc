import Toybox.Application;

class LapApp extends Application.AppBase {
    var _view;

    function initialize() { AppBase.initialize(); }

    function getInitialView() {
        _view = new LapField();
        return [_view];
    }

    function onSettingsChanged() {
        if (_view != null) { _view.reloadSettings(); }
    }
}
