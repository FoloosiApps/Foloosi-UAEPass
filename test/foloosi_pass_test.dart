import 'package:flutter_test/flutter_test.dart';
import 'package:foloosi_pass/foloosi_pass.dart';
import 'package:foloosi_pass/foloosi_pass_platform_interface.dart';
import 'package:foloosi_pass/foloosi_pass_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFoloosiPassPlatform
    with MockPlatformInterfaceMixin
    implements FoloosiPassPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FoloosiPassPlatform initialPlatform = FoloosiPassPlatform.instance;

  test('$MethodChannelFoloosiPass is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFoloosiPass>());
  });

  test('getPlatformVersion', () async {
    FoloosiPass foloosiPassPlugin = FoloosiPass();
    MockFoloosiPassPlatform fakePlatform = MockFoloosiPassPlatform();
    FoloosiPassPlatform.instance = fakePlatform;

    expect(await foloosiPassPlugin.getPlatformVersion(), '42');
  });
}
