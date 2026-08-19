class BleConstants {
  /// Target device advertised name
  static const String deviceName = "NEMA17-Controller";
  static const String mockDeviceName = "NEMA17-Controller (simulated)";

  /// Fixed GATT Service UUID
  static const String serviceUuidStr = "12345678-0000-1000-8000-00805f9b34fb";

  /// Characteristics UUIDs
  /// speed (write) — uint8, 0–100
  static const String speedCharUuidStr = "12345678-0001-1000-8000-00805f9b34fb";

  /// direction (write) — uint8, 0 = CW, 1 = CCW
  static const String directionCharUuidStr = "12345678-0002-1000-8000-00805f9b34fb";

  /// target_position (write) — int16, degrees (-1800 to +1800 or any degree angle)
  static const String targetPosCharUuidStr = "12345678-0003-1000-8000-00805f9b34fb";

  /// status (read + notify) — JSON string: {"position": int, "speed": int, "running": bool}
  static const String statusCharUuidStr = "12345678-0004-1000-8000-00805f9b34fb";
}
