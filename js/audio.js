// Sound Engine - Web Audio API Synthesizer for Basketball Bounceback
class SoundManager {
  constructor() {
    this.ctx = null;
    this.muted = false;
    this.musicPlaying = false;
    this.musicTimer = null;
    this.step = 0;
  }

  init() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (AudioCtx) {
        this.ctx = new AudioCtx();
      }
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  toggleMute() {
    this.muted = !this.muted;
    if (this.muted && this.musicPlaying) {
      this.stopMusic();
    } else if (!this.muted && !this.musicPlaying) {
      this.startMusic();
    }
    return this.muted;
  }

  // Realistic Basketball Court Bounce (Sub-thud + leather click)
  playBounce(intensity = 1.0) {
    if (this.muted || !this.ctx) return;
    this.init();
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'triangle';
    // Deep basketball thump pitch drops from 95Hz to 40Hz
    osc.frequency.setValueAtTime(95 * intensity, t);
    osc.frequency.exponentialRampToValueAtTime(42, t + 0.08);

    gain.gain.setValueAtTime(0.4 * Math.min(intensity, 1.5), t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.12);

    // Leather surface click
    const click = this.ctx.createOscillator();
    const clickGain = this.ctx.createGain();
    click.type = 'sine';
    click.frequency.setValueAtTime(320, t);
    click.frequency.exponentialRampToValueAtTime(100, t + 0.02);
    clickGain.gain.setValueAtTime(0.15 * intensity, t);
    clickGain.gain.exponentialRampToValueAtTime(0.001, t + 0.03);

    osc.connect(gain);
    gain.connect(this.ctx.destination);
    click.connect(clickGain);
    clickGain.connect(this.ctx.destination);

    osc.start(t);
    osc.stop(t + 0.13);
    click.start(t);
    click.stop(t + 0.04);
  }

  // Boost Jump / High Leap
  playJump() {
    if (this.muted || !this.ctx) return;
    this.init();
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(160, t);
    osc.frequency.exponentialRampToValueAtTime(440, t + 0.16);

    gain.gain.setValueAtTime(0.25, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.2);

    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start(t);
    osc.stop(t + 0.2);
  }

  // Slam Pound / Ground Strike
  playSlam() {
    if (this.muted || !this.ctx) return;
    this.init();
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(120, t);
    osc.frequency.exponentialRampToValueAtTime(30, t + 0.2);

    gain.gain.setValueAtTime(0.45, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.25);

    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start(t);
    osc.stop(t + 0.25);
  }

  // Spring Trampoline Launch
  playSpring() {
    if (this.muted || !this.ctx) return;
    this.init();
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'triangle';
    osc.frequency.setValueAtTime(220, t);
    osc.frequency.linearRampToValueAtTime(650, t + 0.12);
    osc.frequency.linearRampToValueAtTime(450, t + 0.25);

    gain.gain.setValueAtTime(0.3, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.3);

    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start(t);
    osc.stop(t + 0.3);
  }

  // Star / Diamond / Coin Pickup
  playStar(index = 0) {
    if (this.muted || !this.ctx) return;
    this.init();
    const t = this.ctx.currentTime;
    const freqs = [587.33, 659.25, 783.99, 880.00, 1046.50]; // D5, E5, G5, A5, C6
    const f = freqs[index % freqs.length];

    const osc = this.ctx.createOscillator();
    const osc2 = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(f, t);
    osc2.type = 'triangle';
    osc2.frequency.setValueAtTime(f * 2, t);

    gain.gain.setValueAtTime(0.2, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.25);

    osc.connect(gain);
    osc2.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start(t);
    osc2.start(t);
    osc.stop(t + 0.25);
    osc2.stop(t + 0.25);
  }

  // Stomp defender enemy
  playStomp() {
    if (this.muted || !this.ctx) return;
    this.init();
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'square';
    osc.frequency.setValueAtTime(240, t);
    osc.frequency.exponentialRampToValueAtTime(70, t + 0.15);

    gain.gain.setValueAtTime(0.3, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.18);

    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start(t);
    osc.stop(t + 0.18);
  }

  // Spike / Hazard Hit (Pop / Deflate)
  playHit() {
    if (this.muted || !this.ctx) return;
    this.init();
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(350, t);
    osc.frequency.exponentialRampToValueAtTime(50, t + 0.3);

    gain.gain.setValueAtTime(0.4, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.35);

    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start(t);
    osc.stop(t + 0.35);
  }

  // Rim Clank
  playRim() {
    if (this.muted || !this.ctx) return;
    this.init();
    const t = this.ctx.currentTime;
    const freqs = [800, 1150, 1480];
    freqs.forEach(f => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(f, t);
      gain.gain.setValueAtTime(0.18, t);
      gain.gain.exponentialRampToValueAtTime(0.001, t + 0.18);
      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start(t);
      osc.stop(t + 0.18);
    });
  }

  // Net Swish (Filtered White Noise Burst)
  playSwish() {
    if (this.muted || !this.ctx) return;
    this.init();
    const bufferSize = this.ctx.sampleRate * 0.28;
    const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
    const output = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      output[i] = Math.random() * 2 - 1;
    }

    const whiteNoise = this.ctx.createBufferSource();
    whiteNoise.buffer = buffer;

    const filter = this.ctx.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.setValueAtTime(1400, this.ctx.currentTime);
    filter.Q.setValueAtTime(3, this.ctx.currentTime);

    const gain = this.ctx.createGain();
    const t = this.ctx.currentTime;
    gain.gain.setValueAtTime(0.35, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.28);

    whiteNoise.connect(filter);
    filter.connect(gain);
    gain.connect(this.ctx.destination);

    whiteNoise.start(t);
    whiteNoise.stop(t + 0.28);
  }

  // Referee Whistle
  playWhistle() {
    if (this.muted || !this.ctx) return;
    this.init();
    const t = this.ctx.currentTime;
    [2400, 2650].forEach(f => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(f, t);
      // vibrato
      gain.gain.setValueAtTime(0.18, t);
      gain.gain.linearRampToValueAtTime(0.25, t + 0.1);
      gain.gain.exponentialRampToValueAtTime(0.001, t + 0.35);
      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start(t);
      osc.stop(t + 0.35);
    });
  }

  // Buzzer Beater Horn
  playBuzzer() {
    if (this.muted || !this.ctx) return;
    this.init();
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const osc2 = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(145, t);
    osc2.type = 'sawtooth';
    osc2.frequency.setValueAtTime(148, t); // beat frequency

    gain.gain.setValueAtTime(0.35, t);
    gain.gain.setValueAtTime(0.35, t + 0.6);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.85);

    osc.connect(gain);
    osc2.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start(t);
    osc2.start(t);
    osc.stop(t + 0.85);
    osc2.stop(t + 0.85);
  }

  // Crowd Cheer
  playCheer() {
    if (this.muted || !this.ctx) return;
    this.init();
    const bufferSize = this.ctx.sampleRate * 1.5;
    const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
    const output = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      output[i] = (Math.random() * 2 - 1) * Math.sin((i / bufferSize) * Math.PI);
    }
    const noise = this.ctx.createBufferSource();
    noise.buffer = buffer;

    const filter = this.ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(900, this.ctx.currentTime);

    const gain = this.ctx.createGain();
    const t = this.ctx.currentTime;
    gain.gain.setValueAtTime(0.25, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 1.5);

    noise.connect(filter);
    filter.connect(gain);
    gain.connect(this.ctx.destination);

    noise.start(t);
    noise.stop(t + 1.5);
  }

  // Upbeat Retro Chiptune Sports Music
  startMusic() {
    if (this.musicPlaying || this.muted) return;
    this.init();
    this.musicPlaying = true;
    this.step = 0;

    const bpm = 128;
    const interval = (60 / bpm / 4) * 1000; // 16th note interval

    // Bassline notes (MIDI pitch or Hz)
    // C minor / Eb / F / G retro funk groove
    const bassline = [
      130.81, 0, 130.81, 0, 155.56, 0, 174.61, 0,
      196.00, 0, 174.61, 0, 155.56, 0, 146.83, 130.81,
      130.81, 0, 130.81, 0, 155.56, 0, 174.61, 0,
      220.00, 0, 196.00, 0, 174.61, 0, 155.56, 146.83
    ];

    // Melody lead notes
    const melody = [
      523.25, 0, 523.25, 587.33, 622.25, 0, 523.25, 0,
      698.46, 0, 622.25, 0, 587.33, 523.25, 466.16, 0,
      523.25, 0, 622.25, 0, 698.46, 783.99, 698.46, 0,
      783.99, 0, 698.46, 0, 622.25, 0, 587.33, 0
    ];

    const tick = () => {
      if (!this.musicPlaying || this.muted || !this.ctx) return;
      const t = this.ctx.currentTime;
      const idx = this.step % 32;

      // Bass note
      const bFreq = bassline[idx];
      if (bFreq > 0) {
        const bOsc = this.ctx.createOscillator();
        const bGain = this.ctx.createGain();
        bOsc.type = 'triangle';
        bOsc.frequency.setValueAtTime(bFreq, t);
        bGain.gain.setValueAtTime(0.12, t);
        bGain.gain.exponentialRampToValueAtTime(0.001, t + 0.12);
        bOsc.connect(bGain);
        bGain.connect(this.ctx.destination);
        bOsc.start(t);
        bOsc.stop(t + 0.12);
      }

      // Drum kick on 0, 8, 16, 24
      if (idx % 8 === 0) {
        const kOsc = this.ctx.createOscillator();
        const kGain = this.ctx.createGain();
        kOsc.frequency.setValueAtTime(140, t);
        kOsc.frequency.exponentialRampToValueAtTime(35, t + 0.08);
        kGain.gain.setValueAtTime(0.2, t);
        kGain.gain.exponentialRampToValueAtTime(0.001, t + 0.09);
        kOsc.connect(kGain);
        kGain.connect(this.ctx.destination);
        kOsc.start(t);
        kOsc.stop(t + 0.09);
      }

      // Snare on 4, 12, 20, 28
      if (idx % 8 === 4) {
        const sNoise = this.ctx.createBuffer(1, 1024, this.ctx.sampleRate);
        const data = sNoise.getChannelData(0);
        for (let i = 0; i < 1024; i++) data[i] = Math.random() * 2 - 1;
        const sSource = this.ctx.createBufferSource();
        sSource.buffer = sNoise;
        const sGain = this.ctx.createGain();
        sGain.gain.setValueAtTime(0.1, t);
        sGain.gain.exponentialRampToValueAtTime(0.001, t + 0.07);
        sSource.connect(sGain);
        sGain.connect(this.ctx.destination);
        sSource.start(t);
        sSource.stop(t + 0.07);
      }

      // Melody note
      const mFreq = melody[idx];
      if (mFreq > 0 && (this.step % 64 >= 16)) { // enters after 1st loop
        const mOsc = this.ctx.createOscillator();
        const mGain = this.ctx.createGain();
        mOsc.type = 'square';
        mOsc.frequency.setValueAtTime(mFreq, t);
        mGain.gain.setValueAtTime(0.04, t);
        mGain.gain.exponentialRampToValueAtTime(0.001, t + 0.11);
        mOsc.connect(mGain);
        mGain.connect(this.ctx.destination);
        mOsc.start(t);
        mOsc.stop(t + 0.11);
      }

      this.step++;
      this.musicTimer = setTimeout(tick, interval);
    };

    tick();
  }

  stopMusic() {
    this.musicPlaying = false;
    if (this.musicTimer) {
      clearTimeout(this.musicTimer);
      this.musicTimer = null;
    }
  }
}

const Audio = new SoundManager();