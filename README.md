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


## Known Environment Variables

* `AG_ASYNC_LAYOUTS`
* `AG_DEBUG_SERVER=1|3` - starts debug server, `1` - serves on localhost, `3` - serves on externally visible IP address.
* `AG_PREFETCH_LAYOUTS`
* `AG_PRINT_CYCLES`
* `AG_PRINT_LAYOUTS`
* `AG_PROFILE` - profile flags, as decimal number
* `AG_TRACE` - tracing flags, as decimal, hex or octal number and/or a comma/space separated list of keywords:
    * `enabled` - sets flag 0x01 (must be set for tracing to work at all)
    * `full` - sets flag 0x02
    * `backtrace` - sets flag 0x04
    * `prepare` - sets flag 0x08
    * `custom` - sets flag 0x10, disables most of the standard messages
    * `all` - sets flag 0x20
    Unrecorgnized keywords are treated as names of subsystems.
* `AG_TRACE_FILE` - path or file name used as a base for generating file name of a new trace file. Resulting trace path is formed by appending a counter and `.ag-trace` extension. If path is not an absolute path, it is appended to `$TMPDIR`.
* `AG_TRACE_STACK_FRAMES`
* `AG_TRAP_CYCLES`
* `AG_UNMAP_REUSABLE`
* `AG_TREE` 
