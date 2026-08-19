import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/app_tab_provider.dart';
import '../widgets/status_badge.dart';
import '../widgets/connecting_overlay.dart';
import '../widgets/svg_icons.dart';
import 'scan_screen.dart';
import 'control_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabProvider = context.watch<AppTabProvider>();
    final bluetoothProvider = context.watch<BluetoothProvider>();

    final screens = const [
      ScanScreen(),
      ControlScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const TechIcon(
              type: TechIconType.stepperMotor,
              size: 24,
              color: AppTheme.primaryAccent,
            ),
            const SizedBox(width: 10),
            Text(
              bluetoothProvider.connectedDevice?.name.replaceAll(" ", "_").toUpperCase() ?? "NEMA17_CTRL_01",
              style: AppTheme.monoHeader(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        actions: [
          if (bluetoothProvider.isConnected)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: OutlinedButton(
                onPressed: () => bluetoothProvider.disconnect(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3F4450)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "DISCONNECT",
                  style: AppTheme.monoSubheader(fontSize: 10, color: const Color(0xFFA0A5B0)),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: StatusBadge(
                state: bluetoothProvider.connectionState,
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: tabProvider.currentTab,
            children: screens,
          ),
          if (bluetoothProvider.isConnecting)
            ConnectingOverlay(
              deviceName: bluetoothProvider.connectedDevice?.name ?? "NEMA17-Controller",
              onCancel: () => bluetoothProvider.disconnect(),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardBg,
          border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: tabProvider.currentTab,
          onTap: (index) => tabProvider.setTab(index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryAccent,
          unselectedItemColor: const Color(0xFF6C727F),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: TechIcon(type: TechIconType.radarScan, size: 20, color: Color(0xFF6C727F)),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: TechIcon(type: TechIconType.radarScan, size: 20, color: AppTheme.primaryAccent),
              ),
              label: "SCAN",
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: TechIcon(type: TechIconType.controlSliders, size: 20, color: Color(0xFF6C727F)),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: TechIcon(type: TechIconType.controlSliders, size: 20, color: AppTheme.primaryAccent),
              ),
              label: "CONTROL",
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: TechIcon(type: TechIconType.settings, size: 20, color: Color(0xFF6C727F)),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: TechIcon(type: TechIconType.settings, size: 20, color: AppTheme.primaryAccent),
              ),
              label: "SETTINGS",
            ),
          ],
        ),
      ),
    );
  }
}
