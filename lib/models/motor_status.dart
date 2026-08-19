import 'dart:convert';

class MotorStatus {
  final int position; // Degrees or steps
  final int speed;    // 0-100% or RPM
  final bool running;
  final double temp;   // °C
  final double busVolt;// VDC
  final String driverStatus;
  final int batteryPercent; // %

  const MotorStatus({
    required this.position,
    required this.speed,
    required this.running,
    this.temp = 42.5,
    this.busVolt = 24.1,
    this.driverStatus = 'TMC2209 OK',
    this.batteryPercent = 0,
  });

  factory MotorStatus.fromJson(Map<String, dynamic> json) {
    return MotorStatus(
      position: (json['position'] as num?)?.toInt() ?? 0,
      speed: (json['speed'] as num?)?.toInt() ?? 0,
      running: json['running'] as bool? ?? false,
      temp: (json['temp'] as num?)?.toDouble() ?? 42.5,
      busVolt: (json['busVolt'] as num?)?.toDouble() ?? 24.1,
      driverStatus: json['driverStatus'] as String? ?? 'TMC2209 OK',
      batteryPercent: (json['battery'] as num?)?.toInt() ?? 100,
    );
  }

  factory MotorStatus.parseRawJson(String jsonStr) {
    try {
      final Map<String, dynamic> parsed = jsonDecode(jsonStr);
      return MotorStatus.fromJson(parsed);
    } catch (_) {
      return const MotorStatus(position: 0, speed: 0, running: false, batteryPercent: 0);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'speed': speed,
      'running': running,
      'temp': temp,
      'busVolt': busVolt,
      'driverStatus': driverStatus,
      'batteryPercent': batteryPercent,
    };
  }

  MotorStatus copyWith({
    int? position,
    int? speed,
    bool? running,
    double? temp,
    double? busVolt,
    String? driverStatus,
    int? batteryPercent,
  }) {
    return MotorStatus(
      position: position ?? this.position,
      speed: speed ?? this.speed,
      running: running ?? this.running,
      temp: temp ?? this.temp,
      busVolt: busVolt ?? this.busVolt,
      driverStatus: driverStatus ?? this.driverStatus,
      batteryPercent: batteryPercent ?? this.batteryPercent,
    );
  }
}
