import Toybox.Application;

class PaceApp extends Application.AppBase {
    var _view;

    function initialize() { AppBase.initialize(); }

    function getInitialView() {
        _view = new PaceField();
        return [_view];
    }

    function onSettingsChanged() {
        if (_view != null) { _view.reloadSettings(); }
    }
}
