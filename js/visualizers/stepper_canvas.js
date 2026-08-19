/**
 * G28 STEPPER MOTOR CANVAS WIDGET
 * Exact 1:1 reproduction of the Flutter StepperMotorWidget:
 * 4 stator pole inductors, rotating rotor core with shaft notch, and center axle.
 */

class StepperMotorWidget {
  constructor(canvasId) {
    this.canvas = document.getElementById(canvasId);
    if (!this.canvas) return;
    this.ctx = this.canvas.getContext('2d');

    this.size = 190;
    this.setupHiDPI();

    this.isRunning = true;
    this.isForward = true;
    this.isEmergencyStopped = false;
    this.currentSpeed = 40; // RPM
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
    if (speed !== undefined) this.currentSpeed = speed;
  }

  animate(now) {
    const dt = (now - this.lastTimestamp) / 1000;
    this.lastTimestamp = now;

    if (this.isRunning && !this.isEmergencyStopped && this.currentSpeed > 0) {
      // Angular velocity proportional to speed
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
    const radius = this.size / 2 - 14;

    ctx.clearRect(0, 0, this.size, this.size);

    // 1. Draw 4 Stator Pole Inductor Dots on outer ring (matching StatorPainter)
    const statorColor = this.isEmergencyStopped
      ? '#FF1744'
      : (this.isRunning
          ? (this.isForward ? '#00E5FF' : '#8B5CF6')
          : '#64748B');

    ctx.fillStyle = statorColor;
    for (let i = 0; i < 4; i++) {
      const angle = (i * Math.PI) / 2;
      const x = center + radius * Math.cos(angle);
      const y = center + radius * Math.sin(angle);
      ctx.beginPath();
      ctx.arc(x, y, 6, 0, Math.PI * 2);
      ctx.fill();
    }

    // 2. Draw Rotating Rotor Core
    ctx.save();
    ctx.translate(center, center);
    ctx.rotate(this.rotationAngle);

    const rotorRadius = this.size * 0.55 / 2;

    // Rotor background with gradient
    ctx.beginPath();
    ctx.arc(0, 0, rotorRadius, 0, Math.PI * 2);
    const grad = ctx.createLinearGradient(-rotorRadius, -rotorRadius, rotorRadius, rotorRadius);
    grad.addColorStop(0, '#334155');
    grad.addColorStop(1, '#0F172A');
    ctx.fillStyle = grad;
    ctx.fill();
    ctx.lineWidth = 2;
    ctx.strokeStyle = '#232F45';
    ctx.stroke();

    // Shaft notch indicator (top notch)
    const notchColor = this.isEmergencyStopped
      ? '#FF1744'
      : (this.isForward ? '#00E5FF' : '#8B5CF6');

    ctx.beginPath();
    ctx.roundRect(-4, -rotorRadius + 6, 8, 20, 4);
    ctx.fillStyle = notchColor;
    ctx.fill();

    // Center metal axle
    ctx.beginPath();
    ctx.arc(0, 0, 12, 0, Math.PI * 2);
    ctx.fillStyle = '#64748B';
    ctx.fill();

    ctx.restore();
  }
}

window.StepperMotorWidget = StepperMotorWidget;
