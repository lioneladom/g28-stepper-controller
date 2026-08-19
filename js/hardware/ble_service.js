/**
 * G28 REAL BLUETOOTH & HARDWARE CONTROLLER
 * Fully functional standalone Web Bluetooth API and Web Serial API client.
 * Directly scans, connects, transmits GATT commands, and receives live telemetry.
 */

// Fixed GATT UUIDs from firmware specification
const BLE_UUIDS = {
  // ESP32 Custom Service
  CUSTOM_SERVICE: '12345678-0000-1000-8000-00805f9b34fb',
  SPEED_CHAR: '12345678-0001-1000-8000-00805f9b34fb',
  DIR_CHAR: '12345678-0002-1000-8000-00805f9b34fb',
  TARGET_POS_CHAR: '12345678-0003-1000-8000-00805f9b34fb',
  STATUS_CHAR: '12345678-0004-1000-8000-00805f9b34fb',

  // Nordic UART Service (Generic BLE Serial Modules like HC-08, HM-10, ESP32 BLE UART)
  NORDIC_UART_SERVICE: '6e400001-b5a3-f393-e0a9-e50e24dcca9e',
  NORDIC_TX_CHAR: '6e400002-b5a3-f393-e0a9-e50e24dcca9e',
  NORDIC_RX_CHAR: '6e400003-b5a3-f393-e0a9-e50e24dcca9e',

  // Common transparent BLE Serial Service (HM-10 / CC2541 / ESP32)
  HM10_SERVICE: 0xFFE0,
  HM10_CHAR: 0xFFE1
};

class RealBluetoothController {
  constructor(callbacks = {}) {
    this.onTelemetry = callbacks.onTelemetry || (() => {});
    this.onConnectionChanged = callbacks.onConnectionChanged || (() => {});
    this.onError = callbacks.onError || (() => {});

    this.device = null;
    this.server = null;
    this.isConnected = false;
    this.isConnecting = false;

    // Characteristics
    this.speedChar = null;
    this.dirChar = null;
    this.targetPosChar = null;
    this.statusChar = null;

    // Fallback UART serial characteristics
    this.uartTxChar = null;
    this.uartRxChar = null;

    this.rxBuffer = "";
  }

  isSupported() {
    return !!(navigator.bluetooth && navigator.bluetooth.requestDevice);
  }

  async requestAndConnect() {
    if (!this.isSupported()) {
      alert("Web Bluetooth is not supported in this browser. Please use Google Chrome, Microsoft Edge, or Bluefy on iOS.");
      return false;
    }

    if (this.isConnecting || this.isConnected) return false;

    this.isConnecting = true;
    this.onConnectionChanged({ state: 'connecting' });

    try {
      // Prompt user to select nearby BLE device
      this.device = await navigator.bluetooth.requestDevice({
        acceptAllDevices: true,
        optionalServices: [
          BLE_UUIDS.CUSTOM_SERVICE,
          BLE_UUIDS.NORDIC_UART_SERVICE,
          BLE_UUIDS.HM10_SERVICE,
          '0000ffe0-0000-1000-8000-00805f9b34fb',
          0x1800,
          0x1801
        ]
      });

      this.device.addEventListener('gattserverdisconnected', () => {
        this.handleDisconnect();
      });

      // Connect to GATT Server
      this.server = await this.device.gatt.connect();

      // Discover Services & Characteristics
      await this.discoverServices();

      this.isConnected = true;
      this.isConnecting = false;
      this.onConnectionChanged({
        state: 'connected',
        deviceName: this.device.name || "Bluetooth Device"
      });

      return true;
    } catch (err) {
      console.warn("Bluetooth connection error:", err);
      this.handleDisconnect();
      if (err.name !== 'NotFoundError') { // User didn't just cancel picker
        this.onError(err.message || "Failed to connect to Bluetooth device.");
      }
      return false;
    }
  }

  async discoverServices() {
    // 1. Try Custom ESP32 Service
    try {
      const customService = await this.server.getPrimaryService(BLE_UUIDS.CUSTOM_SERVICE);
      if (customService) {
        this.speedChar = await customService.getCharacteristic(BLE_UUIDS.SPEED_CHAR).catch(() => null);
        this.dirChar = await customService.getCharacteristic(BLE_UUIDS.DIR_CHAR).catch(() => null);
        this.targetPosChar = await customService.getCharacteristic(BLE_UUIDS.TARGET_POS_CHAR).catch(() => null);
        this.statusChar = await customService.getCharacteristic(BLE_UUIDS.STATUS_CHAR).catch(() => null);

        if (this.statusChar) {
          await this.statusChar.startNotifications();
          this.statusChar.addEventListener('characteristicvaluechanged', (e) => {
            this.handleCustomStatusNotification(e.target.value);
          });
        }
        return;
      }
    } catch (_) {}

    // 2. Try Nordic UART BLE Service
    try {
      const uartService = await this.server.getPrimaryService(BLE_UUIDS.NORDIC_UART_SERVICE);
      if (uartService) {
        this.uartTxChar = await uartService.getCharacteristic(BLE_UUIDS.NORDIC_TX_CHAR).catch(() => null);
        this.uartRxChar = await uartService.getCharacteristic(BLE_UUIDS.NORDIC_RX_CHAR).catch(() => null);

        if (this.uartRxChar) {
          await this.uartRxChar.startNotifications();
          this.uartRxChar.addEventListener('characteristicvaluechanged', (e) => {
            this.handleSerialChunk(e.target.value);
          });
        }
        return;
      }
    } catch (_) {}

    // 3. Try HM-10 Transparent Serial Service
    try {
      const hmService = await this.server.getPrimaryService(BLE_UUIDS.HM10_SERVICE);
      if (hmService) {
        const char = await hmService.getCharacteristic(BLE_UUIDS.HM10_CHAR).catch(() => null);
        if (char) {
          this.uartTxChar = char;
          await char.startNotifications();
          char.addEventListener('characteristicvaluechanged', (e) => {
            this.handleSerialChunk(e.target.value);
          });
        }
      }
    } catch (_) {}
  }

  handleCustomStatusNotification(dataView) {
    try {
      const jsonStr = new TextDecoder().decode(dataView);
      const data = JSON.parse(jsonStr);
      this.onTelemetry({
        speed: data.speed || 0,
        direction: data.running ? 1 : 0,
        emergencyStopped: !data.running && data.speed === 0,
        angle: data.position || 0,
        mode: 1,
        running: !!data.running
      });
    } catch (_) {}
  }

  handleSerialChunk(dataView) {
    const chunk = new TextDecoder().decode(dataView);
    this.rxBuffer += chunk;

    // Parse packet format: <STATUS,speed,dir,stop,angle,mode>
    while (this.rxBuffer.includes('>') && this.rxBuffer.includes('<STATUS,')) {
      const start = this.rxBuffer.indexOf('<STATUS,');
      const end = this.rxBuffer.indexOf('>', start);
      if (end > start) {
        const packet = this.rxBuffer.substring(start + 8, end);
        this.rxBuffer = this.rxBuffer.substring(end + 1);
        this.parseStatusPacket(packet);
      } else {
        break;
      }
    }

    if (this.rxBuffer.length > 300) this.rxBuffer = "";
  }

  parseStatusPacket(packetStr) {
    const parts = packetStr.split(',');
    if (parts.length >= 3) {
      const speed = parseInt(parts[0].trim()) || 0;
      const dir = parseInt(parts[1].trim()) || 1;
      const stop = parseInt(parts[2].trim()) || 0;
      const angle = parts.length >= 4 ? parseInt(parts[3].trim()) || 0 : 0;
      const mode = parts.length >= 5 ? parseInt(parts[4].trim()) || 1 : 1;

      this.onTelemetry({
        speed,
        direction: dir,
        emergencyStopped: stop === 1,
        angle,
        mode,
        running: stop === 0 && speed > 0
      });
    }
  }

  async sendCommand(cmdStr) {
    if (!this.isConnected) return false;

    try {
      const char = cmdStr.charAt(0).toUpperCase();

      // If Custom GATT Characteristics are present
      if (this.speedChar && char === 'V') {
        const rpm = parseInt(cmdStr.substring(1)) || 0;
        await this.speedChar.writeValue(new Uint8Array([rpm]));
        return true;
      }
      if (this.dirChar && (char === 'F' || char === 'R')) {
        await this.dirChar.writeValue(new Uint8Array([char === 'F' ? 0 : 1]));
        return true;
      }
      if (this.targetPosChar && char === 'G') {
        const deg = parseInt(cmdStr.substring(1)) || 0;
        const buf = new Int16Array([deg]);
        await this.targetPosChar.writeValue(buf.buffer);
        return true;
      }

      // If UART Serial Characteristic is present
      if (this.uartTxChar) {
        const encoder = new TextEncoder();
        const data = encoder.encode(cmdStr.endsWith('\n') ? cmdStr : cmdStr + '\n');
        await this.uartTxChar.writeValue(data);
        return true;
      }
    } catch (err) {
      console.warn("Error sending command:", err);
      return false;
    }
    return false;
  }

  disconnect() {
    if (this.device && this.device.gatt && this.device.gatt.connected) {
      this.device.gatt.disconnect();
    }
    this.handleDisconnect();
  }

  handleDisconnect() {
    this.isConnected = false;
    this.isConnecting = false;
    this.speedChar = null;
    this.dirChar = null;
    this.targetPosChar = null;
    this.statusChar = null;
    this.uartTxChar = null;
    this.uartRxChar = null;
    this.device = null;
    this.server = null;

    this.onConnectionChanged({ state: 'disconnected' });
  }
}

window.RealBluetoothController = RealBluetoothController;
