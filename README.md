# NEMA17 Controller — Mobile BLE App

An industrial cyberpunk Flutter mobile application built for Android and iOS to control an ESP32-based NEMA17 stepper motor over Bluetooth Low Energy (BLE).

---

## ⚠️ Firmware Developer Specification (FIXED UUID SCHEME)

> [!IMPORTANT]  
> The ESP32 firmware **must** be implemented to match these exact GATT Service and Characteristic UUIDs:

- **Advertised Device Name**: `"NEMA17-Controller"`
- **Service UUID**: `12345678-0000-1000-8000-00805f9b34fb`

### Characteristics Specification

| Name | UUID | Permissions | Data Format | Description |
| :--- | :--- | :--- | :--- | :--- |
| **`speed`** | `12345678-0001-1000-8000-00805f9b34fb` | `Write` | `uint8` | Motor speed percentage (0–100) |
| **`direction`** | `12345678-0002-1000-8000-00805f9b34fb` | `Write` | `uint8` | `0` = Clockwise (CW), `1` = Counter-Clockwise (CCW) |
| **`target_position`** | `12345678-0003-1000-8000-00805f9b34fb` | `Write` | `int16` (little endian) | Target position in degrees |
| **`status`** | `12345678-0004-1000-8000-00805f9b34fb` | `Read`, `Notify` | JSON string | Telemetry stream e.g.: `{"position": 120, "speed": 45, "running": true}` |

---

## 🛠️ Features & Mock BLE Mode

### Simulated BLE Mode (Enabled by default)
Because firmware development is ongoing, the application includes a full **Mock BLE Engine** (`MockBleService`) that allows complete testing and demoing without physical hardware:
- Simulated BLE scan returns `"NEMA17-Controller (simulated)"`.
- Realistic ~1s MTU negotiation and GATT discovery delay.
- 500ms continuous status telemetry stream with real-time motor physics simulation.
- Debounced GATT write updates (~100ms) with instant Emergency Stop bypass.

### Toggling Off Mock Mode for Physical Hardware
Once ESP32 hardware is flashed with matching firmware:
1. Open the **SETTINGS** tab in the app.
2. Toggle the **"Simulated BLE Mode"** switch to **OFF**.
3. The app will immediately swap to `RealBleService` powered by `flutter_blue_plus`.

Alternatively, change the default flag in `lib/providers/ble_provider.dart`:
```dart
bool _isMockMode = false; // Set false for real BLE hardware
```

---

## 📱 App Architecture

```
lib/
├── main.dart                       # App entry point & MultiProvider
├── constants/
│   ├── ble_constants.dart           # Fixed GATT UUIDs & specifications
│   └── app_theme.dart               # Industrial Dark theme tokens (Amber/Red/Slate)
├── models/
│   ├── ble_device_model.dart        # Discovered BLE node model
│   └── motor_status.dart            # Telemetry model with JSON deserializer
├── services/
│   ├── ble_service.dart             # Abstract interface for Real & Mock BLE
│   ├── mock_ble_service.dart        # Mock engine simulating GATT & motor physics
│   ├── real_ble_service.dart        # flutter_blue_plus hardware BLE implementation
│   └── permission_service.dart      # Android 12+ & iOS Bluetooth runtime permissions
├── providers/
│   ├── ble_provider.dart            # Central state & debounced GATT command dispatcher
│   └── app_tab_provider.dart        # Navigation tab controller
├── widgets/
│   ├── svg_icons.dart               # Custom vector graphics (no emojis)
│   ├── target_angle_dial.dart       # Custom painter angle gauge
│   ├── keypad_input.dart            # Tactical numeric keypad & jog step buttons
│   ├── terminal_logger.dart         # Live BLE debug log console
│   ├── status_badge.dart            # Top bar connection dot & indicator
│   └── connecting_overlay.dart      # Connecting state overlay matching inspiration UI
└── screens/
    ├── main_navigation_screen.dart  # Shell scaffold with bottom navigation bar
    ├── scan_screen.dart             # Cyber-radar scanner screen
    ├── control_screen.dart          # Telemetry, speed slider, angle keypad, Emergency Stop
    └── settings_screen.dart         # System parameters, UUID registry & mock toggle
```

---

## 🚀 Running the App

```bash
# Get dependencies
flutter pub get

# Run static analysis check
flutter analyze

# Run on connected device or emulator
flutter run
```
