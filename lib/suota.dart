
import 'suota_platform_interface.dart';


class Suota {
  Future<String?> getPlatformVersion() {
    return SuotaPlatform.instance.getPlatformVersion();
  }
  Future<bool> installUpdate(
      String path,
      String fileName,
      String remoteId,
      SuotaProgressCallback? progressCallback,
      SuotaSuccessCallback? successCallback,
      SuotaFailureCallback? failureCallback,
      ) async {
    return await SuotaPlatform.instance.installUpdate(
      path,
      fileName,
      remoteId,
      progressCallback,
      successCallback,
      failureCallback,
    );
  }
}
