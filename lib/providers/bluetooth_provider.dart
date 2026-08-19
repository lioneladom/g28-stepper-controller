import 'dart:async';
import 'package:flutter/material.dart';
import '../models/bluetooth_device_model.dart';
import '../models/motor_status.dart';
import '../services/bluetooth_service.dart';
import '../services/real_bluetooth_service.dart';
import '../services/permission_service.dart';

class BluetoothProvider extends ChangeNotifier {
  late BluetoothService _bluetoothService;

  List<BtDeviceModel> _discoveredDevices = [];
  bool _isScanning = false;
  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;
  BtDeviceModel? _connectedDevice;
  MotorStatus _status = const MotorStatus(position: 0, speed: 0, running: false);

  // Debouncing for slider writes
  Timer? _speedDebounceTimer;
  int _pendingSpeed = 0;

  // Real-time log buffer for terminal widget
  final List<String> _logs = [];

  StreamSubscription? _scanSub;
  StreamSubscription? _isScanningSub;
  StreamSubscription? _connSub;
  StreamSubscription? _statusSub;

  List<BtDeviceModel> get discoveredDevices => _discoveredDevices;
  bool get isScanning => _isScanning;
  DeviceConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == DeviceConnectionState.connected;
  bool get isConnecting => _connectionState == DeviceConnectionState.connecting;
  BtDeviceModel? get connectedDevice => _connectedDevice;
  MotorStatus get status => _status;
  List<String> get logs => List.unmodifiable(_logs);

  BluetoothProvider() {
    _initService();
  }

  void logEvent(String message) {
    final now = DateTime.now();
    final timestamp = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    _logs.add("[$timestamp] $message");
    if (_logs.length > 100) {
      _logs.removeAt(0);
    }
    notifyListeners();
  }

  void _initService() {
    _bluetoothService = RealBluetoothService();
    logEvent("Initialized Bluetooth SPP Stack");
    _subscribeToServiceStreams();
  }

  void _subscribeToServiceStreams() {
    _scanSub = _bluetoothService.scanResults.listen((devices) {
      _discoveredDevices = devices;
      notifyListeners();
    });

    _isScanningSub = _bluetoothService.isScanning.listen((scanning) {
      _isScanning = scanning;
      logEvent(scanning ? "Bluetooth Scan started" : "Bluetooth Scan stopped");
      notifyListeners();
    });

    _connSub = _bluetoothService.connectionState.listen((state) {
      _connectionState = state;
      logEvent("Connection State: ${state.name.toUpperCase()}");
      if (state == DeviceConnectionState.disconnected) {
        _connectedDevice = null;
      }
      notifyListeners();
    });

    _statusSub = _bluetoothService.statusStream.listen((motorStatus) {
      _status = motorStatus;
      notifyListeners();
    });
  }

  Future<void> startScan() async {
    final hasPermissions = await PermissionService.requestBlePermissions();
    if (!hasPermissions) {
      logEvent("Error: Bluetooth permissions denied by user");
      return;
    }
    _discoveredDevices = [];
    notifyListeners();
    await _bluetoothService.startScan();
  }

  Future<void> stopScan() async {
    await _bluetoothService.stopScan();
  }

  Future<String?> connect(BtDeviceModel device) async {
    logEvent("Connecting to target: ${device.name} [${device.id}]");
    _connectedDevice = device;
    notifyListeners();

    final error = await _bluetoothService.connect(device);
    if (error == null) {
      logEvent("SPP Connection established");
    } else {
      logEvent("Failed to establish SPP connection: $error");
      _connectedDevice = null;
      notifyListeners();
    }
    return error;
  }

  Future<void> disconnect() async {
    logEvent("Disconnecting from device");
    await _bluetoothService.disconnect();
    _connectedDevice = null;
    notifyListeners();
  }

  /// Debounced speed write (~100ms debounce)
  void setSpeedDebounced(int speedPercent) {
    _pendingSpeed = speedPercent;
    _speedDebounceTimer?.cancel();
    _speedDebounceTimer = Timer(const Duration(milliseconds: 100), () async {
      logEvent("SPP Write -> Speed: $_pendingSpeed%");
      await _bluetoothService.setSpeed(_pendingSpeed);
    });
  }

  Future<void> setDirection(int direction) async {
    logEvent("SPP Write -> Direction: ${direction == 0 ? 'CW (0)' : 'CCW (1)'}");
    await _bluetoothService.setDirection(direction);
  }

  Future<void> setTargetPosition(int degrees) async {
    logEvent("SPP Write -> Target Angle: $degrees°");
    await _bluetoothService.setTargetPosition(degrees);
  }

  /// Prominent Emergency Stop — Bypasses all debounce logic!
  Future<void> emergencyStop() async {
    _speedDebounceTimer?.cancel();
    logEvent("!!! EMERGENCY STOP TRIGGERED !!! Sending immediate stop");
    await _bluetoothService.emergencyStop();
    _status = _status.copyWith(speed: 0, running: false);
    notifyListeners();
  }

  Future<void> rebootSystem() async {
    logEvent("SPP Write -> SYSTEM REBOOT (STOP)");
    await _bluetoothService.rebootSystem();
  }

  void _cancelSubscriptions() {
    _scanSub?.cancel();
    _isScanningSub?.cancel();
    _connSub?.cancel();
    _statusSub?.cancel();
  }

  @override
  void dispose() {
    _speedDebounceTimer?.cancel();
    _cancelSubscriptions();
    _bluetoothService.dispose();
    super.dispose();
  }
}
