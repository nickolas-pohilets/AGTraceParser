Experimental parser of the `.ag-trace` files produces by AttributeGraph - private Apple framework powering SwiftUI.

Useful for debugging SwiftUI issues.

To record a trace:

* Launch SwiftUI app with `AG_DEBUG_SERVER=1` set in  environment variables.
* Enable internal diagnostics for `com.apple.AttributeGraph`:
    * For long-term use, you can use [fishhook](https://github.com/facebook/fishhook) to hook `os_variant_has_internal_diagnostics`
    * For one-off hack, you can pause in debugger after it is called in `AGGraphCreateShared` -> `AG::Graph::Graph()` -> `AG::Graph::Graph()::$_1::operator()() const` -> `AG::DebugServer::start` and change return value in the register.
* Debug Server URL will be printed in the app's console, e.g. `debug server graph://127.0.0.1:55030/?token=3067380191` 
* Connect [`DebugClient`](https://github.com/nickolas-pohilets/AGDebugKit/tree/main/Sources/DebugClient) to the Debug Server and send the following debugging commands:
    1. `tracing/start`
    2. `tracing/stop`
    3. `tracing/sync`
* Path to the `.ag-trace` will be printed in the console of the app.
