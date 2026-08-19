import 'dart:async';
import '../constants/ble_constants.dart';
import '../models/bluetooth_device_model.dart';
import '../models/motor_status.dart';
import 'bluetooth_service.dart';

class MockBluetoothService implements BluetoothService {
  final _scanResultsController = StreamController<List<BtDeviceModel>>.broadcast();
  final _isScanningController = StreamController<bool>.broadcast();
  final _connectionStateController = StreamController<DeviceConnectionState>.broadcast();
  final _statusController = StreamController<MotorStatus>.broadcast();

  bool _isScanning = false;
  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;
  Timer? _scanTimer;
  Timer? _telemetryTimer;

  // Mock State Parameters
  int _currentSpeed = 45;
  int _currentDirection = 0; // 0 = CW, 1 = CCW
  int _targetPosition = 120;
  int _currentPosition = 0;
  bool _isRunning = false;

  final BtDeviceModel _mockDevice = const BtDeviceModel(
    id: "00:1A:7D:DA:71:13",
    name: BleConstants.mockDeviceName,
    rssi: -42,
  );

  MockBluetoothService() {
    _isScanningController.add(_isScanning);
    _connectionStateController.add(_connectionState);
  }

  @override
  Stream<List<BtDeviceModel>> get scanResults => _scanResultsController.stream;

  @override
  Stream<bool> get isScanning => _isScanningController.stream;

  @override
  Stream<DeviceConnectionState> get connectionState => _connectionStateController.stream;

  @override
  Stream<MotorStatus> get statusStream => _statusController.stream;

  @override
  Future<void> startScan() async {
    _isScanning = true;
    _isScanningController.add(true);
    _scanResultsController.add([]);

    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(milliseconds: 600), () {
      if (_isScanning) {
        _scanResultsController.add([
          _mockDevice,
          const BtDeviceModel(
            id: "00:1A:7D:DA:82:F4",
            name: "ESP32_STEPPER_NODE_02",
            rssi: -78,
          ),
        ]);
      }
    });
  }

  @override
  Future<void> stopScan() async {
    _isScanning = false;
    _isScanningController.add(false);
    _scanTimer?.cancel();
  }

  @override
  Future<bool> connect(BtDeviceModel device) async {
    await stopScan();
    _connectionState = DeviceConnectionState.connecting;
    _connectionStateController.add(_connectionState);

    // Simulate ~1s connection delay
    await Future.delayed(const Duration(milliseconds: 1100));

    _connectionState = DeviceConnectionState.connected;
    _connectionStateController.add(_connectionState);

    _startTelemetryLoop();
    return true;
  }

  @override
  Future<void> disconnect() async {
    _connectionState = DeviceConnectionState.disconnecting;
    _connectionStateController.add(_connectionState);

    _telemetryTimer?.cancel();
    await Future.delayed(const Duration(milliseconds: 300));

    _connectionState = DeviceConnectionState.disconnected;
    _connectionStateController.add(_connectionState);
  }

  @override
  Future<void> setSpeed(int speedPercent) async {
    _currentSpeed = speedPercent.clamp(0, 100);
    _isRunning = _currentSpeed > 0 && (_currentPosition != _targetPosition);
  }

  @override
  Future<void> setDirection(int direction) async {
    _currentDirection = direction;
  }

  @override
  Future<void> setTargetPosition(int degrees) async {
    _targetPosition = degrees;
    _isRunning = _currentSpeed > 0;
  }

  @override
  Future<void> emergencyStop() async {
    _currentSpeed = 0;
    _isRunning = false;
    _pushStatusUpdate();
  }

  void _startTelemetryLoop() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _simulateMotorPhysics();
      _pushStatusUpdate();
    });
  }

  void _simulateMotorPhysics() {
    if (!_isRunning || _currentSpeed == 0) return;

    final int stepIncrement = ((_currentSpeed / 10).ceil()).clamp(1, 15);

    if (_currentPosition < _targetPosition) {
      _currentPosition += stepIncrement;
      if (_currentPosition >= _targetPosition) {
        _currentPosition = _targetPosition;
        _isRunning = false;
      }
    } else if (_currentPosition > _targetPosition) {
      _currentPosition -= stepIncrement;
      if (_currentPosition <= _targetPosition) {
        _currentPosition = _targetPosition;
        _isRunning = false;
      }
    } else {
      _isRunning = false;
    }
  }

  void _pushStatusUpdate() {
    if (_connectionState != DeviceConnectionState.connected) return;

    final status = MotorStatus(
      position: _currentPosition,
      speed: _currentSpeed,
      running: _isRunning,
      temp: 38.5 + (_currentSpeed * 0.2),
      busVolt: 4.8 - (_isRunning ? 0.3 : 0.0),
      driverStatus: _isRunning
          ? 'ACTIVE ${_currentDirection == 0 ? "CW" : "CCW"} (L293D)'
          : 'L293D IDLE',
    );
    _statusController.add(status);
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _telemetryTimer?.cancel();
    _scanResultsController.close();
    _isScanningController.close();
    _connectionStateController.close();
    _statusController.close();
  }
}
