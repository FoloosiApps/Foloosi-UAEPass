import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foloosi_pass/foloosi_pass_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFoloosiPass platform = MethodChannelFoloosiPass();
  const MethodChannel channel = MethodChannel('foloosi_pass');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
