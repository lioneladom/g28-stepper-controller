/**
 * G28 TARGET ANGLE COMPASS & DIAL GAUGE
 * Interactive 360-degree angle dial with touch/mouse drag manipulation,
 * degree tick markings, target position needle, and current telemetry tracking arc.
 */

class TargetAngleDial {
  constructor(canvasId, onAngleChanged) {
    this.canvas = document.getElementById(canvasId);
    if (!this.canvas) return;
    this.ctx = this.canvas.getContext('2d');
    this.onAngleChanged = onAngleChanged || (() => {});

    this.size = 240;
    this.setupHiDPI();

    this.targetAngle = 90;
    this.currentAngle = 0;
    this.isDragging = false;

    this.setupEventListeners();
    this.draw();
  }

  setupHiDPI() {
    const dpr = window.devicePixelRatio || 1;
    this.canvas.width = this.size * dpr;
    this.canvas.height = this.size * dpr;
    this.canvas.style.width = `${this.size}px`;
    this.canvas.style.height = `${this.size}px`;
    this.ctx.scale(dpr, dpr);
  }

  setupEventListeners() {
    const handleStart = (e) => {
      this.isDragging = true;
      this.updateAngleFromEvent(e);
    };

    const handleMove = (e) => {
      if (this.isDragging) {
        this.updateAngleFromEvent(e);
      }
    };

    const handleEnd = () => {
      this.isDragging = false;
    };

    this.canvas.addEventListener('mousedown', handleStart);
    window.addEventListener('mousemove', handleMove);
    window.addEventListener('mouseup', handleEnd);

    this.canvas.addEventListener('touchstart', (e) => {
      handleStart(e.touches[0]);
      e.preventDefault();
    }, { passive: false });

    window.addEventListener('touchmove', (e) => {
      if (this.isDragging) {
        handleMove(e.touches[0]);
        e.preventDefault();
      }
    }, { passive: false });

    window.addEventListener('touchend', handleEnd);
  }

  updateAngleFromEvent(e) {
    const rect = this.canvas.getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const dx = e.clientX - cx;
    const dy = e.clientY - cy;

    // Angle in degrees from top (0 deg at top)
    let rad = Math.atan2(dy, dx) + Math.PI / 2;
    if (rad < 0) rad += Math.PI * 2;
    let deg = Math.round((rad * 180) / Math.PI);
    deg = ((deg % 360) + 360) % 360;

    this.setTargetAngle(deg, true);
  }

  setTargetAngle(deg, notify = false) {
    this.targetAngle = ((deg % 360) + 360) % 360;
    this.draw();
    if (notify && this.onAngleChanged) {
      this.onAngleChanged(this.targetAngle);
    }
  }

  setCurrentAngle(deg) {
    this.currentAngle = ((deg % 360) + 360) % 360;
    this.draw();
  }

  draw() {
    const ctx = this.ctx;
    const center = this.size / 2;
    const radius = this.size / 2 - 16;

    ctx.clearRect(0, 0, this.size, this.size);

    // 1. Background Dial Ring
    ctx.beginPath();
    ctx.arc(center, center, radius, 0, Math.PI * 2);
    ctx.fillStyle = '#0a0f1d';
    ctx.fill();
    ctx.lineWidth = 4;
    ctx.strokeStyle = '#1e293b';
    ctx.stroke();

    // 2. Degree Tick Marks (every 30 deg major, every 10 deg minor)
    for (let deg = 0; deg < 360; deg += 10) {
      const isMajor = deg % 30 === 0;
      const rad = ((deg - 90) * Math.PI) / 180;
      const tickLength = isMajor ? 10 : 5;
      const r1 = radius - tickLength;
      const r2 = radius;

      ctx.beginPath();
      ctx.moveTo(center + r1 * Math.cos(rad), center + r1 * Math.sin(rad));
      ctx.lineTo(center + r2 * Math.cos(rad), center + r2 * Math.sin(rad));
      ctx.lineWidth = isMajor ? 2 : 1;
      ctx.strokeStyle = isMajor ? '#64748b' : '#334155';
      ctx.stroke();

      // Cardinal / Quadrant numbers (0, 90, 180, 270)
      if (deg % 90 === 0) {
        const textR = radius - 20;
        const tx = center + textR * Math.cos(rad);
        const ty = center + textR * Math.sin(rad);
        ctx.font = '600 10px JetBrains Mono';
        ctx.fillStyle = '#94a3b8';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(`${deg}°`, tx, ty);
      }
    }

    // 3. Target Position Arc (from 0 to target angle)
    ctx.beginPath();
    const startRad = -Math.PI / 2;
    const targetSweepRad = (this.targetAngle * Math.PI) / 180;
    ctx.arc(center, center, radius - 2, startRad, startRad + targetSweepRad, false);
    ctx.lineWidth = 4;
    ctx.strokeStyle = '#ff9100';
    ctx.shadowColor = 'rgba(255, 145, 0, 0.4)';
    ctx.shadowBlur = 8;
    ctx.stroke();
    ctx.shadowBlur = 0;

    // 4. Actual Current Motor Angle Indicator Arc / Needle
    const actualRad = ((this.currentAngle - 90) * Math.PI) / 180;
    ctx.beginPath();
    ctx.moveTo(center, center);
    ctx.lineTo(center + (radius - 12) * Math.cos(actualRad), center + (radius - 12) * Math.sin(actualRad));
    ctx.lineWidth = 2;
    ctx.strokeStyle = '#00e5ff';
    ctx.shadowColor = 'rgba(0, 229, 255, 0.6)';
    ctx.shadowBlur = 6;
    ctx.stroke();
    ctx.shadowBlur = 0;

    // 5. Target Pointer Needle (Amber glowing arrow)
    const targetRad = ((this.targetAngle - 90) * Math.PI) / 180;
    const nx = center + (radius - 6) * Math.cos(targetRad);
    const ny = center + (radius - 6) * Math.sin(targetRad);

    ctx.beginPath();
    ctx.arc(nx, ny, 6, 0, Math.PI * 2);
    ctx.fillStyle = '#ff9100';
    ctx.shadowColor = '#ff9100';
    ctx.shadowBlur = 12;
    ctx.fill();
    ctx.shadowBlur = 0;

    // 6. Central Pivot Hub
    ctx.beginPath();
    ctx.arc(center, center, 8, 0, Math.PI * 2);
    ctx.fillStyle = '#1e293b';
    ctx.fill();
    ctx.lineWidth = 2;
    ctx.strokeStyle = '#ff9100';
    ctx.stroke();
  }
}

window.TargetAngleDial = TargetAngleDial;
