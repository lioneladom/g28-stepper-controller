import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/bluetooth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = context.watch<BluetoothProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            "Settings",
            style: AppTheme.monoHeader(fontSize: 28, color: AppTheme.textMain, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            "Manage your connection and project details",
            style: AppTheme.bodyText(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),

          // Connection Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bluetoothProvider.isConnected ? AppTheme.successGreen.withOpacity(0.1) : AppTheme.dangerRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      bluetoothProvider.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                      size: 32,
                      color: bluetoothProvider.isConnected ? AppTheme.successGreen : AppTheme.dangerRed,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    bluetoothProvider.isConnected ? "Connected to Project" : "Not Connected",
                    style: AppTheme.monoHeader(fontSize: 18, color: AppTheme.textMain),
                  ),
                  if (bluetoothProvider.isConnected && bluetoothProvider.connectedDevice != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      bluetoothProvider.connectedDevice!.name,
                      style: AppTheme.bodyText(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ]
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Device Information Card
          Text(
            "DEVICE INFORMATION",
            style: AppTheme.monoSubheader(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoRow(Icons.memory, "Microcontroller", "ESP32 Dev Module"),
                  const Divider(height: 32, color: AppTheme.cardBorder),
                  _buildInfoRow(Icons.system_update, "Firmware Version", "v1.2.4"),
                  const Divider(height: 32, color: AppTheme.cardBorder),
                  _buildInfoRow(Icons.speed, "GATT Engine", "BLE Native"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Motor Specs Card
          Text(
            "MOTOR SPECIFICATIONS",
            style: AppTheme.monoSubheader(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoRow(Icons.electric_bolt, "Motor", "NEMA 17 Stepper"),
                  const Divider(height: 32, color: AppTheme.cardBorder),
                  _buildInfoRow(Icons.developer_board, "Driver", "AFMotor Shield v1 (L293D)"),
                  const Divider(height: 32, color: AppTheme.cardBorder),
                  _buildInfoRow(Icons.speed, "Max Speed", "80 RPM"),
                  const Divider(height: 32, color: AppTheme.cardBorder),
                  _buildInfoRow(Icons.rotate_right, "Step Resolution", "1.8° / step (200 steps/rev)"),
                  const Divider(height: 32, color: AppTheme.cardBorder),
                  _buildInfoRow(Icons.power, "Supply Voltage", "5V (Arduino onboard)"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Check for Updates Button
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Firmware is up to date.", style: AppTheme.bodyText(color: Colors.white)),
                  backgroundColor: AppTheme.textMain,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent.withOpacity(0.1),
              foregroundColor: AppTheme.primaryAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Text(
              "CHECK FOR UPDATES",
              style: AppTheme.monoSubheader(fontSize: 14, color: AppTheme.primaryAccent, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryAccent),
        const SizedBox(width: 12),
        Text(label, style: AppTheme.bodyText(fontSize: 14, color: AppTheme.textSecondary)),
        const Spacer(),
        Text(value, style: AppTheme.monoHeader(fontSize: 14, color: AppTheme.textMain, weight: FontWeight.w500)),
      ],
    );
  }
}
