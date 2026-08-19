/**
 * G28 DIGITAL STEPPER OSCILLOSCOPE
 * 4-Channel Phase Pulse & Telemetry Waveform Oscilloscope Canvas
 */

class StepperOscilloscope {
  constructor(canvasId) {
    this.canvas = document.getElementById(canvasId);
    if (!this.canvas) return;
    this.ctx = this.canvas.getContext('2d');

    this.width = this.canvas.clientWidth || 320;
    this.height = 120;
    this.setupHiDPI();

    this.historyLength = 120;
    // 4 Phase channels: A+, B+, A-, B-
    this.channelHistory = [
      new Array(this.historyLength).fill(0),
      new Array(this.historyLength).fill(0),
      new Array(this.historyLength).fill(0),
      new Array(this.historyLength).fill(0)
    ];

    this.colors = ['#00e5ff', '#a855f7', '#ff9100', '#10b981'];
    this.channelNames = ['A+', 'B+', 'A-', 'B-'];

    this.activePhase = 0;
    this.isRunning = false;

    this.animate = this.animate.bind(this);
    requestAnimationFrame(this.animate);
  }

  setupHiDPI() {
    const dpr = window.devicePixelRatio || 1;
    this.canvas.width = this.width * dpr;
    this.canvas.height = this.height * dpr;
    this.ctx.scale(dpr, dpr);
  }

  updatePhase(phase, isRunning) {
    this.activePhase = phase;
    this.isRunning = isRunning;
  }

  pushSample() {
    for (let ch = 0; ch < 4; ch++) {
      const val = (this.isRunning && this.activePhase === ch) ? 1 : 0;
      this.channelHistory[ch].shift();
      this.channelHistory[ch].push(val);
    }
  }

  animate() {
    this.pushSample();
    this.draw();
    requestAnimationFrame(this.animate);
  }

  draw() {
    const ctx = this.ctx;
    const w = this.width;
    const h = this.height;

    ctx.clearRect(0, 0, w, h);

    // 1. Draw Grid Lines
    ctx.strokeStyle = '#131d2e';
    ctx.lineWidth = 1;

    // Horizontal grid for 4 channels
    const chHeight = h / 4;
    for (let i = 1; i < 4; i++) {
      ctx.beginPath();
      ctx.moveTo(0, i * chHeight);
      ctx.lineTo(w, i * chHeight);
      ctx.stroke();
    }

    // Vertical time division lines
    const vStep = w / 8;
    for (let x = 0; x < w; x += vStep) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, h);
      ctx.stroke();
    }

    // 2. Draw 4 Channel Digital Waveforms
    const dx = w / this.historyLength;

    for (let ch = 0; ch < 4; ch++) {
      const baseY = (ch + 1) * chHeight - 4;
      const highY = ch * chHeight + 5;

      ctx.beginPath();
      ctx.strokeStyle = this.colors[ch];
      ctx.lineWidth = 1.5;
      ctx.shadowColor = this.colors[ch];
      ctx.shadowBlur = 4;

      for (let i = 0; i < this.historyLength; i++) {
        const val = this.channelHistory[ch][i];
        const x = i * dx;
        const y = val === 1 ? highY : baseY;

        if (i === 0) {
          ctx.moveTo(x, y);
        } else {
          const prevVal = this.channelHistory[ch][i - 1];
          const prevY = prevVal === 1 ? highY : baseY;
          // Draw digital square step edge
          if (prevY !== y) {
            ctx.lineTo(x, prevY);
          }
          ctx.lineTo(x, y);
        }
      }
      ctx.stroke();
      ctx.shadowBlur = 0;

      // Channel label
      ctx.font = '700 8px JetBrains Mono';
      ctx.fillStyle = this.colors[ch];
      ctx.fillText(this.channelNames[ch], 4, highY + 8);
    }
  }
}

window.StepperOscilloscope = StepperOscilloscope;
