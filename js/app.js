/**
 * G28 STEPPER CONTROLLER — APP LOGIC
 * Standalone Web Bluetooth with automatic mode switching:
 * - Velocity Mode: Continuous spinning (CW / CCW) at set RPM.
 * - Angle Go Mode: Direct angle rotation animation & positioning.
 */

document.addEventListener('DOMContentLoaded', () => {
  const state = {
    mode: 1,        // 1=Velocity, 2=Angle Go
    speed: 0,       // current RPM (starts at 0)
    fwd: true,      // direction
    stopped: false, // emergency stop
    angle: 0,       // current angle degrees
    connected: false,
    deviceName: ''
  };

  // DOM elements
  const $ = id => document.getElementById(id);
  const el = {
    connDot: $('connDot'), connText: $('connText'),
    btnPair: $('btnPair'), btnDiscon: $('btnDiscon'),
    tabVel: $('tabVel'), tabAng: $('tabAng'),
    velPage: $('velPage'), angPage: $('angPage'),
    eBanner: $('eBanner'),
    motorRing: $('motorRing'), motorPill: $('motorPill'),
    speedVal: $('speedVal'), dirVal: $('dirVal'), dirSub: $('dirSub'),
    sliderVal: $('sliderVal'), slider: $('slider'),
    btnFwd: $('btnFwd'), btnRev: $('btnRev'),
    angleVal: $('angleVal'), btnTare: $('btnTare'),
    angleInput: $('angleInput'), btnGo: $('btnGo'),
    btnStop: $('btnStop'), stopText: $('stopText')
  };

  const motor = new StepperMotorWidget('motorCanvas');

  // Web Bluetooth
  const ble = new RealBluetoothController({
    onTelemetry: t => {
      state.angle = t.angle;
      state.stopped = t.emergencyStopped;
      state.fwd = t.direction === 1;
      state.speed = t.speed;
      render();
    },
    onConnectionChanged: ({ state: s, deviceName }) => {
      state.connected = s === 'connected';
      state.deviceName = s === 'connected' ? (deviceName || 'Device') : '';
      renderConn();
      render();
    },
    onError: msg => alert(msg)
  });

  function send(cmd) {
    if (state.connected) ble.sendCommand(cmd);
  }

  // ── Render UI & Update Motor Visualizer State ──
  function render() {
    const sp = state.stopped ? 0 : state.speed;

    // 1. Velocity Readouts
    el.speedVal.textContent = sp + ' RPM';
    el.dirVal.textContent = state.fwd ? 'FORWARD' : 'REVERSE';
    el.dirVal.style.color = state.fwd ? 'var(--primary-cyan)' : 'var(--accent-purple)';
    el.dirSub.textContent = state.fwd ? 'Clockwise' : 'Counter-Clockwise';

    // 2. Angle Readouts
    el.angleVal.textContent = state.angle + '°';

    // 3. Motor Animation Mode Switching
    if (state.stopped) {
      motor.updateState({
        mode: state.mode,
        isRunning: false,
        isForward: state.fwd,
        isEmergencyStopped: true,
        speed: 0,
        targetAngle: state.angle
      });
      el.motorRing.className = 'motor-ring stop';
      el.motorPill.textContent = 'HALTED';
      el.motorPill.className = 'motor-pill c-stop';
    } else if (state.mode === 1) {
      // VELOCITY MODE: Continuous rotation
      const running = state.speed > 0;
      motor.updateState({
        mode: 1,
        isRunning: running,
        isForward: state.fwd,
        isEmergencyStopped: false,
        speed: state.speed
      });

      if (running) {
        el.motorRing.className = 'motor-ring ' + (state.fwd ? 'fwd' : 'rev');
        el.motorPill.textContent = state.fwd ? 'CW (FWD)' : 'CCW (REV)';
        el.motorPill.className = 'motor-pill ' + (state.fwd ? 'c-fwd' : 'c-rev');
      } else {
        el.motorRing.className = 'motor-ring';
        el.motorPill.textContent = 'IDLE';
        el.motorPill.className = 'motor-pill';
      }
    } else if (state.mode === 2) {
      // ANGLE GO MODE: Positional alignment and hold
      motor.updateState({
        mode: 2,
        isRunning: true,
        isEmergencyStopped: false,
        targetAngle: state.angle,
        currentAngle: state.angle
      });
      el.motorRing.className = 'motor-ring ang';
      el.motorPill.textContent = 'POS: ' + state.angle + '°';
      el.motorPill.className = 'motor-pill c-ang';
    }

    // 4. Emergency Banner
    el.eBanner.className = state.stopped ? 'e-banner show' : 'e-banner';

    // 5. Emergency Stop Button
    el.btnStop.className = state.stopped ? 'e-stop on' : 'e-stop';
    el.stopText.textContent = state.stopped ? 'RESUME OPERATION' : 'EMERGENCY STOP';

    // 6. Direction Buttons
    el.btnFwd.className = 'dir-btn' + (!state.stopped && state.fwd ? ' sel-fwd' : '');
    el.btnRev.className = 'dir-btn' + (!state.stopped && !state.fwd ? ' sel-rev' : '');
  }

  function renderConn() {
    if (state.connected) {
      el.connDot.className = 'conn-dot on';
      el.connText.textContent = 'Connected: ' + state.deviceName;
      el.btnPair.style.display = 'none';
      el.btnDiscon.style.display = 'block';
    } else if (ble.isConnecting) {
      el.connDot.className = 'conn-dot mid';
      el.connText.textContent = 'Connecting...';
      el.btnPair.style.display = 'flex';
      el.btnDiscon.style.display = 'none';
    } else {
      el.connDot.className = 'conn-dot';
      el.connText.textContent = 'Disconnected';
      el.btnPair.style.display = 'flex';
      el.btnDiscon.style.display = 'none';
    }
  }

  // ── Automatic Mode Tabs Switching ──
  el.tabVel.onclick = () => {
    state.mode = 1;
    el.tabVel.className = 'mode-tab vel-on';
    el.tabAng.className = 'mode-tab';
    el.velPage.style.display = 'block';
    el.angPage.style.display = 'none';
    send('M1');
    render(); // Instantly switch animation behavior to Velocity mode
  };

  el.tabAng.onclick = () => {
    state.mode = 2;
    el.tabAng.className = 'mode-tab ang-on';
    el.tabVel.className = 'mode-tab';
    el.angPage.style.display = 'block';
    el.velPage.style.display = 'none';
    send('M2');
    render(); // Instantly switch animation behavior to Angle Go mode
  };

  // ── Velocity Speed Slider ──
  let sliderDebounce;
  el.slider.oninput = e => {
    if (state.stopped) return;
    const rpm = +e.target.value;
    state.speed = rpm;
    el.sliderVal.textContent = rpm + ' RPM';
    render();
    clearTimeout(sliderDebounce);
    sliderDebounce = setTimeout(() => send('V' + rpm), 120);
  };

  // ── Velocity Direction ──
  el.btnFwd.onclick = () => {
    state.fwd = true;
    render();
    send('F');
  };

  el.btnRev.onclick = () => {
    state.fwd = false;
    render();
    send('R');
  };

  // ── Angle Presets ──
  document.querySelectorAll('.chip').forEach(c => {
    c.onclick = () => {
      if (state.stopped) return;
      const deg = +c.dataset.deg;
      el.angleInput.value = deg;
      state.angle = (state.angle + deg) % 360;
      if (state.angle < 0) state.angle += 360;
      render();
      send('G' + deg);
    };
  });

  // ── Angle Go Button ──
  el.btnGo.onclick = () => {
    if (state.stopped) return;
    const deg = parseInt(el.angleInput.value) || 0;
    state.angle = (state.angle + deg) % 360;
    if (state.angle < 0) state.angle += 360;
    render();
    send('G' + deg);
  };

  // ── Angle Reset to 0° ──
  el.btnTare.onclick = () => {
    state.angle = 0;
    render();
    send('Z');
  };

  // ── Emergency Stop ──
  el.btnStop.onclick = () => {
    state.stopped = !state.stopped;
    render();
    send('S');
  };

  // ── Bluetooth Connection ──
  el.btnPair.onclick = () => ble.requestAndConnect();
  el.btnDiscon.onclick = () => ble.disconnect();

  // Initial render
  renderConn();
  render();
});
