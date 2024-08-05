import 'package:flutter_test/flutter_test.dart';
import 'package:suota/suota.dart';
import 'package:suota/suota_platform_interface.dart';
import 'package:suota/suota_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSuotaPlatform
    with MockPlatformInterfaceMixin
    implements SuotaPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SuotaPlatform initialPlatform = SuotaPlatform.instance;

  test('$MethodChannelSuota is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSuota>());
  });

  test('getPlatformVersion', () async {
    Suota suotaPlugin = Suota();
    MockSuotaPlatform fakePlatform = MockSuotaPlatform();
    SuotaPlatform.instance = fakePlatform;

    expect(await suotaPlugin.getPlatformVersion(), '42');
  });
}
