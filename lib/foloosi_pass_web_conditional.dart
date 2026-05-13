// Conditional imports to handle platform-specific implementations
export 'foloosi_pass_web_stub.dart' // Stub implementation for non-web platforms
if (dart.library.html) 'foloosi_pass_web.dart'; // Real web implementation for web platform