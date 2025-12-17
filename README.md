Experimental parser of the `.ag-trace` files produces by AttributeGraph - private Apple framework powering SwiftUI.

Useful for debugging SwiftUI issues.

To record a trace:

* Launch SwiftUI app with `AG_DEBUG_SERVER=1` set in  environment variables.
* Set breakpoint in ``AttributeGraph`AGGraphCreateShared``
* Step into `AG::Graph::Graph()` -> `AG::Graph::Graph()::$_1::operator()() const` -> `AG::DebugServer::start`
* Override value returned by `os_variant_has_internal_diagnostics()`
* Debug Server URL will be printed in the app's console, e.g. `debug server graph://127.0.0.1:55030/?token=3067380191` 
* Connect [`DebugClient`](https://github.com/nickolas-pohilets/AGDebugKit/tree/main/Sources/DebugClient) to the Debug Server and send the following debugging commands:
    * `tracing/start`
    * `tracing/stop`
    * `tracing/sync`
* Path to the `.ag-trace` will be printed in the console of the app.
