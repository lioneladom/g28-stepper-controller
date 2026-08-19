/**
 * G28 WEB BLUETOOTH API DRIVER
 * Direct BLE GATT client for ESP32 Dev Module in modern Web Browsers.
 */

const BLE_UUIDS = {
  SERVICE: '12345678-0000-1000-8000-00805f9b34fb',
  SPEED: '12345678-0001-1000-8000-00805f9b34fb',
  DIRECTION: '12345678-0002-1000-8000-00805f9b34fb',
  TARGET_POS: '12345678-0003-1000-8000-00805f9b34fb',
  STATUS: '12345678-0004-1000-8000-00805f9b34fb'
};

class WebBleService {
  constructor(callbacks = {}) {
    this.onTelemetry = callbacks.onTelemetry || (() => {});
    this.onLog = callbacks.onLog || (() => {});
    this.onStateChange = callbacks.onStateChange || (() => {});

    this.device = null;
    this.server = null;
    this.characteristics = {};
    this.isConnected = false;
  }

  isSupported() {
    return 'bluetooth' in navigator;
  }

  async connect() {
    if (!this.isSupported()) {
      this.onLog("[ERR] Web Bluetooth API is not supported in this browser. Use Chrome or Edge on Windows/Mac/Android.");
      return false;
    }

    try {
      this.onLog("[BLE] Scanning for 'NEMA17-Controller' BLE device...");
      this.device = await navigator.bluetooth.requestDevice({
        filters: [{ namePrefix: 'NEMA17' }, { namePrefix: 'G28' }],
        optionalServices: [BLE_UUIDS.SERVICE]
      });

      this.device.addEventListener('gattserverdisconnected', () => {
        this.onLog("[BLE] Device disconnected.");
        this.isConnected = false;
        this.onStateChange('disconnected');
      });

      this.onLog(`[BLE] Connecting to ${this.device.name}...`);
      this.server = await this.device.gatt.connect();

      this.onLog("[BLE] Discovering GATT Service...");
      const service = await this.server.getPrimaryService(BLE_UUIDS.SERVICE);

      this.onLog("[BLE] Discovering Characteristics...");
      this.characteristics.speed = await service.getCharacteristic(BLE_UUIDS.SPEED).catch(() => null);
      this.characteristics.direction = await service.getCharacteristic(BLE_UUIDS.DIRECTION).catch(() => null);
      this.characteristics.targetPos = await service.getCharacteristic(BLE_UUIDS.TARGET_POS).catch(() => null);
      this.characteristics.status = await service.getCharacteristic(BLE_UUIDS.STATUS).catch(() => null);

      if (this.characteristics.status) {
        await this.characteristics.status.startNotifications();
        this.characteristics.status.addEventListener('characteristicvaluechanged', (event) => {
          this.handleStatusNotification(event.target.value);
        });
        this.onLog("[BLE] Telemetry notification stream active.");
      }

      this.isConnected = true;
      this.onStateChange('connected');
      this.onLog(`[BLE] Connected successfully to ${this.device.name}!`);
      return true;
    } catch (err) {
      this.onLog(`[BLE ERR] Connection failed: ${err.message || err}`);
      this.disconnect();
      return false;
    }
  }

  handleStatusNotification(dataView) {
    try {
      const decoder = new TextDecoder('utf-8');
      const jsonStr = decoder.decode(dataView);
      const data = JSON.parse(jsonStr);

      this.onTelemetry({
        speed: data.speed || 0,
        direction: data.running ? (data.speed > 0 ? 1 : 0) : 1,
        emergencyStopped: !data.running && data.speed === 0,
        angle: data.position || 0,
        mode: 1,
        running: !!data.running
      });

      this.onLog(`[BLE RX] ${jsonStr}`);
    } catch (_) {}
  }

  async sendSpeed(rpm) {
    if (!this.characteristics.speed) return false;
    try {
      const buf = new Uint8Array([rpm]);
      await this.characteristics.speed.writeValue(buf);
      this.onLog(`[BLE TX] Speed: ${rpm} RPM`);
      return true;
    } catch (err) {
      this.onLog(`[BLE ERR] Set speed failed: ${err}`);
      return false;
    }
  }

  async sendDirection(isForward) {
    if (!this.characteristics.direction) return false;
    try {
      const buf = new Uint8Array([isForward ? 0 : 1]); // 0=CW, 1=CCW
      await this.characteristics.direction.writeValue(buf);
      this.onLog(`[BLE TX] Direction: ${isForward ? 'CW (0)' : 'CCW (1)'}`);
      return true;
    } catch (err) {
      this.onLog(`[BLE ERR] Set direction failed: ${err}`);
      return false;
    }
  }

  async sendTargetPosition(degrees) {
    if (!this.characteristics.targetPos) return false;
    try {
      const buf = new Int16Array([degrees]);
      await this.characteristics.targetPos.writeValue(buf.buffer);
      this.onLog(`[BLE TX] Target Position: ${degrees}°`);
      return true;
    } catch (err) {
      this.onLog(`[BLE ERR] Target position failed: ${err}`);
      return false;
    }
  }

  async disconnect() {
    if (this.device && this.device.gatt.connected) {
      this.device.gatt.disconnect();
    }
    this.isConnected = false;
    this.onStateChange('disconnected');
    this.onLog("[BLE] Disconnected from BLE device.");
  }
}

window.WebBleService = WebBleService;
