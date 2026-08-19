/**
 * G28 STEPPER CONTROLLER — MASTER SCRIPT
 * Direct standalone Web Bluetooth integration with clean simple mobile UI.
 */

document.addEventListener('DOMContentLoaded', () => {
  // App State
  const state = {
    activeMode: 1, // 1 = Velocity Mode, 2 = Position Mode
    currentSpeedRpm: 40,
    directionForward: true,
    isEmergencyStopped: false,
    currentAngleDegrees: 0,
    isConnected: false,
    connectedDeviceName: ""
  };

  // DOM References
  const els = {
    statusDot: document.getElementById('statusDot'),
    statusText: document.getElementById('statusText'),
    btnPairBt: document.getElementById('btnPairBt'),
    btnDisconnect: document.getElementById('btnDisconnect'),

    tabVelocity: document.getElementById('tabVelocity'),
    tabPosition: document.getElementById('tabPosition'),
    velocityPage: document.getElementById('velocityPage'),
    positionPage: document.getElementById('positionPage'),
    emergencyBanner: document.getElementById('emergencyBanner'),

    motorBox: document.getElementById('motorBox'),
    motorPill: document.getElementById('motorPill'),

    motorSpeedVal: document.getElementById('motorSpeedVal'),
    dirIcon: document.getElementById('dirIcon'),
    dirVal: document.getElementById('dirVal'),
    dirCmdSub: document.getElementById('dirCmdSub'),

    sliderReadout: document.getElementById('sliderReadout'),
    speedSlider: document.getElementById('speedSlider'),
    btnFwd: document.getElementById('btnFwd'),
    btnRev: document.getElementById('btnRev'),

    currentAngleVal: document.getElementById('currentAngleVal'),
    btnZeroTare: document.getElementById('btnZeroTare'),
    angleInputField: document.getElementById('angleInputField'),
    btnMoveGo: document.getElementById('btnMoveGo'),

    btnHeroEmergencyStop: document.getElementById('btnHeroEmergencyStop'),
    emergencyBtnText: document.getElementById('emergencyBtnText')
  };

  // Stepper Motor Canvas Widget
  const motorWidget = new StepperMotorWidget('motorCanvas');

  // Real Web Bluetooth Controller
  const bleController = new RealBluetoothController({
    onTelemetry: (telemetry) => {
      state.currentAngleDegrees = telemetry.angle;
      state.isEmergencyStopped = telemetry.emergencyStopped;
      state.directionForward = telemetry.direction === 1;
      state.currentSpeedRpm = telemetry.speed;
      updateUI();
    },
    onConnectionChanged: ({ state: connState, deviceName }) => {
      if (connState === 'connected') {
        state.isConnected = true;
        state.connectedDeviceName = deviceName || "Bluetooth Device";
      } else if (connState === 'connecting') {
        state.isConnected = false;
        state.connectedDeviceName = "Connecting...";
      } else {
        state.isConnected = false;
        state.connectedDeviceName = "";
      }
      updateConnectionBar();
      updateUI();
    },
    onError: (errMsg) => {
      alert(errMsg);
    }
  });

  function sendCommand(cmd) {
    if (state.isConnected) {
      bleController.sendCommand(cmd);
    }
  }

  // Update UI to match current state
  function updateUI() {
    // 1. Motor Speed Display
    if (els.motorSpeedVal) {
      els.motorSpeedVal.textContent = state.isEmergencyStopped ? "0 RPM" : `${state.currentSpeedRpm} RPM`;
    }

    // 2. Direction Info Display
    if (els.dirVal) {
      els.dirVal.textContent = state.directionForward ? "FORWARD" : "REVERSE";
      els.dirVal.style.color = state.directionForward ? "var(--primary-cyan)" : "var(--accent-purple)";
    }
    if (els.dirCmdSub) {
      els.dirCmdSub.textContent = state.directionForward ? "Clockwise" : "Counter-Clockwise";
    }

    // 3. Current Angle Display
    if (els.currentAngleVal) {
      els.currentAngleVal.textContent = `${state.currentAngleDegrees}°`;
    }

    // 4. Motor Visualizer State
    const isRunning = state.isConnected && !state.isEmergencyStopped && state.currentSpeedRpm > 0;

    motorWidget.updateState({
      isRunning: isRunning,
      isForward: state.directionForward,
      isEmergencyStopped: state.isEmergencyStopped,
      speed: state.currentSpeedRpm
    });

    if (els.motorBox && els.motorPill) {
      if (state.isEmergencyStopped) {
        els.motorBox.className = 'motor-container halted';
        els.motorPill.textContent = 'HALTED';
        els.motorPill.className = 'motor-status-pill halted';
      } else if (isRunning) {
        els.motorBox.className = `motor-container ${state.directionForward ? 'running-fwd' : 'running-rev'}`;
        els.motorPill.textContent = state.directionForward ? 'CW (FWD)' : 'CCW (REV)';
        els.motorPill.className = `motor-status-pill ${state.directionForward ? 'fwd' : 'rev'}`;
      } else {
        els.motorBox.className = 'motor-container';
        els.motorPill.textContent = 'IDLE';
        els.motorPill.className = 'motor-status-pill';
      }
    }

    // 5. Emergency Banner
    if (els.emergencyBanner) {
      if (state.isEmergencyStopped) {
        els.emergencyBanner.classList.add('active');
      } else {
        els.emergencyBanner.classList.remove('active');
      }
    }

    // 6. Emergency Stop Hero Button
    if (els.btnHeroEmergencyStop && els.emergencyBtnText) {
      if (state.isEmergencyStopped) {
        els.btnHeroEmergencyStop.classList.add('active');
        els.emergencyBtnText.textContent = "RESUME OPERATION";
      } else {
        els.btnHeroEmergencyStop.classList.remove('active');
        els.emergencyBtnText.textContent = "EMERGENCY STOP";
      }
    }

    // 7. Direction Buttons
    if (els.btnFwd && els.btnRev) {
      if (state.directionForward && !state.isEmergencyStopped) {
        els.btnFwd.classList.add('active', 'fwd');
        els.btnRev.classList.remove('active', 'rev');
      } else if (!state.directionForward && !state.isEmergencyStopped) {
        els.btnRev.classList.add('active', 'rev');
        els.btnFwd.classList.remove('active', 'fwd');
      } else {
        els.btnFwd.classList.remove('active', 'fwd');
        els.btnRev.classList.remove('active', 'rev');
      }
    }
  }

  function updateConnectionBar() {
    if (state.isConnected) {
      els.statusDot.className = 'status-dot connected';
      els.statusText.textContent = `Connected: ${state.connectedDeviceName}`;
      els.btnPairBt.style.display = 'none';
      els.btnDisconnect.style.display = 'block';
    } else if (bleController.isConnecting) {
      els.statusDot.className = 'status-dot connecting';
      els.statusText.textContent = 'Connecting...';
      els.btnPairBt.style.display = 'flex';
      els.btnDisconnect.style.display = 'none';
    } else {
      els.statusDot.className = 'status-dot';
      els.statusText.textContent = 'Disconnected';
      els.btnPairBt.style.display = 'flex';
      els.btnDisconnect.style.display = 'none';
    }
  }

  // Mode Switch Tabs
  function setOperatingMode(mode) {
    state.activeMode = mode;
    if (mode === 1) {
      els.tabVelocity.classList.add('active', 'velocity');
      els.tabPosition.classList.remove('active', 'position');
      els.velocityPage.style.display = 'flex';
      els.positionPage.style.display = 'none';
      sendCommand('M1');
    } else {
      els.tabPosition.classList.add('active', 'position');
      els.tabVelocity.classList.remove('active', 'velocity');
      els.positionPage.style.display = 'flex';
      els.velocityPage.style.display = 'none';
      sendCommand('M2');
    }
    updateUI();
  }

  els.tabVelocity.addEventListener('click', () => setOperatingMode(1));
  els.tabPosition.addEventListener('click', () => setOperatingMode(2));

  // Speed Slider
  let debounceTimer = null;
  els.speedSlider.addEventListener('input', (e) => {
    if (state.isEmergencyStopped) return;
    const rpm = parseInt(e.target.value) || 0;
    state.currentSpeedRpm = rpm;
    els.sliderReadout.textContent = `${rpm} RPM`;
    updateUI();

    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
      sendCommand(`V${rpm}`);
    }, 150);
  });

  // Direction Buttons
  els.btnFwd.addEventListener('click', () => {
    state.directionForward = true;
    updateUI();
    sendCommand('F');
  });

  els.btnRev.addEventListener('click', () => {
    state.directionForward = false;
    updateUI();
    sendCommand('R');
  });

  // Preset Angle Chips
  document.querySelectorAll('.angle-chip').forEach((chip) => {
    chip.addEventListener('click', () => {
      if (state.isEmergencyStopped) return;
      const deg = parseInt(chip.dataset.deg) || 0;
      els.angleInputField.value = deg.toString();
      sendCommand(`G${deg}`);
    });
  });

  // Move Go Button
  els.btnMoveGo.addEventListener('click', () => {
    if (state.isEmergencyStopped) return;
    const deg = parseInt(els.angleInputField.value.trim()) || 0;
    sendCommand(`G${deg}`);
  });

  // Zero Tare
  els.btnZeroTare.addEventListener('click', () => {
    state.currentAngleDegrees = 0;
    updateUI();
    sendCommand('Z');
  });

  // Emergency Stop Hero Button
  els.btnHeroEmergencyStop.addEventListener('click', () => {
    state.isEmergencyStopped = !state.isEmergencyStopped;
    updateUI();
    sendCommand('S');
  });

  // Connect & Disconnect Handlers
  els.btnPairBt.addEventListener('click', async () => {
    await bleController.requestAndConnect();
  });

  els.btnDisconnect.addEventListener('click', () => {
    bleController.disconnect();
  });

  // Initial Sync
  updateConnectionBar();
  updateUI();
});
