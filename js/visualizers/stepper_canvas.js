/**
 * G28 STEPPER MOTOR CANVAS WIDGET
 * Dual-mode Stepper Animation Engine:
 * - Velocity Mode (Mode 1): Continuous rotation at set RPM & direction.
 * - Angle Go Mode (Mode 2): Pauses continuous rotation, receives angle targets,
 *   rotates smoothly to target angle position, and holds.
 */
class StepperMotorWidget {
  constructor(canvasId) {
    this.canvas = document.getElementById(canvasId);
    if (!this.canvas) return;
    this.ctx = this.canvas.getContext('2d');

    this.mode = 1; // 1 = Velocity, 2 = Angle Go
    this.isRunning = false;
    this.isForward = true;
    this.isEmergencyStopped = false;
    this.currentSpeed = 0; // RPM
    this.rotationAngle = 0; // Radians

    // Angular position tracking
    this.currentAngleDeg = 0;
    this.targetAngleDeg = 0;
    this.isMovingAngle = false;

    this.lastTs = performance.now();

    this._resize();
    window.addEventListener('resize', () => this._resize());

    this._loop = this._loop.bind(this);
    requestAnimationFrame(this._loop);
  }

  _resize() {
    const rect = this.canvas.parentElement ? this.canvas.parentElement.getBoundingClientRect() : null;
    this.size = (rect && rect.width > 0) ? Math.min(rect.width, rect.height) : 220;
    const dpr = window.devicePixelRatio || 1;
    this.canvas.width = this.size * dpr;
    this.canvas.height = this.size * dpr;
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }

  updateState({ mode, isRunning, isForward, isEmergencyStopped, speed, targetAngle, currentAngle }) {
    if (mode !== undefined) {
      if (this.mode !== mode) {
        this.mode = mode;
        if (mode === 2) {
          // When switching to Angle Go mode: pause spin and hold current angle
          let currentNormalized = ((this.rotationAngle * 180 / Math.PI) % 360);
          if (currentNormalized < 0) currentNormalized += 360;
          this.currentAngleDeg = Math.round(currentNormalized);
          this.targetAngleDeg = this.currentAngleDeg;
          this.rotationAngle = (this.currentAngleDeg * Math.PI) / 180;
        }
      }
    }
    if (isRunning !== undefined) this.isRunning = isRunning;
    if (isForward !== undefined) this.isForward = isForward;
    if (isEmergencyStopped !== undefined) this.isEmergencyStopped = isEmergencyStopped;
    if (speed !== undefined) this.currentSpeed = Math.max(0, speed);

    if (targetAngle !== undefined) {
      this.targetAngleDeg = targetAngle;
      this.isMovingAngle = Math.abs(this.targetAngleDeg - this.currentAngleDeg) > 0.5;
    }
  }

  setAngleTarget(targetDeg) {
    this.targetAngleDeg = targetDeg;
    this.isMovingAngle = true;
  }

  resetZero() {
    this.currentAngleDeg = 0;
    this.targetAngleDeg = 0;
    this.rotationAngle = 0;
    this.isMovingAngle = false;
  }

  _loop(now) {
    const dt = (now - this.lastTs) / 1000;
    this.lastTs = now;

    if (!this.isEmergencyStopped) {
      if (this.mode === 1) {
        // Mode 1: Continuous Velocity Mode
        if (this.isRunning && this.currentSpeed > 0) {
          const rps = (this.currentSpeed * 2 * Math.PI) / 60;
          this.rotationAngle += rps * dt * (this.isForward ? 1 : -1);
          this.rotationAngle %= (2 * Math.PI);
          this.currentAngleDeg = ((this.rotationAngle * 180 / Math.PI) % 360);
          if (this.currentAngleDeg < 0) this.currentAngleDeg += 360;
        }
      } else if (this.mode === 2) {
        // Mode 2: Angle Go Mode — paused continuous rotation, smoothly step to targetAngleDeg
        const diff = this.targetAngleDeg - this.currentAngleDeg;
        const absDiff = Math.abs(diff);

        if (absDiff > 0.5) {
          this.isMovingAngle = true;
          // Step speed: proportional with minimum 140 deg/sec for responsive smooth animation
          const stepSpeed = Math.max(140, Math.min(360, absDiff * 3.5));
          const step = Math.sign(diff) * Math.min(absDiff, stepSpeed * dt);
          this.currentAngleDeg += step;
          this.rotationAngle = (this.currentAngleDeg * Math.PI) / 180;
        } else {
          this.currentAngleDeg = this.targetAngleDeg;
          this.rotationAngle = (this.targetAngleDeg * Math.PI) / 180;
          this.isMovingAngle = false;
        }
      }
    }

    this._draw();
    requestAnimationFrame(this._loop);
  }

  _draw() {
    const c = this.ctx, s = this.size, cx = s / 2, r = s / 2 - (s * 0.074);
    c.clearRect(0, 0, s, s);

    // Stator poles color based on active mode & state
    let statorColor = '#64748B';
    if (this.isEmergencyStopped) {
      statorColor = '#FF1744';
    } else if (this.mode === 2) {
      statorColor = '#FFC107'; // Angle Go Mode = Yellow
    } else if (this.isRunning && this.currentSpeed > 0) {
      statorColor = this.isForward ? '#00E5FF' : '#8B5CF6';
    }

    c.fillStyle = statorColor;
    const dotR = s * 0.032;
    for (let i = 0; i < 4; i++) {
      const a = (i * Math.PI) / 2;
      c.beginPath();
      c.arc(cx + r * Math.cos(a), cx + r * Math.sin(a), dotR, 0, Math.PI * 2);
      c.fill();
    }

    // Rotor Core
    c.save();
    c.translate(cx, cx);
    c.rotate(this.rotationAngle);

    const rr = s * 0.275;
    c.beginPath();
    c.arc(0, 0, rr, 0, Math.PI * 2);
    const g = c.createLinearGradient(-rr, -rr, rr, rr);
    g.addColorStop(0, '#334155');
    g.addColorStop(1, '#0F172A');
    c.fillStyle = g;
    c.fill();
    c.lineWidth = 2;
    c.strokeStyle = '#232F45';
    c.stroke();

    // Shaft notch
    let notchColor = '#64748B';
    if (this.isEmergencyStopped) {
      notchColor = '#FF1744';
    } else if (this.mode === 2) {
      notchColor = '#FFC107';
    } else {
      notchColor = this.isForward ? '#00E5FF' : '#8B5CF6';
    }

    const nw = s * 0.042, nh = s * 0.105;
    c.beginPath();
    c.roundRect(-nw / 2, -rr + s * 0.032, nw, nh, nw / 2);
    c.fillStyle = notchColor;
    c.fill();

    // Center Axle
    c.beginPath();
    c.arc(0, 0, s * 0.063, 0, Math.PI * 2);
    c.fillStyle = '#64748B';
    c.fill();

    c.restore();
  }
}

window.StepperMotorWidget = StepperMotorWidget;
