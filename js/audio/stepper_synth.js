/**
 * G28 STEPPER MOTOR AUDIO SYNTHESIZER
 * Web Audio API real-time acoustic feedback for stepper motor stepping frequencies,
 * button clicks, emergency alarms, and position tare chimes.
 */

class StepperAudioSynth {
  constructor() {
    this.ctx = null;
    this.isMuted = true; // start muted by default for clean UX
    this.oscillator = null;
    this.gainNode = null;
    this.currentFrequency = 0;
  }

  init() {
    if (!this.ctx) {
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      if (AudioContext) {
        this.ctx = new AudioContext();
      }
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  toggleMute() {
    this.init();
    this.isMuted = !this.isMuted;
    if (this.isMuted) {
      this.stopMotorSound();
    }
    return this.isMuted;
  }

  setMotorSpeed(rpm, isRunning, isEmergency) {
    if (this.isMuted || !this.ctx || !isRunning || isEmergency || rpm <= 0) {
      this.stopMotorSound();
      return;
    }

    // NEMA 17: 200 full steps per revolution
    // Frequency = (RPM * 200) / 60 Hz
    const stepFreq = Math.max(30, Math.min(1200, (rpm * 200) / 60));

    if (!this.oscillator) {
      this.startMotorSound(stepFreq);
    } else {
      this.oscillator.frequency.setTargetAtTime(stepFreq, this.ctx.currentTime, 0.05);
    }
  }

  startMotorSound(freq) {
    if (!this.ctx || this.isMuted) return;

    try {
      this.oscillator = this.ctx.createOscillator();
      this.gainNode = this.ctx.createGain();

      // Stepper motor coil PWM harmonic waveform (square + lowpass)
      this.oscillator.type = 'sawtooth';
      this.oscillator.frequency.setValueAtTime(freq, this.ctx.currentTime);

      const filter = this.ctx.createBiquadFilter();
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(800, this.ctx.currentTime);

      this.gainNode.gain.setValueAtTime(0.04, this.ctx.currentTime);

      this.oscillator.connect(filter);
      filter.connect(this.gainNode);
      this.gainNode.connect(this.ctx.destination);

      this.oscillator.start();
    } catch (e) {
      console.warn("Audio synth start error:", e);
    }
  }

  stopMotorSound() {
    if (this.oscillator) {
      try {
        this.oscillator.stop();
        this.oscillator.disconnect();
      } catch (_) {}
      this.oscillator = null;
      this.gainNode = null;
    }
  }

  playClickSound() {
    if (this.isMuted || !this.ctx) return;
    try {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(880, this.ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(440, this.ctx.currentTime + 0.04);

      gain.gain.setValueAtTime(0.05, this.ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.04);

      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start();
      osc.stop(this.ctx.currentTime + 0.05);
    } catch (_) {}
  }

  playTareSound() {
    if (this.isMuted || !this.ctx) return;
    try {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(523.25, this.ctx.currentTime); // C5
      osc.frequency.setValueAtTime(659.25, this.ctx.currentTime + 0.08); // E5
      osc.frequency.setValueAtTime(783.99, this.ctx.currentTime + 0.16); // G5

      gain.gain.setValueAtTime(0.08, this.ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.3);

      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start();
      osc.stop(this.ctx.currentTime + 0.32);
    } catch (_) {}
  }

  playEmergencyAlarm() {
    if (this.isMuted || !this.ctx) return;
    try {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'square';
      osc.frequency.setValueAtTime(440, this.ctx.currentTime);
      osc.frequency.linearRampToValueAtTime(220, this.ctx.currentTime + 0.15);

      gain.gain.setValueAtTime(0.12, this.ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.2);

      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start();
      osc.stop(this.ctx.currentTime + 0.22);
    } catch (_) {}
  }
}

window.stepperAudio = new StepperAudioSynth();
