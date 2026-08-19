import '../models/bluetooth_device_model.dart';
import '../models/motor_status.dart';

enum DeviceConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
}

abstract class BluetoothService {
  /// Stream of discovered devices
  Stream<List<BtDeviceModel>> get scanResults;

  /// Stream of scan state (active/inactive)
  Stream<bool> get isScanning;

  /// Stream of connection state
  Stream<DeviceConnectionState> get connectionState;

  /// Stream of live motor telemetry status
  Stream<MotorStatus> get statusStream;

  /// Start device scan
  Future<void> startScan();

  /// Stop active scan
  Future<void> stopScan();

  /// Connect to selected device. Returns null on success, or error message on failure.
  Future<String?> connect(BtDeviceModel device);

  /// Disconnect current device
  Future<void> disconnect();

  /// Write speed (0–100 uint8 -> maps to RPM in provider and sends RUN string)
  Future<void> setSpeed(int speedPercent);

  /// Write direction (0 = CW, 1 = CCW uint8)
  Future<void> setDirection(int direction);

  /// Write target position (int16 degrees)
  Future<void> setTargetPosition(int degrees);

  /// Immediate emergency stop (bypasses debounce)
  Future<void> emergencyStop();

  /// Reboot the system
  Future<void> rebootSystem();

  /// Cleanup resources
  void dispose();
}
