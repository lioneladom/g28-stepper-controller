import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

enum ArduinoConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
}

class ArduinoBtDevice {
  final String address;
  final String name;
  final bool isBonded;
  final BluetoothDevice rawDevice;

  ArduinoBtDevice({
    required this.address,
    required this.name,
    this.isBonded = false,
    required this.rawDevice,
  });
}

class ArduinoBtService {
  final StreamController<List<ArduinoBtDevice>> _scanController = StreamController<List<ArduinoBtDevice>>.broadcast();
  final StreamController<bool> _isScanningController = StreamController<bool>.broadcast();
  final StreamController<ArduinoConnectionState> _connectionStateController = StreamController<ArduinoConnectionState>.broadcast();
  final StreamController<String> _logController = StreamController<String>.broadcast();

  BluetoothConnection? _connection;
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySubscription;
  
  final List<ArduinoBtDevice> _discoveredDevices = [];
  bool _isScanning = false;
  ArduinoConnectionState _connectionState = ArduinoConnectionState.disconnected;

  final StreamController<Map<String, int>> _telemetryController = StreamController<Map<String, int>>.broadcast();

  Stream<List<ArduinoBtDevice>> get scanResults => _scanController.stream;
  Stream<bool> get isScanning => _isScanningController.stream;
  Stream<ArduinoConnectionState> get connectionState => _connectionStateController.stream;
  Stream<String> get logStream => _logController.stream;
  Stream<Map<String, int>> get telemetryStream => _telemetryController.stream;

  ArduinoConnectionState get currentConnectionState => _connectionState;

  ArduinoBtService() {
    _setConnectionState(ArduinoConnectionState.disconnected);
    _isScanningController.add(false);
  }

  void _setConnectionState(ArduinoConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T').last.substring(0, 8);
    _logController.add("[$timestamp] $message");
  }

  /// Start scanning for bonded and discovery devices
  Future<void> startScan() async {
    if (_isScanning) return;

    // Request permissions first
    try {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
    } catch (_) {}
    
    _discoveredDevices.clear();
    _scanController.add(_discoveredDevices);
    _isScanning = true;
    _isScanningController.add(true);
    _log("Starting Bluetooth scan...");

    try {
      // Add paired/bonded devices first
      List<BluetoothDevice> bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      for (var dev in bonded) {
        _addDevice(dev, isBonded: true);
      }

      // Start active discovery for nearby Bluetooth devices
      _discoverySubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
        _addDevice(result.device, isBonded: result.device.isBonded);
      }, onDone: () {
        _isScanning = false;
        _isScanningController.add(false);
        _log("Scan finished. Found ${_discoveredDevices.length} devices.");
      }, onError: (err) {
        _log("Scan error: $err");
        _isScanning = false;
        _isScanningController.add(false);
      });
    } catch (e) {
      _log("Error during scan initialization: $e");
      _isScanning = false;
      _isScanningController.add(false);
    }
  }

  void _addDevice(BluetoothDevice device, {bool isBonded = false}) {
    final index = _discoveredDevices.indexWhere((d) => d.address == device.address);
    final devName = (device.name != null && device.name!.trim().isNotEmpty) ? device.name! : "Bluetooth Device";
    final model = ArduinoBtDevice(
      address: device.address,
      name: devName,
      isBonded: isBonded,
      rawDevice: device,
    );

    if (index >= 0) {
      _discoveredDevices[index] = model;
    } else {
      _discoveredDevices.add(model);
    }
    _scanController.add(List.from(_discoveredDevices));
  }

  Future<void> stopScan() async {
    await _discoverySubscription?.cancel();
    _isScanning = false;
    _isScanningController.add(false);
    _log("Bluetooth scan stopped.");
  }

  /// Connect to targeted Bluetooth device (e.g. HC-05 or HC-06)
  Future<bool> connect(ArduinoBtDevice device) async {
    await stopScan();
    _setConnectionState(ArduinoConnectionState.connecting);
    _log("Connecting to ${device.name} (${device.address})...");

    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      _setConnectionState(ArduinoConnectionState.connected);
      _log("Connected successfully to ${device.name}!");
      
      _listenToIncomingData();
      return true;
    } catch (e) {
      _setConnectionState(ArduinoConnectionState.disconnected);
      _log("Connection failed: $e");
      return false;
    }
  }

  String _rxBuffer = "";

  void _listenToIncomingData() {
    _connection?.input?.listen((Uint8List data) {
      String chunk = ascii.decode(data);
      _rxBuffer += chunk;

      while (_rxBuffer.contains('>') && _rxBuffer.contains('<STATUS,')) {
        int start = _rxBuffer.indexOf('<STATUS,');
        int end = _rxBuffer.indexOf('>', start);
        if (end > start) {
          String statusPacket = _rxBuffer.substring(start + 8, end);
          _rxBuffer = _rxBuffer.substring(end + 1);
          _parseStatusPacket(statusPacket);
        } else {
          break;
        }
      }
      if (_rxBuffer.length > 500) _rxBuffer = "";
    }).onDone(() {
      _setConnectionState(ArduinoConnectionState.disconnected);
      _log("Bluetooth connection closed by remote device.");
    });
  }

  void _parseStatusPacket(String packet) {
    // packet format: "speed,dir,stop,angle,mode" e.g. "45,1,0,180,1"
    final parts = packet.split(',');
    if (parts.length >= 3) {
      int speed = int.tryParse(parts[0].trim()) ?? 0;
      int dir = int.tryParse(parts[1].trim()) ?? 1;
      int stop = int.tryParse(parts[2].trim()) ?? 0;
      int angle = (parts.length >= 4) ? (int.tryParse(parts[3].trim()) ?? 0) : 0;
      int mode = (parts.length >= 5) ? (int.tryParse(parts[4].trim()) ?? 1) : 1;

      _telemetryController.add({
        'speed': speed,
        'dir': dir,
        'stop': stop,
        'angle': angle,
        'mode': mode,
      });
    }
  }

  /// Disconnect current connection
  Future<void> disconnect() async {
    if (_connection != null) {
      _setConnectionState(ArduinoConnectionState.disconnecting);
      _log("Disconnecting...");
      await _connection?.close();
      _connection = null;
      _setConnectionState(ArduinoConnectionState.disconnected);
      _log("Disconnected.");
    }
  }

  /// Send Command 'M<1|2>\n' (1 = Velocity, 2 = Position)
  Future<bool> sendOperatingMode(int mode) async {
    return _sendCommand("M$mode\n", "SWITCH MODE: ${mode == 1 ? 'VELOCITY' : 'POSITION'}");
  }

  /// Send Command 'F' for Forward
  Future<bool> sendForward() async {
    return _sendCommand('F', "FORWARD");
  }

  /// Send Command 'R' for Reverse
  Future<bool> sendReverse() async {
    return _sendCommand('R', "REVERSE");
  }

  /// Send Command 'S' for Emergency Stop Toggle
  Future<bool> toggleEmergencyStop() async {
    return _sendCommand('S', "EMERGENCY STOP TOGGLE");
  }

  /// Send Speed Command 'V<rpm>\n' (e.g. V45)
  Future<bool> sendSpeed(int rpm) async {
    return _sendCommand("V$rpm\n", "SET SPEED: $rpm RPM");
  }

  /// Send Position Command 'G<degrees>\n' (e.g. G90)
  Future<bool> sendTargetAngle(int degrees) async {
    return _sendCommand("G$degrees\n", "GO TO ANGLE: $degrees DEG");
  }

  /// Send Zero Tare Command 'Z\n'
  Future<bool> sendZeroTare() async {
    return _sendCommand("Z\n", "ZERO TARE ORIGIN");
  }

  /// Send arbitrary single character or custom string
  Future<bool> sendRawString(String command) async {
    return _sendCommand(command, "RAW: $command");
  }

  Future<bool> _sendCommand(String cmdChar, String description) async {
    if (_connection == null || !_connection!.isConnected) {
      _log("Cannot send '$cmdChar': Bluetooth is not connected.");
      return false;
    }

    try {
      _connection!.output.add(ascii.encode(cmdChar));
      await _connection!.output.allSent;
      _log("TX -> '$cmdChar' ($description)");
      return true;
    } catch (e) {
      _log("Error sending command '$cmdChar': $e");
      return false;
    }
  }

  void dispose() {
    _scanController.close();
    _isScanningController.close();
    _connectionStateController.close();
    _logController.close();
    _telemetryController.close();
    _connection?.close();
  }
}
