import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BtDeviceModel {
  final String id;
  final String name;
  final int rssi;
  final BluetoothDevice? rawDevice; 

  const BtDeviceModel({
    required this.id,
    required this.name,
    required this.rssi,
    this.rawDevice,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BtDeviceModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
