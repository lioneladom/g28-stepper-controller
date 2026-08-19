import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/arduino_bt_provider.dart';
import '../services/arduino_bt_service.dart';
import '../theme/arduino_bt_theme.dart';
import '../widgets/stepper_motor_widget.dart';

class MainArduinoBtScreen extends StatefulWidget {
  const MainArduinoBtScreen({super.key});

  @override
  State<MainArduinoBtScreen> createState() => _MainArduinoBtScreenState();
}

class _MainArduinoBtScreenState extends State<MainArduinoBtScreen> {
  final TextEditingController _angleInputController = TextEditingController(text: "90");

  @override
  void dispose() {
    _angleInputController.dispose();
    super.dispose();
  }

  void _openDeviceScanModal(BuildContext context) {
    final provider = context.read<ArduinoBtProvider>();
    provider.startScan();

    showModalBottomSheet(
      context: context,
      backgroundColor: ArduinoBtTheme.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Consumer<ArduinoBtProvider>(
          builder: (context, btProvider, child) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Bluetooth Devices",
                        style: ArduinoBtTheme.headerStyle(fontSize: 18),
                      ),
                      IconButton(
                        icon: Icon(
                          btProvider.isScanning ? Icons.stop_circle : Icons.refresh,
                          color: ArduinoBtTheme.primaryCyan,
                        ),
                        onPressed: () {
                          if (btProvider.isScanning) {
                            btProvider.stopScan();
                          } else {
                            btProvider.startScan();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select your device below:",
                    style: ArduinoBtTheme.bodyStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  if (btProvider.isScanning)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(
                        backgroundColor: ArduinoBtTheme.cardBorder,
                        color: ArduinoBtTheme.primaryCyan,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: btProvider.scanResults.isEmpty
                        ? Center(
                            child: Text(
                              btProvider.isScanning ? "Scanning..." : "No Bluetooth devices found.",
                              style: ArduinoBtTheme.bodyStyle(),
                            ),
                          )
                        : ListView.separated(
                            itemCount: btProvider.scanResults.length,
                            separatorBuilder: (_, _) => const Divider(color: ArduinoBtTheme.cardBorder, height: 1),
                            itemBuilder: (ctx, idx) {
                              final device = btProvider.scanResults[idx];
                              final isCurrent = btProvider.connectedDevice?.address == device.address;

                              return ListTile(
                                leading: Icon(
                                  device.isBonded ? Icons.bluetooth_connected : Icons.bluetooth,
                                  color: isCurrent ? ArduinoBtTheme.successGreen : ArduinoBtTheme.primaryCyan,
                                ),
                                title: Text(
                                  device.name,
                                  style: ArduinoBtTheme.monoStyle(
                                    fontSize: 14,
                                    color: isCurrent ? ArduinoBtTheme.successGreen : ArduinoBtTheme.textMain,
                                  ),
                                ),
                                subtitle: Text(
                                  "${device.address} ${device.isBonded ? '(Paired)' : ''}",
                                  style: ArduinoBtTheme.bodyStyle(fontSize: 12),
                                ),
                                trailing: isCurrent
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: ArduinoBtTheme.successGreen.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          "Connected",
                                          style: ArduinoBtTheme.monoStyle(fontSize: 11, color: ArduinoBtTheme.successGreen),
                                        ),
                                      )
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: ArduinoBtTheme.primaryCyan.withOpacity(0.15),
                                          foregroundColor: ArduinoBtTheme.primaryCyan,
                                          elevation: 0,
                                        ),
                                        onPressed: () async {
                                          Navigator.pop(modalContext);
                                          await btProvider.connect(device);
                                        },
                                        child: const Text("Connect"),
                                      ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final btProvider = context.watch<ArduinoBtProvider>();

    return Scaffold(
      backgroundColor: ArduinoBtTheme.bgDark,
      appBar: AppBar(
        title: Text("G28 STEPPER CONTROLLER", style: ArduinoBtTheme.headerStyle(fontSize: 16)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Connection Status Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: _buildConnectionBar(context, btProvider),
            ),

            // Mode Switching Segmented Navigation Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: ArduinoBtTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ArduinoBtTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => btProvider.setOperatingMode(1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: btProvider.activeMode == 1 ? ArduinoBtTheme.primaryCyan.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                            border: btProvider.activeMode == 1 ? Border.all(color: ArduinoBtTheme.primaryCyan, width: 2) : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.speed, size: 18, color: btProvider.activeMode == 1 ? ArduinoBtTheme.primaryCyan : ArduinoBtTheme.textDim),
                              const SizedBox(width: 8),
                              Text(
                                "VELOCITY MODE",
                                style: ArduinoBtTheme.headerStyle(
                                  fontSize: 12,
                                  color: btProvider.activeMode == 1 ? ArduinoBtTheme.primaryCyan : ArduinoBtTheme.textDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => btProvider.setOperatingMode(2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: btProvider.activeMode == 2 ? ArduinoBtTheme.warningYellow.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                            border: btProvider.activeMode == 2 ? Border.all(color: ArduinoBtTheme.warningYellow, width: 2) : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.explore_outlined, size: 18, color: btProvider.activeMode == 2 ? ArduinoBtTheme.warningYellow : ArduinoBtTheme.textDim),
                              const SizedBox(width: 8),
                              Text(
                                "ANGLE GO MODE",
                                style: ArduinoBtTheme.headerStyle(
                                  fontSize: 12,
                                  color: btProvider.activeMode == 2 ? ArduinoBtTheme.warningYellow : ArduinoBtTheme.textDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Active Page Body View
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Emergency Alert Banner (when active)
                    if (btProvider.isEmergencyStopped) ...[
                      _buildEmergencyBanner(),
                      const SizedBox(height: 16),
                    ],

                    // Motor Visualizer Display
                    Center(
                      child: StepperMotorWidget(
                        isRunning: btProvider.isConnected && !btProvider.isEmergencyStopped,
                        isForward: btProvider.directionForward,
                        isEmergencyStopped: btProvider.isEmergencyStopped,
                        size: 190,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Render Mode Specific View Page
                    if (btProvider.activeMode == 1)
                      _buildVelocityModePage(context, btProvider)
                    else
                      _buildAnglePositionModePage(context, btProvider),

                    const SizedBox(height: 24),

                    // Emergency Stop Hero Button (Always accessible)
                    _buildEmergencyStopButton(context, btProvider),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PAGE 1: CONTINUOUS VELOCITY CONTROLLER VIEW
  Widget _buildVelocityModePage(BuildContext context, ArduinoBtProvider btProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status Cards
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                label: "MOTOR SPEED",
                value: btProvider.isEmergencyStopped ? "0 RPM" : "${btProvider.currentSpeedRpm} RPM",
                subtext: "App & Potentiometer",
                icon: Icons.speed,
                accentColor: ArduinoBtTheme.primaryCyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                label: "DIRECTION",
                value: btProvider.directionForward ? "FORWARD" : "REVERSE",
                subtext: btProvider.directionForward ? "Command: 'F'" : "Command: 'R'",
                icon: btProvider.directionForward ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                accentColor: btProvider.directionForward ? ArduinoBtTheme.primaryCyan : ArduinoBtTheme.accentPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Velocity Speed Control Slider
        Text("SPEED SLIDER CONTROL", style: ArduinoBtTheme.monoStyle(fontSize: 12, color: ArduinoBtTheme.textDim)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Target Speed", style: ArduinoBtTheme.bodyStyle(fontSize: 13)),
                    Text(
                      "${btProvider.isEmergencyStopped ? 0 : btProvider.currentSpeedRpm} RPM",
                      style: ArduinoBtTheme.headerStyle(fontSize: 18, color: ArduinoBtTheme.primaryCyan),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: ArduinoBtTheme.primaryCyan,
                    inactiveTrackColor: ArduinoBtTheme.cardBorder,
                    thumbColor: ArduinoBtTheme.primaryCyan,
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: btProvider.currentSpeedRpm.toDouble().clamp(0, 80),
                    min: 0,
                    max: 80,
                    divisions: 80,
                    onChangeStart: (_) => btProvider.setIsDraggingSlider(true),
                    onChangeEnd: (_) => btProvider.setIsDraggingSlider(false),
                    onChanged: btProvider.isEmergencyStopped
                        ? null
                        : (val) {
                            btProvider.setSpeedRpm(val.round());
                          },
                  ),
                ),
                Text(
                  "Sends speed command ('V<rpm>') to Arduino",
                  style: ArduinoBtTheme.bodyStyle(fontSize: 11, color: ArduinoBtTheme.textDim),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Direction Control Buttons
        Text("DIRECTION CONTROLS", style: ArduinoBtTheme.monoStyle(fontSize: 12, color: ArduinoBtTheme.textDim)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildDirectionButton(
                context: context,
                label: "FORWARD",
                cmdChar: "F",
                isSelected: btProvider.directionForward && !btProvider.isEmergencyStopped,
                accentColor: ArduinoBtTheme.primaryCyan,
                icon: Icons.fast_forward_rounded,
                onPressed: () => btProvider.setForward(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDirectionButton(
                context: context,
                label: "REVERSE",
                cmdChar: "R",
                isSelected: !btProvider.directionForward && !btProvider.isEmergencyStopped,
                accentColor: ArduinoBtTheme.accentPurple,
                icon: Icons.fast_rewind_rounded,
                onPressed: () => btProvider.setReverse(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // PAGE 2: ANGLE POSITION CONTROLLER VIEW
  Widget _buildAnglePositionModePage(BuildContext context, ArduinoBtProvider btProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Angle Position Summary Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.explore_outlined, size: 18, color: ArduinoBtTheme.warningYellow),
                        const SizedBox(width: 8),
                        Text("CURRENT ANGLE", style: ArduinoBtTheme.monoStyle(fontSize: 11, color: ArduinoBtTheme.textDim)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${btProvider.currentAngleDegrees}°",
                      style: ArduinoBtTheme.headerStyle(fontSize: 26, color: ArduinoBtTheme.warningYellow),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ArduinoBtTheme.warningYellow,
                    side: const BorderSide(color: ArduinoBtTheme.warningYellow),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: () => btProvider.sendZeroTare(),
                  icon: const Icon(Icons.center_focus_strong, size: 18),
                  label: Text("ZERO TARE (0°)", style: ArduinoBtTheme.monoStyle(fontSize: 12, color: ArduinoBtTheme.warningYellow)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Angle Move Controls Card
        Text("TARGET ANGLE POSITIONING", style: ArduinoBtTheme.monoStyle(fontSize: 12, color: ArduinoBtTheme.warningYellow)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Select or enter relative target movement:", style: ArduinoBtTheme.bodyStyle(fontSize: 12, color: ArduinoBtTheme.textMuted)),
                const SizedBox(height: 14),

                // Preset Angle Quick Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip("+15°", 15, btProvider),
                      _buildPresetChip("+45°", 45, btProvider),
                      _buildPresetChip("+90°", 90, btProvider),
                      _buildPresetChip("+180°", 180, btProvider),
                      _buildPresetChip("-45°", -45, btProvider),
                      _buildPresetChip("-90°", -90, btProvider),
                      _buildPresetChip("-180°", -180, btProvider),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _angleInputController,
                        keyboardType: const TextInputType.numberWithOptions(signed: true),
                        style: ArduinoBtTheme.monoStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: "Target Angle (e.g. 90, -45)",
                          labelStyle: ArduinoBtTheme.bodyStyle(fontSize: 12, color: ArduinoBtTheme.textMuted),
                          suffixText: "deg",
                          isDense: true,
                          filled: true,
                          fillColor: ArduinoBtTheme.bgDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: ArduinoBtTheme.cardBorder),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArduinoBtTheme.warningYellow,
                        foregroundColor: ArduinoBtTheme.bgDark,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: btProvider.isEmergencyStopped
                          ? null
                          : () {
                              final deg = int.tryParse(_angleInputController.text.trim());
                              if (deg != null) {
                                btProvider.sendTargetAngle(deg);
                              }
                            },
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: Text("MOVE GO", style: ArduinoBtTheme.headerStyle(fontSize: 15, color: ArduinoBtTheme.bgDark)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, int deg, ArduinoBtProvider btProvider) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        backgroundColor: ArduinoBtTheme.bgDark,
        side: const BorderSide(color: ArduinoBtTheme.cardBorder),
        label: Text(label, style: ArduinoBtTheme.monoStyle(fontSize: 12, color: ArduinoBtTheme.warningYellow)),
        onPressed: btProvider.isEmergencyStopped
            ? null
            : () {
                _angleInputController.text = deg.toString();
                btProvider.sendTargetAngle(deg);
              },
      ),
    );
  }

  Widget _buildConnectionBar(BuildContext context, ArduinoBtProvider btProvider) {
    final state = btProvider.connectionState;
    Color statusColor;
    String statusText;

    switch (state) {
      case ArduinoConnectionState.connected:
        statusColor = ArduinoBtTheme.successGreen;
        statusText = "Connected: ${btProvider.connectedDevice?.name ?? 'Device'}";
        break;
      case ArduinoConnectionState.connecting:
        statusColor = ArduinoBtTheme.warningYellow;
        statusText = "Connecting...";
        break;
      case ArduinoConnectionState.disconnecting:
        statusColor = ArduinoBtTheme.warningYellow;
        statusText = "Disconnecting...";
        break;
      case ArduinoConnectionState.disconnected:
        statusColor = ArduinoBtTheme.textDim;
        statusText = "Disconnected";
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
                boxShadow: [
                  BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 8, spreadRadius: 1),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                statusText,
                style: ArduinoBtTheme.monoStyle(fontSize: 13, color: ArduinoBtTheme.textMain),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (btProvider.isConnected)
              TextButton(
                onPressed: () => btProvider.disconnect(),
                child: Text("Disconnect", style: ArduinoBtTheme.monoStyle(fontSize: 12, color: ArduinoBtTheme.dangerRed)),
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArduinoBtTheme.primaryCyan.withOpacity(0.15),
                  foregroundColor: ArduinoBtTheme.primaryCyan,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openDeviceScanModal(context),
                icon: const Icon(Icons.bluetooth_searching, size: 16),
                label: Text("Pair BT", style: ArduinoBtTheme.monoStyle(fontSize: 12, color: ArduinoBtTheme.primaryCyan)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ArduinoBtTheme.dangerRed.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArduinoBtTheme.dangerRed, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: ArduinoBtTheme.dangerRed, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "EMERGENCY STOP ACTIVE",
                  style: ArduinoBtTheme.headerStyle(fontSize: 14, color: ArduinoBtTheme.dangerRed),
                ),
                Text(
                  "Motor outputs released (cmd 'S'). Press toggle to resume.",
                  style: ArduinoBtTheme.bodyStyle(fontSize: 11, color: ArduinoBtTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Text(label, style: ArduinoBtTheme.monoStyle(fontSize: 11, color: ArduinoBtTheme.textDim)),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: ArduinoBtTheme.headerStyle(fontSize: 16, color: accentColor)),
            const SizedBox(height: 4),
            Text(subtext, style: ArduinoBtTheme.bodyStyle(fontSize: 11, color: ArduinoBtTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionButton({
    required BuildContext context,
    required String label,
    required String cmdChar,
    required bool isSelected,
    required Color accentColor,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? accentColor.withOpacity(0.15) : Colors.transparent,
        side: BorderSide(
          color: isSelected ? accentColor : ArduinoBtTheme.cardBorder,
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        children: [
          Icon(icon, color: isSelected ? accentColor : ArduinoBtTheme.textDim, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: ArduinoBtTheme.headerStyle(
              fontSize: 14,
              color: isSelected ? accentColor : ArduinoBtTheme.textDim,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Send '$cmdChar'",
            style: ArduinoBtTheme.monoStyle(fontSize: 10, color: ArduinoBtTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyStopButton(BuildContext context, ArduinoBtProvider btProvider) {
    final isStopped = btProvider.isEmergencyStopped;

    return ElevatedButton.icon(
      onPressed: () => btProvider.toggleEmergencyStop(),
      style: ElevatedButton.styleFrom(
        backgroundColor: isStopped ? ArduinoBtTheme.dangerRed : ArduinoBtTheme.dangerRed.withOpacity(0.15),
        foregroundColor: isStopped ? Colors.white : ArduinoBtTheme.dangerRed,
        padding: const EdgeInsets.symmetric(vertical: 20),
        elevation: isStopped ? 8 : 0,
        shadowColor: ArduinoBtTheme.dangerRed.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: ArduinoBtTheme.dangerRed, width: 2),
        ),
      ),
      icon: const Icon(Icons.stop_circle_rounded, size: 30),
      label: Text(
        isStopped ? "RESUME OPERATION (SEND 'S')" : "EMERGENCY STOP (SEND 'S')",
        style: ArduinoBtTheme.headerStyle(
          fontSize: 15,
          color: isStopped ? Colors.white : ArduinoBtTheme.dangerRed,
        ),
      ),
    );
  }
}
