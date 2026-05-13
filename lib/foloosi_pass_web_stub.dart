// Stub implementation for non-web platforms

import 'core/foloosi_pass_platform_interface.dart';

class FoloosiPassWebStub extends FoloosiPassPlatform {
  static void registerWith(dynamic registrar) {
    // This is a stub - web implementation is handled separately
    throw UnsupportedError('Web platform not supported on this platform');
  }
}
