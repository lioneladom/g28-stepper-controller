/**
 * G28 STEPPER MOTOR CANVAS WIDGET
 * 190px — Starts at 0 RPM (completely idle).
 */

class StepperMotorWidget {
  constructor(canvasId) {
    this.canvas = document.getElementById(canvasId);
    if (!this.canvas) return;
    this.ctx = this.canvas.getContext('2d');
    this.size = 190;
    const dpr = window.devicePixelRatio || 1;
    this.canvas.width = this.size * dpr;
    this.canvas.height = this.size * dpr;
    this.ctx.scale(dpr, dpr);

    this.isRunning = false;
    this.isForward = true;
    this.isEmergencyStopped = false;
    this.currentSpeed = 0;
    this.rotationAngle = 0;
    this.lastTs = performance.now();
    this._loop = this._loop.bind(this);
    requestAnimationFrame(this._loop);
  }

  updateState({ isRunning, isForward, isEmergencyStopped, speed }) {
    if (isRunning !== undefined) this.isRunning = isRunning;
    if (isForward !== undefined) this.isForward = isForward;
    if (isEmergencyStopped !== undefined) this.isEmergencyStopped = isEmergencyStopped;
    if (speed !== undefined) this.currentSpeed = Math.max(0, speed);
  }

  _loop(now) {
    const dt = (now - this.lastTs) / 1000;
    this.lastTs = now;
    if (this.isRunning && !this.isEmergencyStopped && this.currentSpeed > 0) {
      const rps = (this.currentSpeed * 2 * Math.PI) / 60;
      this.rotationAngle += rps * dt * (this.isForward ? 1 : -1);
      this.rotationAngle %= (2 * Math.PI);
    }
    this._draw();
    requestAnimationFrame(this._loop);
  }

  _draw() {
    const c = this.ctx, s = this.size, cx = s / 2, r = s / 2 - 14;
    c.clearRect(0, 0, s, s);

    // Stator poles
    const sc = this.isEmergencyStopped ? '#FF1744'
      : (this.isRunning && this.currentSpeed > 0
        ? (this.isForward ? '#00E5FF' : '#8B5CF6') : '#64748B');
    c.fillStyle = sc;
    for (let i = 0; i < 4; i++) {
      const a = (i * Math.PI) / 2;
      c.beginPath();
      c.arc(cx + r * Math.cos(a), cx + r * Math.sin(a), 6, 0, Math.PI * 2);
      c.fill();
    }

    // Rotor
    c.save();
    c.translate(cx, cx);
    c.rotate(this.rotationAngle);
    const rr = s * 0.55 / 2;
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
    const nc = this.isEmergencyStopped ? '#FF1744' : (this.isForward ? '#00E5FF' : '#8B5CF6');
    c.beginPath();
    c.roundRect(-4, -rr + 6, 8, 20, 4);
    c.fillStyle = nc;
    c.fill();

    // Axle
    c.beginPath();
    c.arc(0, 0, 12, 0, Math.PI * 2);
    c.fillStyle = '#64748B';
    c.fill();

    c.restore();
  }
}

window.StepperMotorWidget = StepperMotorWidget;
