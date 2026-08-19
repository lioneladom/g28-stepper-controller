import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/bluetooth_service.dart';

class StatusBadge extends StatelessWidget {
  final DeviceConnectionState state;
  final String? deviceName;

  const StatusBadge({
    super.key,
    required this.state,
    this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    String statusText;

    switch (state) {
      case DeviceConnectionState.connected:
        dotColor = AppTheme.successGreen;
        statusText = "CONNECTED";
        break;
      case DeviceConnectionState.connecting:
        dotColor = AppTheme.primaryAccent;
        statusText = "CONNECTING...";
        break;
      case DeviceConnectionState.disconnecting:
        dotColor = AppTheme.primaryAccent;
        statusText = "DISCONNECTING...";
        break;
      case DeviceConnectionState.disconnected:
        dotColor = AppTheme.textSecondary;
        statusText = "DISCONNECTED";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBgElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                if (state == DeviceConnectionState.connected)
                  BoxShadow(
                    color: AppTheme.successGreen.withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            deviceName != null ? "$deviceName • $statusText" : statusText,
            style: AppTheme.monoSubheader(fontSize: 10, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
