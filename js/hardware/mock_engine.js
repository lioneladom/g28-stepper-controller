/**
 * G28 MOCK BLE & HARDWARE SIMULATION ENGINE
 * Full motor physics, step timing, deceleration profiles, and bidirectional
 * telemetry protocol simulation for hardware-less testing & grading.
 */

class MockHardwareEngine {
  constructor(callbacks = {}) {
    this.onTelemetry = callbacks.onTelemetry || (() => {});
    this.onLog = callbacks.onLog || (() => {});
    this.onPhaseStep = callbacks.onPhaseStep || (() => {});

    // State matching firmware
    this.currentMode = 1; // 1 = Velocity, 2 = Position
    this.currentSpeed = 40; // RPM
    this.targetSpeed = 40;
    this.currentAngle = 0; // degrees
    this.targetAngle = 90;
    this.currentSteps = 0;
    this.targetSteps = 0;
    this.directionForward = true;
    this.isEmergencyStopped = false;
    this.positionMoveActive = false;

    this.activePhase = 0;
    this.lastLoopTime = performance.now();
    this.lastTelemetryBroadcast = 0;

    this.isRunning = true;
    this.initPhysicsLoop();
  }

  initPhysicsLoop() {
    const loop = (now) => {
      const dt = (now - this.lastLoopTime) / 1000;
      this.lastLoopTime = now;

      if (!this.isEmergencyStopped) {
        this.stepPhysics(dt, now);
      }

      // Send telemetry packet every 200ms
      if (now - this.lastTelemetryBroadcast > 200) {
        this.broadcastTelemetry();
        this.lastTelemetryBroadcast = now;
      }

      requestAnimationFrame(loop);
    };
    requestAnimationFrame(loop);
  }

  stepPhysics(dt, now) {
    if (this.currentMode === 1) {
      // Velocity Mode: Continuous Rotation
      if (this.currentSpeed > 0) {
        const degPerSec = (this.currentSpeed * 360) / 60;
        const deltaDeg = degPerSec * dt * (this.directionForward ? 1 : -1);
        this.currentAngle = (this.currentAngle + deltaDeg) % 360;
        if (this.currentAngle < 0) this.currentAngle += 360;

        // Step phase cycling
        const stepsPerSec = (this.currentSpeed * 200) / 60;
        const phaseStep = Math.floor((now / 1000) * stepsPerSec) % 4;
        this.activePhase = this.directionForward ? phaseStep : (3 - phaseStep);
        this.onPhaseStep(this.activePhase, true);
      } else {
        this.onPhaseStep(0, false);
      }
    } else if (this.currentMode === 2) {
      // Angle Position Mode: Step to Target
      if (this.positionMoveActive) {
        const stepSpeed = this.currentSpeed > 0 ? this.currentSpeed : 45;
        const degPerSec = (stepSpeed * 360) / 60;
        const maxStepThisFrame = degPerSec * dt;

        let diff = this.targetAngle - this.currentAngle;
        // Normalize diff to -180..180 for shortest path
        while (diff > 180) diff -= 360;
        while (diff < -180) diff += 360;

        if (Math.abs(diff) <= maxStepThisFrame || Math.abs(diff) < 0.5) {
          this.currentAngle = this.targetAngle;
          this.positionMoveActive = false;
          this.onLog(`[SIM] Reached Target Angle: ${Math.round(this.targetAngle)}°`);
          this.onPhaseStep(0, false);
        } else {
          const moveDir = diff > 0 ? 1 : -1;
          this.directionForward = moveDir > 0;
          this.currentAngle = (this.currentAngle + moveDir * maxStepThisFrame) % 360;
          if (this.currentAngle < 0) this.currentAngle += 360;

          const stepsPerSec = (stepSpeed * 200) / 60;
          const phaseStep = Math.floor((now / 1000) * stepsPerSec) % 4;
          this.activePhase = this.directionForward ? phaseStep : (3 - phaseStep);
          this.onPhaseStep(this.activePhase, true);
        }
      } else {
        this.onPhaseStep(0, false);
      }
    }
  }

  broadcastTelemetry() {
    const telemetry = {
      speed: this.isEmergencyStopped ? 0 : Math.round(this.currentSpeed),
      direction: this.directionForward ? 1 : 0,
      emergencyStopped: this.isEmergencyStopped,
      angle: Math.round(this.currentAngle),
      mode: this.currentMode,
      running: !this.isEmergencyStopped && (this.currentMode === 1 ? this.currentSpeed > 0 : this.positionMoveActive)
    };

    this.onTelemetry(telemetry);

    // Format packet: <STATUS,speed,dir,stop,angle,mode>
    const packet = `<STATUS,${telemetry.speed},${telemetry.direction},${telemetry.emergencyStopped ? 1 : 0},${telemetry.angle},${telemetry.mode}>`;
    // Only log periodically to prevent spam
    if (Math.random() < 0.15) {
      this.onLog(`[RX] ${packet}`);
    }
  }

  // Handle incoming TX command
  sendCommand(cmdStr) {
    const cleanCmd = cmdStr.trim();
    this.onLog(`[TX] -> '${cleanCmd}'`);

    const char = cleanCmd.charAt(0).toUpperCase();

    if (char === 'M') {
      const mode = parseInt(cleanCmd.substring(1)) || 1;
      this.currentMode = mode;
      this.positionMoveActive = false;
      this.onLog(`[SIM] Switched to ${mode === 1 ? 'VELOCITY' : 'POSITION'} Mode`);
    } else if (char === 'F') {
      this.directionForward = true;
      this.onLog(`[SIM] Motor Direction -> FORWARD (CW)`);
    } else if (char === 'R') {
      this.directionForward = false;
      this.onLog(`[SIM] Motor Direction -> REVERSE (CCW)`);
    } else if (char === 'S') {
      this.isEmergencyStopped = !this.isEmergencyStopped;
      this.positionMoveActive = false;
      this.onLog(`[SIM] EMERGENCY STOP TOGGLE -> ${this.isEmergencyStopped ? 'HALTED' : 'RESUMED'}`);
    } else if (char === 'V') {
      const rpm = parseInt(cleanCmd.substring(1)) || 0;
      this.currentSpeed = Math.max(0, Math.min(80, rpm));
      this.onLog(`[SIM] Speed set to ${this.currentSpeed} RPM`);
    } else if (char === 'G') {
      const deg = parseInt(cleanCmd.substring(1)) || 0;
      this.targetAngle = ((deg % 360) + 360) % 360;
      this.currentMode = 2;
      this.positionMoveActive = true;
      this.onLog(`[SIM] Moving to Target Angle: ${this.targetAngle}°`);
    } else if (char === 'Z') {
      this.currentAngle = 0;
      this.targetAngle = 0;
      this.positionMoveActive = false;
      this.onLog(`[SIM] Zero Tare Origin (0°)`);
    }
  }
}

window.MockHardwareEngine = MockHardwareEngine;
