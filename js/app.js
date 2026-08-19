/**
 * G28 STEPPER MOTOR WEB CONTROLLER — MASTER APPLICATION CONTROLLER
 * Orchestrates UI interactions, hardware services, simulation engine,
 * visualizers, audio synthesis, and live telemetry data feeds.
 */

document.addEventListener('DOMContentLoaded', () => {
  // App State
  const state = {
    mode: 1, // 1 = Velocity, 2 = Position
    speed: 40, // RPM (0-80)
    directionForward: true,
    isEmergencyStopped: false,
    currentAngle: 0,
    targetAngle: 90,
    keypadBuffer: "90",
    connectionType: 'simulated', // 'simulated', 'serial', 'ble'
    isConnected: true,
    isAudioMuted: true
  };

  // DOM Elements
  const els = {
    // Header & Badges
    connectionStatusPill: document.getElementById('connectionStatusPill'),
    connectionStatusText: document.getElementById('connectionStatusText'),
    btnOpenConnectModal: document.getElementById('btnOpenConnectModal'),
    btnAudioToggle: document.getElementById('btnAudioToggle'),
    btnOpenSpecsModal: document.getElementById('btnOpenSpecsModal'),

    // Mode Tabs & Emergency Banner
    modeTabVelocity: document.getElementById('modeTabVelocity'),
    modeTabPosition: document.getElementById('modeTabPosition'),
    velocityModePanel: document.getElementById('velocityModePanel'),
    positionModePanel: document.getElementById('positionModePanel'),
    emergencyBanner: document.getElementById('emergencyBanner'),

    // Telemetry Display Readouts
    telemetrySpeedVal: document.getElementById('telemetrySpeedVal'),
    telemetryDirVal: document.getElementById('telemetryDirVal'),
    telemetryAngleVal: document.getElementById('telemetryAngleVal'),
    telemetryModeVal: document.getElementById('telemetryModeVal'),
    motorStatusBadge: document.getElementById('motorStatusBadge'),

    // Velocity Mode Controls
    speedSlider: document.getElementById('speedSlider'),
    speedReadout: document.getElementById('speedReadout'),
    btnDirFwd: document.getElementById('btnDirFwd'),
    btnDirRev: document.getElementById('btnDirRev'),

    // Position Mode Controls
    targetAngleReadout: document.getElementById('targetAngleReadout'),
    actualAngleReadout: document.getElementById('actualAngleReadout'),
    keypadBufferDisplay: document.getElementById('keypadBufferDisplay'),
    btnZeroTare: document.getElementById('btnZeroTare'),

    // Emergency Stop
    btnHeroEmergencyStop: document.getElementById('btnHeroEmergencyStop'),

    // Terminal
    terminalLogs: document.getElementById('terminalLogs'),
    termCommandInput: document.getElementById('termCommandInput'),
    btnTermSend: document.getElementById('btnTermSend'),
    btnTermClear: document.getElementById('btnTermClear'),
    btnTermCopy: document.getElementById('btnTermCopy'),

    // Modals
    connectModal: document.getElementById('connectModal'),
    specsModal: document.getElementById('specsModal'),
    btnCloseConnectModal: document.getElementById('btnCloseConnectModal'),
    btnCloseSpecsModal: document.getElementById('btnCloseSpecsModal'),
    btnSelectSimulated: document.getElementById('btnSelectSimulated'),
    btnSelectWebSerial: document.getElementById('btnSelectWebSerial'),
    btnSelectWebBle: document.getElementById('btnSelectWebBle'),

    // Toasts
    toastContainer: document.getElementById('toastContainer')
  };

  // Toast notification helper
  function showToast(msg) {
    if (!els.toastContainer) return;
    const toast = document.createElement('div');
    toast.className = 'cyber-toast';
    toast.textContent = msg;
    els.toastContainer.appendChild(toast);
    setTimeout(() => {
      if (toast.parentNode) toast.parentNode.removeChild(toast);
    }, 3000);
  }

  // Logger helper
  function addTerminalLog(msg) {
    if (!els.terminalLogs) return;
    const line = document.createElement('div');
    line.className = 'log-entry';

    const timestamp = new Date().toTimeString().split(' ')[0];
    if (msg.includes('[TX]')) {
      line.className += ' tx';
    } else if (msg.includes('[RX]')) {
      line.className += ' rx';
    } else if (msg.includes('[ERR]') || msg.includes('EMERGENCY')) {
      line.className += ' err';
    } else if (msg.includes('[SIM]') || msg.includes('[BLE]') || msg.includes('[SERIAL]')) {
      line.className += ' warn';
    }

    line.textContent = `[${timestamp}] ${msg}`;
    els.terminalLogs.appendChild(line);

    // Keep log max 250 entries
    while (els.terminalLogs.children.length > 250) {
      els.terminalLogs.removeChild(els.terminalLogs.firstChild);
    }
    els.terminalLogs.scrollTop = els.terminalLogs.scrollHeight;
  }

  // Initialize Visualizers
  const motorCanvas = new StepperMotorCanvas('motorCanvas');
  const dialGauge = new TargetAngleDial('dialCanvas', (newAngle) => {
    state.targetAngle = newAngle;
    state.keypadBuffer = newAngle.toString();
    updatePositionUI();
  });
  const oscilloscope = new StepperOscilloscope('scopeCanvas');

  // Initialize Hardware & Simulation Engines
  const handleTelemetryUpdate = (telemetry) => {
    state.currentAngle = telemetry.angle;
    state.isEmergencyStopped = telemetry.emergencyStopped;
    state.directionForward = telemetry.direction === 1;

    // Update canvas visualizers
    motorCanvas.updateState({
      angle: telemetry.angle,
      speed: telemetry.speed,
      isForward: state.directionForward,
      isRunning: telemetry.running,
      isEmergencyStopped: state.isEmergencyStopped
    });

    dialGauge.setCurrentAngle(telemetry.angle);

    // Update audio synthesis
    if (window.stepperAudio) {
      window.stepperAudio.setMotorSpeed(telemetry.speed, telemetry.running, state.isEmergencyStopped);
    }

    // Update Telemetry Header & Tile readouts
    if (els.telemetrySpeedVal) els.telemetrySpeedVal.textContent = `${telemetry.speed} RPM`;
    if (els.telemetryDirVal) els.telemetryDirVal.textContent = state.directionForward ? 'FORWARD' : 'REVERSE';
    if (els.telemetryAngleVal) els.telemetryAngleVal.textContent = `${telemetry.angle}°`;
    if (els.telemetryModeVal) els.telemetryModeVal.textContent = telemetry.mode === 1 ? 'VELOCITY' : 'POSITION';

    if (els.motorStatusBadge) {
      if (state.isEmergencyStopped) {
        els.motorStatusBadge.textContent = 'HALTED';
        els.motorStatusBadge.className = 'motor-badge-overlay stopped';
      } else if (telemetry.running) {
        els.motorStatusBadge.textContent = state.directionForward ? 'CW (FWD)' : 'CCW (REV)';
        els.motorStatusBadge.className = `motor-badge-overlay ${state.directionForward ? '' : 'reverse'}`;
      } else {
        els.motorStatusBadge.textContent = 'IDLE';
        els.motorStatusBadge.className = 'motor-badge-overlay';
      }
    }

    // Update emergency banner
    if (els.emergencyBanner) {
      if (state.isEmergencyStopped) {
        els.emergencyBanner.classList.add('active');
      } else {
        els.emergencyBanner.classList.remove('active');
      }
    }

    if (els.btnHeroEmergencyStop) {
      if (state.isEmergencyStopped) {
        els.btnHeroEmergencyStop.classList.add('active');
        els.btnHeroEmergencyStop.innerHTML = `<span style="font-size:1.4rem;">⚠️</span> RESUME OPERATION (SEND 'S')`;
      } else {
        els.btnHeroEmergencyStop.classList.remove('active');
        els.btnHeroEmergencyStop.innerHTML = `<span style="font-size:1.4rem;">⛔</span> EMERGENCY STOP (SEND 'S')`;
      }
    }
  };

  const mockEngine = new MockHardwareEngine({
    onTelemetry: handleTelemetryUpdate,
    onLog: addTerminalLog,
    onPhaseStep: (phase, isRunning) => {
      oscilloscope.updatePhase(phase, isRunning);
    }
  });

  const serialService = new WebSerialService({
    onTelemetry: handleTelemetryUpdate,
    onLog: addTerminalLog,
    onStateChange: (connState) => {
      state.isConnected = connState === 'connected';
      updateConnectionPill();
    }
  });

  const bleService = new WebBleService({
    onTelemetry: handleTelemetryUpdate,
    onLog: addTerminalLog,
    onStateChange: (connState) => {
      state.isConnected = connState === 'connected';
      updateConnectionPill();
    }
  });

  // Central Command Dispatcher
  function sendHardwareCommand(cmd) {
    if (window.stepperAudio) window.stepperAudio.playClickSound();

    if (state.connectionType === 'simulated') {
      mockEngine.sendCommand(cmd);
    } else if (state.connectionType === 'serial' && serialService.isConnected) {
      serialService.sendCommand(cmd);
    } else if (state.connectionType === 'ble' && bleService.isConnected) {
      const char = cmd.charAt(0).toUpperCase();
      if (char === 'V') bleService.sendSpeed(parseInt(cmd.substring(1)) || 0);
      else if (char === 'F') bleService.sendDirection(true);
      else if (char === 'R') bleService.sendDirection(false);
      else if (char === 'G') bleService.sendTargetPosition(parseInt(cmd.substring(1)) || 0);
    } else {
      addTerminalLog(`[WARN] Not connected. Operating in simulated mode.`);
      mockEngine.sendCommand(cmd);
    }
  }

  // UI Event Bindings: Mode Switching
  function switchMode(newMode) {
    state.mode = newMode;
    if (newMode === 1) {
      els.modeTabVelocity.classList.add('active', 'velocity');
      els.modeTabPosition.classList.remove('active', 'position');
      els.velocityModePanel.style.display = 'block';
      els.positionModePanel.style.display = 'none';
      sendHardwareCommand('M1');
      showToast("Switched to Velocity Mode");
    } else {
      els.modeTabPosition.classList.add('active', 'position');
      els.modeTabVelocity.classList.remove('active', 'velocity');
      els.positionModePanel.style.display = 'block';
      els.velocityModePanel.style.display = 'none';
      sendHardwareCommand('M2');
      showToast("Switched to Angle Go Mode");
    }
  }

  els.modeTabVelocity.addEventListener('click', () => switchMode(1));
  els.modeTabPosition.addEventListener('click', () => switchMode(2));

  // Speed Slider Debounced Control
  let speedDebounceTimer = null;
  els.speedSlider.addEventListener('input', (e) => {
    const val = parseInt(e.target.value) || 0;
    state.speed = val;
    els.speedReadout.textContent = `${val} RPM`;

    clearTimeout(speedDebounceTimer);
    speedDebounceTimer = setTimeout(() => {
      sendHardwareCommand(`V${val}`);
    }, 100);
  });

  // Direction Controls
  els.btnDirFwd.addEventListener('click', () => {
    state.directionForward = true;
    els.btnDirFwd.classList.add('active', 'fwd');
    els.btnDirRev.classList.remove('active', 'rev');
    sendHardwareCommand('F');
  });

  els.btnDirRev.addEventListener('click', () => {
    state.directionForward = false;
    els.btnDirRev.classList.add('active', 'rev');
    els.btnDirFwd.classList.remove('active', 'fwd');
    sendHardwareCommand('R');
  });

  // Emergency Stop Toggle
  els.btnHeroEmergencyStop.addEventListener('click', () => {
    if (window.stepperAudio) window.stepperAudio.playEmergencyAlarm();
    sendHardwareCommand('S');
  });

  // Position Mode: Keypad Inputs
  function updatePositionUI() {
    if (els.targetAngleReadout) els.targetAngleReadout.textContent = `${state.targetAngle}°`;
    if (els.keypadBufferDisplay) els.keypadBufferDisplay.textContent = `${state.keypadBuffer}°`;
  }

  document.querySelectorAll('.key-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      const key = btn.dataset.key;
      if (key === 'C') {
        state.keypadBuffer = "0";
      } else if (key === 'GO') {
        const parsed = parseInt(state.keypadBuffer) || 0;
        state.targetAngle = ((parsed % 360) + 360) % 360;
        dialGauge.setTargetAngle(state.targetAngle);
        sendHardwareCommand(`G${state.targetAngle}`);
        showToast(`Moving to ${state.targetAngle}°`);
      } else {
        if (state.keypadBuffer === "0") {
          state.keypadBuffer = key;
        } else if (state.keypadBuffer.length < 5) {
          state.keypadBuffer += key;
        }
      }
      updatePositionUI();
      if (window.stepperAudio) window.stepperAudio.playClickSound();
    });
  });

  // Jog Step Buttons (+1, +10, -1, -10)
  document.querySelectorAll('.jog-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      const step = parseInt(btn.dataset.step) || 0;
      let newTarget = (state.targetAngle + step) % 360;
      if (newTarget < 0) newTarget += 360;
      state.targetAngle = newTarget;
      state.keypadBuffer = newTarget.toString();
      dialGauge.setTargetAngle(newTarget);
      updatePositionUI();
      sendHardwareCommand(`G${newTarget}`);
    });
  });

  // Preset Angle Chips
  document.querySelectorAll('.preset-chip').forEach((chip) => {
    chip.addEventListener('click', () => {
      const angle = parseInt(chip.dataset.angle) || 0;
      state.targetAngle = ((angle % 360) + 360) % 360;
      state.keypadBuffer = state.targetAngle.toString();
      dialGauge.setTargetAngle(state.targetAngle);
      updatePositionUI();
      sendHardwareCommand(`G${state.targetAngle}`);
      showToast(`Target set to ${state.targetAngle}°`);
    });
  });

  // Zero Tare Origin
  els.btnZeroTare.addEventListener('click', () => {
    if (window.stepperAudio) window.stepperAudio.playTareSound();
    sendHardwareCommand('Z');
    dialGauge.setTargetAngle(0);
    state.targetAngle = 0;
    state.keypadBuffer = "0";
    updatePositionUI();
    showToast("Origin zeroed (0° tare)");
  });

  // Terminal Controls
  els.btnTermSend.addEventListener('click', () => {
    const raw = els.termCommandInput.value.trim();
    if (raw) {
      sendHardwareCommand(raw);
      els.termCommandInput.value = '';
    }
  });

  els.termCommandInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      const raw = els.termCommandInput.value.trim();
      if (raw) {
        sendHardwareCommand(raw);
        els.termCommandInput.value = '';
      }
    }
  });

  els.btnTermClear.addEventListener('click', () => {
    els.terminalLogs.innerHTML = '';
  });

  els.btnTermCopy.addEventListener('click', () => {
    const text = els.terminalLogs.innerText;
    navigator.clipboard.writeText(text).then(() => {
      showToast("Terminal logs copied to clipboard");
    });
  });

  // Audio Toggle
  els.btnAudioToggle.addEventListener('click', () => {
    if (window.stepperAudio) {
      const isMuted = window.stepperAudio.toggleMute();
      state.isAudioMuted = isMuted;
      els.btnAudioToggle.innerHTML = isMuted ? '🔇 Audio: Off' : '🔊 Audio: On';
      showToast(isMuted ? "Sound muted" : "Sound enabled");
    }
  });

  // Connection Modal
  function updateConnectionPill() {
    if (state.connectionType === 'simulated') {
      els.connectionStatusPill.className = 'status-pill simulated';
      els.connectionStatusText.textContent = 'Simulated Engine';
    } else if (state.isConnected) {
      els.connectionStatusPill.className = 'status-pill connected';
      els.connectionStatusText.textContent = state.connectionType === 'serial' ? 'USB Serial Connected' : 'ESP32 BLE Connected';
    } else {
      els.connectionStatusPill.className = 'status-pill emergency';
      els.connectionStatusText.textContent = 'Disconnected';
    }
  }

  els.btnOpenConnectModal.addEventListener('click', () => {
    els.connectModal.classList.add('active');
  });

  els.btnCloseConnectModal.addEventListener('click', () => {
    els.connectModal.classList.remove('active');
  });

  els.btnSelectSimulated.addEventListener('click', () => {
    state.connectionType = 'simulated';
    state.isConnected = true;
    updateConnectionPill();
    els.connectModal.classList.remove('active');
    showToast("Connected to Simulation Engine");
  });

  els.btnSelectWebSerial.addEventListener('click', async () => {
    els.connectModal.classList.remove('active');
    const ok = await serialService.connect();
    if (ok) {
      state.connectionType = 'serial';
      state.isConnected = true;
      updateConnectionPill();
      showToast("Connected via Web Serial!");
    }
  });

  els.btnSelectWebBle.addEventListener('click', async () => {
    els.connectModal.classList.remove('active');
    const ok = await bleService.connect();
    if (ok) {
      state.connectionType = 'ble';
      state.isConnected = true;
      updateConnectionPill();
      showToast("Connected via Web Bluetooth!");
    }
  });

  // Specs Modal
  els.btnOpenSpecsModal.addEventListener('click', () => {
    els.specsModal.classList.add('active');
  });

  els.btnCloseSpecsModal.addEventListener('click', () => {
    els.specsModal.classList.remove('active');
  });

  // Initial Boot Logs
  addTerminalLog("[BOOT] G28 Cyberpunk Stepper Controller Web App initialized.");
  addTerminalLog("[BOOT] Physics Engine active @ 60 FPS. Ready for commands.");
  updateConnectionPill();
  updatePositionUI();
});
