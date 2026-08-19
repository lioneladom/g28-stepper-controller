/**
 * G28 STEPPER MOTOR CANVAS WIDGET
 * High-DPI 220px Stepper Motor Visualizer.
 * Starts at 0 RPM (completely still) and rotates smoothly based on live telemetry speed.
 */

class StepperMotorWidget {
  constructor(canvasId) {
    this.canvas = document.getElementById(canvasId);
    if (!this.canvas) return;
    this.ctx = this.canvas.getContext('2d');

    this.size = 220;
    this.setupHiDPI();

    this.isRunning = false;
    this.isForward = true;
    this.isEmergencyStopped = false;
    this.currentSpeed = 0; // Starts strictly at 0 RPM
    this.rotationAngle = 0; // radians

    this.lastTimestamp = performance.now();
    this.animate = this.animate.bind(this);
    requestAnimationFrame(this.animate);
  }

  setupHiDPI() {
    const dpr = window.devicePixelRatio || 1;
    this.canvas.width = this.size * dpr;
    this.canvas.height = this.size * dpr;
    this.ctx.scale(dpr, dpr);
  }

  updateState({ isRunning, isForward, isEmergencyStopped, speed }) {
    if (isRunning !== undefined) this.isRunning = isRunning;
    if (isForward !== undefined) this.isForward = isForward;
    if (isEmergencyStopped !== undefined) this.isEmergencyStopped = isEmergencyStopped;
    if (speed !== undefined) this.currentSpeed = Math.max(0, speed);
  }

  animate(now) {
    const dt = (now - this.lastTimestamp) / 1000;
    this.lastTimestamp = now;

    // Only rotate if running, not emergency stopped, and speed is strictly positive
    if (this.isRunning && !this.isEmergencyStopped && this.currentSpeed > 0) {
      const radPerSec = (this.currentSpeed * 2 * Math.PI) / 60;
      const delta = radPerSec * dt * (this.isForward ? 1 : -1);
      this.rotationAngle = (this.rotationAngle + delta) % (2 * Math.PI);
    }

    this.draw();
    requestAnimationFrame(this.animate);
  }

  draw() {
    const ctx = this.ctx;
    const center = this.size / 2;
    const radius = this.size / 2 - 16;

    ctx.clearRect(0, 0, this.size, this.size);

    // 1. Stator Pole Inductors (4 poles at 0, 90, 180, 270 deg)
    const statorColor = this.isEmergencyStopped
      ? '#EF4444'
      : (this.isRunning && this.currentSpeed > 0
          ? (this.isForward ? '#00E5FF' : '#A855F7')
          : '#475569');

    ctx.fillStyle = statorColor;
    for (let i = 0; i < 4; i++) {
      const angle = (i * Math.PI) / 2;
      const x = center + radius * Math.cos(angle);
      const y = center + radius * Math.sin(angle);
      ctx.beginPath();
      ctx.arc(x, y, 7, 0, Math.PI * 2);
      ctx.fill();
    }

    // 2. Rotating Rotor Core
    ctx.save();
    ctx.translate(center, center);
    ctx.rotate(this.rotationAngle);

    const rotorRadius = this.size * 0.56 / 2;

    // Rotor disc with gradient
    ctx.beginPath();
    ctx.arc(0, 0, rotorRadius, 0, Math.PI * 2);
    const grad = ctx.createLinearGradient(-rotorRadius, -rotorRadius, rotorRadius, rotorRadius);
    grad.addColorStop(0, '#334155');
    grad.addColorStop(1, '#0F172A');
    ctx.fillStyle = grad;
    ctx.fill();
    ctx.lineWidth = 2;
    ctx.strokeStyle = '#1E293B';
    ctx.stroke();

    // Shaft notch indicator (top notch)
    const notchColor = this.isEmergencyStopped
      ? '#EF4444'
      : (this.isForward ? '#00E5FF' : '#A855F7');

    ctx.beginPath();
    ctx.roundRect(-4, -rotorRadius + 6, 8, 22, 4);
    ctx.fillStyle = notchColor;
    ctx.fill();

    // Center metal axle
    ctx.beginPath();
    ctx.arc(0, 0, 14, 0, Math.PI * 2);
    ctx.fillStyle = '#64748B';
    ctx.fill();
    ctx.lineWidth = 1.5;
    ctx.strokeStyle = '#94A3B8';
    ctx.stroke();

    ctx.restore();
  }
}

window.StepperMotorWidget = StepperMotorWidget;
