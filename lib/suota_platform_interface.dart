import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'suota_method_channel.dart';

typedef SuotaProgressCallback = void Function(double percent);
typedef SuotaSuccessCallback = void Function(
    double totalElapsedSeconds, double imageUploadElapsedSeconds);
typedef SuotaFailureCallback = void Function(int errorCode);

abstract class SuotaPlatform extends PlatformInterface {
  /// Constructs a SuotaPlatform.
  SuotaPlatform() : super(token: _token);

  static final Object _token = Object();

  static SuotaPlatform _instance = MethodChannelSuota();

  /// The default instance of [SuotaPlatform] to use.
  ///
  /// Defaults to [MethodChannelSuota].
  static SuotaPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SuotaPlatform] when
  /// they register themselves.
  static set instance(SuotaPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    return _instance.getPlatformVersion();
  }

  Future<bool> installUpdate(
      String path,
      String fileName,
      String remoteId,
      SuotaProgressCallback? progressCallback,
      SuotaSuccessCallback? successCallback,
      SuotaFailureCallback? failureCallback) {
    return _instance.installUpdate(
        path, fileName, remoteId, progressCallback, successCallback, failureCallback);
  }
}
