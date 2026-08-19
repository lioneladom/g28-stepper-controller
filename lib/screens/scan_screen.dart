import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/bluetooth_device_model.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/app_tab_provider.dart';
import '../widgets/svg_icons.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = context.watch<BluetoothProvider>();
    final tabProvider = context.read<AppTabProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header titles
          Center(
            child: Column(
              children: [
                const TechIcon(type: TechIconType.bluetooth, size: 48, color: AppTheme.primaryAccent),
                const SizedBox(height: 16),
                Text(
                  "Discover Devices",
                  style: AppTheme.monoHeader(fontSize: 28, color: AppTheme.textMain, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  "Find and connect to nearby projects",
                  style: AppTheme.bodyText(fontSize: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Start Scan Center Button
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                boxShadow: [
                  if (!bluetoothProvider.isScanning)
                    BoxShadow(
                      color: AppTheme.primaryAccent.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                ],
                borderRadius: BorderRadius.circular(32),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  if (bluetoothProvider.isScanning) {
                    bluetoothProvider.stopScan();
                  } else {
                    bluetoothProvider.startScan();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: bluetoothProvider.isScanning ? AppTheme.cardBgElevated : AppTheme.primaryAccent,
                  foregroundColor: bluetoothProvider.isScanning ? AppTheme.primaryAccent : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                    side: BorderSide(
                      color: bluetoothProvider.isScanning ? AppTheme.primaryAccent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                icon: Icon(
                  bluetoothProvider.isScanning ? Icons.stop_circle_outlined : Icons.radar,
                  size: 24,
                ),
                label: Text(
                  bluetoothProvider.isScanning ? "STOP SCANNING" : "START SCAN",
                  style: AppTheme.monoHeader(
                    fontSize: 14,
                    color: bluetoothProvider.isScanning ? AppTheme.primaryAccent : Colors.white,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Discovered Nodes Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Nearby Devices",
                style: AppTheme.monoHeader(fontSize: 16, color: AppTheme.textMain),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${bluetoothProvider.discoveredDevices.length}",
                  style: AppTheme.monoSubheader(fontSize: 14, color: AppTheme.primaryAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Discovered Devices List
          if (bluetoothProvider.discoveredDevices.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.bluetooth_searching, size: 48, color: AppTheme.textSecondary.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      "No devices found",
                      style: AppTheme.monoHeader(fontSize: 16, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Make sure your project is turned on",
                      style: AppTheme.bodyText(fontSize: 14, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bluetoothProvider.discoveredDevices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final device = bluetoothProvider.discoveredDevices[index];
                return _buildDeviceTile(context, device, bluetoothProvider, tabProvider);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(
    BuildContext context,
    BtDeviceModel device,
    BluetoothProvider bluetoothProvider,
    AppTabProvider tabProvider,
  ) {
    return Card(
      child: InkWell(
        onTap: () async {
          final error = await bluetoothProvider.connect(device);
          if (error == null) {
            tabProvider.navigateToControl();
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Connection failed: $error",
                    style: AppTheme.bodyText(color: Colors.white),
                  ),
                  backgroundColor: AppTheme.dangerRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.memory, color: AppTheme.primaryAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: AppTheme.monoHeader(fontSize: 16, color: AppTheme.textMain),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tap to connect",
                      style: AppTheme.bodyText(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        "${device.rssi} dBm",
                        style: AppTheme.bodyText(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.signal_cellular_alt, size: 16, color: AppTheme.textSecondary),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
