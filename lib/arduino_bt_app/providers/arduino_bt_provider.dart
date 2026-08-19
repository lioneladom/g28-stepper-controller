import 'dart:async';
import 'package:flutter/material.dart';
import '../services/arduino_bt_service.dart';

class ArduinoBtProvider extends ChangeNotifier {
  final ArduinoBtService _service = ArduinoBtService();

  ArduinoConnectionState _connectionState = ArduinoConnectionState.disconnected;
  ArduinoBtDevice? _connectedDevice;
  List<ArduinoBtDevice> _scanResults = [];
  bool _isScanning = false;

  // Motor state in app
  bool _directionForward = true;
  bool _isEmergencyStopped = false;
  int _currentSpeedRpm = 40;
  int _currentAngleDegrees = 0;
  int _activeMode = 1; // 1 = Velocity Mode, 2 = Position Mode
  bool _isDraggingSlider = false;
  Timer? _debounceTimer;

  // Console Logs
  final List<String> _logs = [];

  StreamSubscription? _stateSub;
  StreamSubscription? _scanSub;
  StreamSubscription? _isScanningSub;
  StreamSubscription? _logSub;
  StreamSubscription? _telemetrySub;

  // Getters
  ArduinoConnectionState get connectionState => _connectionState;
  ArduinoBtDevice? get connectedDevice => _connectedDevice;
  List<ArduinoBtDevice> get scanResults => _scanResults;
  bool get isScanning => _isScanning;
  bool get isConnected => _connectionState == ArduinoConnectionState.connected;
  bool get directionForward => _directionForward;
  bool get isEmergencyStopped => _isEmergencyStopped;
  int get currentSpeedRpm => _currentSpeedRpm;
  int get currentAngleDegrees => _currentAngleDegrees;
  int get activeMode => _activeMode;
  bool get isDraggingSlider => _isDraggingSlider;
  List<String> get logs => List.unmodifiable(_logs);

  ArduinoBtProvider() {
    _initSubscriptions();
  }

  void _initSubscriptions() {
    _stateSub = _service.connectionState.listen((state) {
      _connectionState = state;
      if (state == ArduinoConnectionState.disconnected) {
        _connectedDevice = null;
      }
      notifyListeners();
    });

    _scanSub = _service.scanResults.listen((results) {
      _scanResults = results;
      notifyListeners();
    });

    _isScanningSub = _service.isScanning.listen((scanning) {
      _isScanning = scanning;
      notifyListeners();
    });

    _logSub = _service.logStream.listen((logEntry) {
      _logs.add(logEntry);
      if (_logs.length > 200) {
        _logs.removeAt(0); // keep log buffer reasonable
      }
      notifyListeners();
    });

    _telemetrySub = _service.telemetryStream.listen((data) {
      final speed = data['speed'] ?? 0;
      final dir = data['dir'] ?? 1;
      final stop = data['stop'] ?? 0;
      final angle = data['angle'] ?? 0;
      final mode = data['mode'] ?? _activeMode;

      if (!_isDraggingSlider) {
        _currentSpeedRpm = speed;
      }
      _directionForward = (dir == 1);
      _isEmergencyStopped = (stop == 1);
      _currentAngleDegrees = angle;
      _activeMode = mode;
      notifyListeners();
    });
  }

  Future<void> setOperatingMode(int mode) async {
    _activeMode = mode;
    notifyListeners();
    await _service.sendOperatingMode(mode);
  }

  void setIsDraggingSlider(bool dragging) {
    _isDraggingSlider = dragging;
    notifyListeners();
  }

  Future<void> startScan() async {
    await _service.startScan();
  }

  Future<void> stopScan() async {
    await _service.stopScan();
  }

  Future<bool> connect(ArduinoBtDevice device) async {
    final success = await _service.connect(device);
    if (success) {
      _connectedDevice = device;
    }
    notifyListeners();
    return success;
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    _connectedDevice = null;
    notifyListeners();
  }

  /// Send Forward command 'F'
  Future<void> setForward() async {
    _directionForward = true;
    notifyListeners();
    await _service.sendForward();
  }

  /// Send Reverse command 'R'
  Future<void> setReverse() async {
    _directionForward = false;
    notifyListeners();
    await _service.sendReverse();
  }

  /// Send Emergency Stop toggle command 'S'
  Future<void> toggleEmergencyStop() async {
    _isEmergencyStopped = !_isEmergencyStopped;
    notifyListeners();
    await _service.toggleEmergencyStop();
  }

  /// Send Speed command 'V<rpm>\n'
  void setSpeedRpm(int rpm) {
    _currentSpeedRpm = rpm;
    notifyListeners();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _service.sendSpeed(rpm);
    });
  }

  /// Send Position Angle Command 'G<degrees>\n' (High Priority)
  Future<void> sendTargetAngle(int degrees) async {
    await _service.sendTargetAngle(degrees);
  }

  /// Send Zero Tare Command 'Z\n'
  Future<void> sendZeroTare() async {
    _currentAngleDegrees = 0;
    notifyListeners();
    await _service.sendZeroTare();
  }

  /// Send custom raw command
  Future<void> sendRawCommand(String cmd) async {
    await _service.sendRawString(cmd);
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _scanSub?.cancel();
    _isScanningSub?.cancel();
    _logSub?.cancel();
    _telemetrySub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
