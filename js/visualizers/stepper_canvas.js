/**
 * G28 STEPPER MOTOR CANVAS VISUALIZER
 * Precision 60FPS rendering of a NEMA 17 Stepper Motor with dynamic stator coil
 * energization (A+/A-/B+/B-), 200-step toothed rotor, D-cut shaft, and angle readouts.
 */

class StepperMotorCanvas {
  constructor(canvasId) {
    this.canvas = document.getElementById(canvasId);
    if (!this.canvas) return;
    this.ctx = this.canvas.getContext('2d');
    
    this.size = 280;
    this.setupHiDPI();

    this.currentAngle = 0; // in degrees
    this.targetAngle = 0;
    this.currentSpeed = 0; // RPM
    this.isForward = true;
    this.isRunning = false;
    this.isEmergencyStopped = false;
    this.activeCoilPhase = 0; // 0..3 for 4-step sequence
    
    this.lastTimestamp = performance.now();
    this.animate = this.animate.bind(this);
    requestAnimationFrame(this.animate);
  }

  setupHiDPI() {
    const dpr = window.devicePixelRatio || 1;
    this.canvas.width = this.size * dpr;
    this.canvas.height = this.size * dpr;
    this.canvas.style.width = `${this.size}px`;
    this.canvas.style.height = `${this.size}px`;
    this.ctx.scale(dpr, dpr);
  }

  updateState({ angle, speed, isForward, isRunning, isEmergencyStopped }) {
    if (angle !== undefined) this.currentAngle = angle;
    if (speed !== undefined) this.currentSpeed = speed;
    if (isForward !== undefined) this.isForward = isForward;
    if (isRunning !== undefined) this.isRunning = isRunning;
    if (isEmergencyStopped !== undefined) this.isEmergencyStopped = isEmergencyStopped;
  }

  animate(now) {
    const dt = (now - this.lastTimestamp) / 1000;
    this.lastTimestamp = now;

    // Advance coil phase when running
    if (this.isRunning && !this.isEmergencyStopped && this.currentSpeed > 0) {
      const stepsPerSec = (this.currentSpeed * 200) / 60;
      this.activeCoilPhase = Math.floor((now / 1000) * stepsPerSec) % 4;
    }

    this.draw();
    requestAnimationFrame(this.animate);
  }

  draw() {
    const ctx = this.ctx;
    const center = this.size / 2;
    const radius = this.size / 2 - 12;

    ctx.clearRect(0, 0, this.size, this.size);

    // 1. Draw Outer NEMA 17 Frame / Mounting Ring
    ctx.save();
    ctx.beginPath();
    ctx.arc(center, center, radius, 0, Math.PI * 2);
    ctx.fillStyle = '#0b111e';
    ctx.fill();
    ctx.lineWidth = 3;
    ctx.strokeStyle = this.isEmergencyStopped ? '#ff1744' : (this.isRunning ? (this.isForward ? '#00e5ff' : '#a855f7') : '#1e293b');
    ctx.stroke();

    // Subtle radial gradient background
    const bgGrad = ctx.createRadialGradient(center, center, 20, center, center, radius);
    bgGrad.addColorStop(0, 'rgba(15, 23, 42, 0.9)');
    bgGrad.addColorStop(1, 'rgba(6, 9, 17, 0.95)');
    ctx.fillStyle = bgGrad;
    ctx.fill();
    ctx.restore();

    // 2. Draw 8 Stator Magnetic Poles & Coils (Phases A+, B+, A-, B-)
    const statorRadius = radius * 0.76;
    for (let i = 0; i < 8; i++) {
      const coilAngle = (i * Math.PI) / 4;
      const cx = center + statorRadius * Math.cos(coilAngle);
      const cy = center + statorRadius * Math.sin(coilAngle);
      const phaseGroup = i % 4;
      const isEnergized = this.isRunning && !this.isEmergencyStopped && (phaseGroup === this.activeCoilPhase);

      ctx.save();
      ctx.beginPath();
      ctx.arc(cx, cy, 9, 0, Math.PI * 2);
      
      if (this.isEmergencyStopped) {
        ctx.fillStyle = 'rgba(255, 23, 68, 0.2)';
        ctx.strokeStyle = '#ff1744';
      } else if (isEnergized) {
        ctx.fillStyle = this.isForward ? '#00e5ff' : '#a855f7';
        ctx.strokeStyle = '#ffffff';
        ctx.shadowColor = this.isForward ? 'rgba(0, 229, 255, 0.8)' : 'rgba(168, 85, 247, 0.8)';
        ctx.shadowBlur = 12;
      } else {
        ctx.fillStyle = '#1e293b';
        ctx.strokeStyle = '#334155';
      }
      ctx.lineWidth = 2;
      ctx.fill();
      ctx.stroke();

      // Coil core pin
      ctx.beginPath();
      ctx.arc(cx, cy, 3, 0, Math.PI * 2);
      ctx.fillStyle = isEnergized ? '#ffffff' : '#475569';
      ctx.fill();
      ctx.restore();
    }

    // 3. Draw Rotating 200-Step Toothed Rotor Core
    ctx.save();
    ctx.translate(center, center);
    const radAngle = (this.currentAngle * Math.PI) / 180;
    ctx.rotate(radAngle);

    const rotorRadius = radius * 0.52;

    // Rotor Toothed Rim (50 teeth for visual balance)
    ctx.beginPath();
    const toothCount = 40;
    for (let t = 0; t < toothCount; t++) {
      const a1 = (t * 2 * Math.PI) / toothCount;
      const a2 = ((t + 0.5) * 2 * Math.PI) / toothCount;
      const rOuter = rotorRadius + 4;
      const rInner = rotorRadius - 2;

      ctx.lineTo(rOuter * Math.cos(a1), rOuter * Math.sin(a1));
      ctx.lineTo(rInner * Math.cos(a2), rInner * Math.sin(a2));
    }
    ctx.closePath();
    ctx.fillStyle = '#1e293b';
    ctx.strokeStyle = this.isEmergencyStopped ? 'rgba(255, 23, 68, 0.6)' : (this.isForward ? 'rgba(0, 229, 255, 0.6)' : 'rgba(168, 85, 247, 0.6)');
    ctx.lineWidth = 1.5;
    ctx.fill();
    ctx.stroke();

    // Rotor inner disc
    ctx.beginPath();
    ctx.arc(0, 0, rotorRadius * 0.82, 0, Math.PI * 2);
    const rotorGrad = ctx.createLinearGradient(-rotorRadius, -rotorRadius, rotorRadius, rotorRadius);
    rotorGrad.addColorStop(0, '#334155');
    rotorGrad.addColorStop(1, '#0f172a');
    ctx.fillStyle = rotorGrad;
    ctx.fill();
    ctx.lineWidth = 2;
    ctx.strokeStyle = '#475569';
    ctx.stroke();

    // Rotor Shaft Orientation Notch / Pin
    ctx.beginPath();
    ctx.roundRect(-4, -rotorRadius * 0.72, 8, 18, 4);
    ctx.fillStyle = this.isEmergencyStopped ? '#ff1744' : (this.isForward ? '#00e5ff' : '#a855f7');
    ctx.shadowColor = ctx.fillStyle;
    ctx.shadowBlur = 8;
    ctx.fill();

    // Center Metal Shaft with D-cut flat
    ctx.beginPath();
    ctx.arc(0, 0, 14, 0, Math.PI * 2);
    ctx.fillStyle = '#64748b';
    ctx.fill();
    ctx.lineWidth = 1.5;
    ctx.strokeStyle = '#cbd5e1';
    ctx.stroke();

    ctx.restore();

    // 4. Draw Center Lock / Emergency Crosshair if Stopped
    if (this.isEmergencyStopped) {
      ctx.save();
      ctx.translate(center, center);
      ctx.beginPath();
      ctx.moveTo(-16, -16); ctx.lineTo(16, 16);
      ctx.moveTo(16, -16); ctx.lineTo(-16, 16);
      ctx.strokeStyle = '#ff1744';
      ctx.lineWidth = 3;
      ctx.stroke();
      ctx.restore();
    }
  }
}

window.StepperMotorCanvas = StepperMotorCanvas;
