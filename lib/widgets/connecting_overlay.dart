import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import 'svg_icons.dart';

class ConnectingOverlay extends StatelessWidget {
  final String deviceName;
  final VoidCallback onCancel;

  const ConnectingOverlay({
    super.key,
    required this.deviceName,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background.withOpacity(0.95),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top device header
                Text(
                  deviceName.toUpperCase(),
                  style: AppTheme.monoHeader(fontSize: 22, color: AppTheme.primaryAccent),
                ),
                const SizedBox(height: 32),

                // Radar circular connection dial
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
                        backgroundColor: AppTheme.cardBorder,
                      ),
                    ),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBgElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: const Center(
                        child: TechIcon(
                          type: TechIconType.bluetooth,
                          size: 48,
                          color: AppTheme.primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Connection status text matching screenshot #1
                Text(
                  "CONFIGURING PARAMETERS...",
                  style: AppTheme.monoHeader(fontSize: 14, color: AppTheme.primaryAccent),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 140,
                  child: LinearProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
                    backgroundColor: AppTheme.cardBorder,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "REQUESTING_MTU_NEGOTIATION...",
                  style: AppTheme.monoSubheader(fontSize: 11, color: const Color(0xFF8B92A0)),
                ),

                const SizedBox(height: 48),

                // Cancel connection button
                OutlinedButton.icon(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.cardBorder, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                  label: Text(
                    "CANCEL CONNECTION",
                    style: AppTheme.monoSubheader(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
