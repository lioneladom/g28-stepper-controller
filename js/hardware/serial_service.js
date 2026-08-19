/**
 * G28 WEB SERIAL API DRIVER
 * Direct USB Serial communication with Arduino Uno / Nano / ESP32 at 9600 baud in modern browsers.
 */

class WebSerialService {
  constructor(callbacks = {}) {
    this.onTelemetry = callbacks.onTelemetry || (() => {});
    this.onLog = callbacks.onLog || (() => {});
    this.onStateChange = callbacks.onStateChange || (() => {});

    this.port = null;
    this.reader = null;
    this.writer = null;
    this.isConnected = false;
    this.rxBuffer = '';
  }

  isSupported() {
    return 'serial' in navigator;
  }

  async connect() {
    if (!this.isSupported()) {
      this.onLog("[ERR] Web Serial API is not supported in this browser. Use Chrome, Edge, or Opera.");
      return false;
    }

    try {
      this.onLog("[SERIAL] Requesting USB Serial Port (9600 baud)...");
      this.port = await navigator.serial.requestPort();
      await this.port.open({ baudRate: 9600 });

      this.isConnected = true;
      this.onStateChange('connected');
      this.onLog("[SERIAL] Connected to USB Serial Port successfully!");

      this.startReading();
      return true;
    } catch (err) {
      this.onLog(`[SERIAL ERR] Connection failed: ${err.message || err}`);
      this.disconnect();
      return false;
    }
  }

  async startReading() {
    while (this.port && this.port.readable && this.isConnected) {
      try {
        const textDecoder = new TextDecoderStream();
        const readableStreamClosed = this.port.readable.pipeTo(textDecoder.writable);
        this.reader = textDecoder.readable.getReader();

        while (true) {
          const { value, done } = await this.reader.read();
          if (done) break;
          if (value) {
            this.handleIncomingChunk(value);
          }
        }
      } catch (err) {
        this.onLog(`[SERIAL RX ERR] ${err.message || err}`);
        break;
      }
    }
    this.disconnect();
  }

  handleIncomingChunk(chunk) {
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

    if (this.rxBuffer.length > 500) {
      this.rxBuffer = '';
    }
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

      this.onLog(`[RX] <STATUS,${speed},${dir},${stop},${angle},${mode}>`);
    }
  }

  async sendCommand(cmdStr) {
    if (!this.port || !this.port.writable || !this.isConnected) {
      this.onLog(`[SERIAL] Cannot send '${cmdStr}': Port not connected.`);
      return false;
    }

    try {
      const textEncoder = new TextEncoderStream();
      const writableStreamClosed = textEncoder.readable.pipeTo(this.port.writable);
      const writer = textEncoder.writable.getWriter();
      await writer.write(cmdStr + "\n");
      await writer.close();
      this.onLog(`[TX] -> '${cmdStr}'`);
      return true;
    } catch (err) {
      this.onLog(`[SERIAL TX ERR] ${err.message || err}`);
      return false;
    }
  }

  async disconnect() {
    try {
      if (this.reader) {
        await this.reader.cancel();
        this.reader = null;
      }
      if (this.port) {
        await this.port.close();
        this.port = null;
      }
    } catch (_) {}
    this.isConnected = false;
    this.onStateChange('disconnected');
    this.onLog("[SERIAL] Disconnected from USB Serial port.");
  }
}

window.WebSerialService = WebSerialService;
