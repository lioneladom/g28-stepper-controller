import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/bluetooth_device_model.dart';
import '../models/motor_status.dart';
import 'bluetooth_service.dart';

class RealBluetoothService implements BluetoothService {
  final _scanController = StreamController<List<BtDeviceModel>>.broadcast();
  final _isScanningController = StreamController<bool>.broadcast();
  final _connectionStateController = StreamController<DeviceConnectionState>.broadcast();
  final _statusController = StreamController<MotorStatus>.broadcast();

  BluetoothConnection? _connection;
  StreamSubscription<BluetoothDiscoveryResult>? _discoveryStreamSubscription;
  
  List<BtDeviceModel> _discoveredDevices = [];
  bool _isScanning = false;
  
  // App state
  int _currentSpeed = 0; // %
  bool _currentForward = true;

  @override
  Stream<List<BtDeviceModel>> get scanResults => _scanController.stream;

  @override
  Stream<bool> get isScanning => _isScanningController.stream;

  @override
  Stream<DeviceConnectionState> get connectionState => _connectionStateController.stream;

  @override
  Stream<MotorStatus> get statusStream => _statusController.stream;

  RealBluetoothService() {
    _connectionStateController.add(DeviceConnectionState.disconnected);
    _isScanningController.add(false);
  }

  @override
  Future<void> startScan() async {
    if (_isScanning) return;
    
    _discoveredDevices.clear();
    _scanController.add(_discoveredDevices);
    
    _isScanning = true;
    _isScanningController.add(true);

    try {
      // Also grab already bonded devices
      List<BluetoothDevice> bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      for (var device in bonded) {
        _addDevice(device);
      }

      _discoveryStreamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
        _addDevice(r.device);
      }, onDone: () {
        _isScanning = false;
        _isScanningController.add(false);
      });
    } catch (e) {
      _isScanning = false;
      _isScanningController.add(false);
    }
  }
  
  void _addDevice(BluetoothDevice device) {
    final existingIdx = _discoveredDevices.indexWhere((d) => d.id == device.address);
    final model = BtDeviceModel(
      id: device.address,
      name: device.name ?? "Unknown Device",
      rssi: 0,
      rawDevice: device,
    );
    
    if (existingIdx >= 0) {
      _discoveredDevices[existingIdx] = model;
    } else {
      _discoveredDevices.add(model);
    }
    _scanController.add(_discoveredDevices);
  }

  @override
  Future<void> stopScan() async {
    await _discoveryStreamSubscription?.cancel();
    _isScanning = false;
    _isScanningController.add(false);
  }

  @override
  Future<String?> connect(BtDeviceModel device) async {
    await stopScan();
    _connectionStateController.add(DeviceConnectionState.connecting);

    try {
      _connection = await BluetoothConnection.toAddress(device.id);
      _connectionStateController.add(DeviceConnectionState.connected);
      
      _listenToStream();
      return null; // Success
    } catch (e) {
      _connectionStateController.add(DeviceConnectionState.disconnected);
      return e.toString();
    }
  }

  String _rxBuffer = "";

  void _listenToStream() {
    _connection?.input?.listen((Uint8List data) {
      String chunk = ascii.decode(data);
      _rxBuffer += chunk;
      
      while (_rxBuffer.contains('\n')) {
        int idx = _rxBuffer.indexOf('\n');
        String line = _rxBuffer.substring(0, idx).trim();
        _rxBuffer = _rxBuffer.substring(idx + 1);
        _parseTelemetry(line);
      }
    }).onDone(() {
      _connectionStateController.add(DeviceConnectionState.disconnected);
    });
  }

  void _parseTelemetry(String line) {
    if (line.startsWith("POS:")) {
      int pos = int.tryParse(line.substring(4)) ?? 0;
      _statusController.add(MotorStatus(
        position: pos,
        speed: _currentSpeed,
        running: _currentSpeed > 0,
      ));
    }
  }

  void _sendString(String data) {
    if (_connection != null && _connection!.isConnected) {
      _connection!.output.add(ascii.encode(data));
      _connection!.output.allSent;
    }
  }

  @override
  Future<void> disconnect() async {
    _connectionStateController.add(DeviceConnectionState.disconnecting);
    await _connection?.close();
    _connectionStateController.add(DeviceConnectionState.disconnected);
  }

  @override
  Future<void> setSpeed(int speedPercent) async {
    _currentSpeed = speedPercent;
    if (_currentSpeed == 0) {
      _sendString("<STOP>\n");
    } else {
      int rpm = (speedPercent * 80) ~/ 100; // max 80 RPM
      if (rpm == 0) rpm = 1;
      _sendString("<RUN,${_currentForward ? 'F' : 'B'},$rpm>\n");
    }
  }

  @override
  Future<void> setDirection(int direction) async {
    _currentForward = (direction == 0);
    // If currently running, update the command
    if (_currentSpeed > 0) {
      setSpeed(_currentSpeed);
    }
  }

  @override
  Future<void> setTargetPosition(int degrees) async {
    int rpm = _currentSpeed > 0 ? (_currentSpeed * 80) ~/ 100 : 40;
    if (rpm == 0) rpm = 1;
    _sendString("<GOTO,$degrees,$rpm>\n");
    _currentSpeed = (rpm * 100) ~/ 80;
  }

  @override
  Future<void> emergencyStop() async {
    _currentSpeed = 0;
    _sendString("<STOP>\n");
  }

  @override
  Future<void> rebootSystem() async {
    _sendString("<STOP>\n");
    // Arduino Uno auto-resets on DTR drop typically, but we don't have DTR control over SPP.
    // So reboot command is mostly just STOP in this context.
  }

  @override
  void dispose() {
    _scanController.close();
    _isScanningController.close();
    _connectionStateController.close();
    _statusController.close();
    _connection?.close();
  }
}
