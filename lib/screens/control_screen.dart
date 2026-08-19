import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/bluetooth_provider.dart';
import '../widgets/target_angle_dial.dart';
import '../widgets/keypad_input.dart';
import '../widgets/svg_icons.dart';
import '../widgets/motor_animation_widget.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  double _speedSliderVal = 45.0;
  int _direction = 0; // 0 = CW, 1 = CCW
  int _targetAngle = 120;

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = context.watch<BluetoothProvider>();
    final status = bluetoothProvider.status;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Battery
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Control Panel",
                    style: AppTheme.monoHeader(fontSize: 24, color: AppTheme.textMain, weight: FontWeight.bold),
                  ),
                  Text(
                    status.running ? "Motor is Active" : "Motor is Idle",
                    style: AppTheme.bodyText(
                      fontSize: 14,
                      color: status.running ? AppTheme.primaryAccent : AppTheme.textSecondary,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bluetoothProvider.isConnected ? AppTheme.successGreen.withOpacity(0.1) : AppTheme.cardBorder.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      !bluetoothProvider.isConnected ? Icons.battery_unknown : (status.batteryPercent > 20 ? Icons.battery_full : Icons.battery_alert),
                      size: 16,
                      color: !bluetoothProvider.isConnected ? AppTheme.textSecondary : (status.batteryPercent > 20 ? AppTheme.successGreen : AppTheme.dangerRed),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      !bluetoothProvider.isConnected ? "N/A" : "${status.batteryPercent}%",
                      style: AppTheme.monoSubheader(
                        fontSize: 14, 
                        color: !bluetoothProvider.isConnected ? AppTheme.textSecondary : AppTheme.successGreen, 
                        weight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Motor Animation & Live Telemetry
          Row(
            children: [
              MotorAnimationWidget(
                speed: status.speed,
                direction: _direction,
                isRunning: status.running,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildTelemetryTile("Position", "${status.position}°", Icons.rotate_right),
                    const SizedBox(height: 12),
                    _buildTelemetryTile("Speed", "${(status.speed * 0.8).round()} RPM", Icons.speed),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 32),

          // Speed Control
          Text(
            "Velocity",
            style: AppTheme.monoSubheader(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "${(_speedSliderVal * 0.8).round()} RPM",
                    style: AppTheme.monoValue(fontSize: 32, color: AppTheme.textMain),
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppTheme.primaryAccent,
                      inactiveTrackColor: AppTheme.cardBorder,
                      thumbColor: AppTheme.primaryAccent,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                      overlayColor: AppTheme.primaryAccent.withOpacity(0.2),
                      trackHeight: 8,
                    ),
                    child: Slider(
                      value: _speedSliderVal,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      onChanged: (val) {
                        setState(() {
                          _speedSliderVal = val;
                        });
                        bluetoothProvider.setSpeedDebounced(val.round());
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDirectionBtn("Clockwise", 0, _direction == 0, () {
                          setState(() => _direction = 0);
                          bluetoothProvider.setDirection(0);
                        }),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDirectionBtn("Counter-CW", 1, _direction == 1, () {
                          setState(() => _direction = 1);
                          bluetoothProvider.setDirection(1);
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Targeting Section
          Text(
            "Targeting",
            style: AppTheme.monoSubheader(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Center(
            child: TargetAngleDial(
              targetAngle: _targetAngle,
              currentAngle: status.position,
              isRunning: status.running,
              size: 200,
            ),
          ),
          const SizedBox(height: 16),
          KeypadInput(
            onTargetSubmitted: (angle) {
              setState(() => _targetAngle = angle);
              bluetoothProvider.setTargetPosition(angle);
            },
            onJogStep: (step) {
              setState(() {
                _targetAngle += step;
              });
              bluetoothProvider.setTargetPosition(_targetAngle);
            },
          ),
          const SizedBox(height: 48),

          // Emergency Stop Button
          ElevatedButton.icon(
            onPressed: () => bluetoothProvider.emergencyStop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed.withOpacity(0.1),
              foregroundColor: AppTheme.dangerRed,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: AppTheme.dangerRed.withOpacity(0.5), width: 2),
              ),
            ),
            icon: const Icon(Icons.warning_amber_rounded, size: 28),
            label: Text(
              "EMERGENCY STOP",
              style: AppTheme.monoHeader(fontSize: 18, color: AppTheme.dangerRed, weight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          // Reboot Button
          OutlinedButton.icon(
            onPressed: () => bluetoothProvider.rebootSystem(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.cardBorder, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            icon: const Icon(Icons.restart_alt),
            label: Text("REBOOT SYSTEM", style: AppTheme.monoHeader(fontSize: 14)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTelemetryTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryAccent, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.bodyText(fontSize: 12, color: AppTheme.textSecondary)),
              Text(value, style: AppTheme.monoHeader(fontSize: 18, color: AppTheme.textMain)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionBtn(String label, int dirVal, bool isSelected, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryAccent.withOpacity(0.1) : Colors.transparent,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryAccent : AppTheme.cardBorder,
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        label,
        style: AppTheme.monoHeader(
          fontSize: 14,
          color: isSelected ? AppTheme.primaryAccent : AppTheme.textSecondary,
        ),
      ),
    );
  }
}
