import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestBlePermissions() async {
    if (Platform.isAndroid) {
      final scanStatus = await Permission.bluetoothScan.request();
      final connectStatus = await Permission.bluetoothConnect.request();
      final locationStatus = await Permission.locationWhenInUse.request();

      return (scanStatus.isGranted || scanStatus.isLimited) &&
          (connectStatus.isGranted || connectStatus.isLimited) &&
          (locationStatus.isGranted || locationStatus.isLimited);
    } else if (Platform.isIOS) {
      final bluetoothStatus = await Permission.bluetooth.request();
      return bluetoothStatus.isGranted || bluetoothStatus.isLimited;
    }
    return true;
  }

  static Future<bool> checkBlePermissionsGranted() async {
    if (Platform.isAndroid) {
      final scan = await Permission.bluetoothScan.status;
      final connect = await Permission.bluetoothConnect.status;
      return scan.isGranted && connect.isGranted;
    } else if (Platform.isIOS) {
      return (await Permission.bluetooth.status).isGranted;
    }
    return true;
  }
}
