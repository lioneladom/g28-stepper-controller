/**
 * G28 STEPPER MOTOR CANVAS WIDGET
 * Responsive: reads canvas container size. Starts at 0 RPM.
 */
class StepperMotorWidget {
  constructor(canvasId) {
    this.canvas = document.getElementById(canvasId);
    if (!this.canvas) return;
    this.ctx = this.canvas.getContext('2d');

    this.isRunning = false;
    this.isForward = true;
    this.isEmergencyStopped = false;
    this.currentSpeed = 0;
    this.rotationAngle = 0;
    this.lastTs = performance.now();

    this._resize();
    window.addEventListener('resize', () => this._resize());

    this._loop = this._loop.bind(this);
    requestAnimationFrame(this._loop);
  }

  _resize() {
    // Size to the container (.motor-ring)
    const rect = this.canvas.parentElement ? this.canvas.parentElement.getBoundingClientRect() : null;
    this.size = (rect && rect.width > 0) ? Math.min(rect.width, rect.height) : 220;
    const dpr = window.devicePixelRatio || 1;
    this.canvas.width = this.size * dpr;
    this.canvas.height = this.size * dpr;
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
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
    const c = this.ctx, s = this.size, cx = s / 2, r = s / 2 - (s * 0.074);
    c.clearRect(0, 0, s, s);

    // Stator poles
    const sc = this.isEmergencyStopped ? '#FF1744'
      : (this.isRunning && this.currentSpeed > 0
        ? (this.isForward ? '#00E5FF' : '#8B5CF6') : '#64748B');
    c.fillStyle = sc;
    const dotR = s * 0.032;
    for (let i = 0; i < 4; i++) {
      const a = (i * Math.PI) / 2;
      c.beginPath();
      c.arc(cx + r * Math.cos(a), cx + r * Math.sin(a), dotR, 0, Math.PI * 2);
      c.fill();
    }

    // Rotor
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
    const nc = this.isEmergencyStopped ? '#FF1744' : (this.isForward ? '#00E5FF' : '#8B5CF6');
    const nw = s * 0.042, nh = s * 0.105;
    c.beginPath();
    c.roundRect(-nw / 2, -rr + s * 0.032, nw, nh, nw / 2);
    c.fillStyle = nc;
    c.fill();

    // Axle
    c.beginPath();
    c.arc(0, 0, s * 0.063, 0, Math.PI * 2);
    c.fillStyle = '#64748B';
    c.fill();
    c.restore();
  }
}
window.StepperMotorWidget = StepperMotorWidget;
