import Toybox.Application;
import Toybox.Lang;

module VmaSettings {
    function readPositive(key, fallback) {
        var value = Application.Properties.getValue(key);
        if (value instanceof Number || value instanceof Float || value instanceof Double || value instanceof Long) {
            if (value > 0 && value <= 1000) {
                return value.toFloat();
            }
        }
        return fallback;
    }

    function vma() {
        return readPositive("vma", 15.0);
    }
}
