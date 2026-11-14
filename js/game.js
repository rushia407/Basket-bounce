// Main Game Engine, State Machine, HUD & Controller for Basketball Bounceback

const STATES = {
  MENU: 'menu',
  PLAYING: 'playing',
  SHOOTING: 'shooting',
  VICTORY: 'victory',
  GAMEOVER: 'gameover'
};

const BALL_SKINS = [
  { name: 'Classic Basketball', sx: 48, sy: 12, sw: 33, sh: 33 },
  { name: 'Neon Volt Ball', sx: 8, sy: 11, sw: 32, sh: 32 },
  { name: 'Pro Soccer Ball', sx: 88, sy: 12, sw: 32, sh: 32 },
  { name: 'Lucky 8-Ball', sx: 5, sy: 55, sw: 32, sh: 32 },
  { name: 'Retro Beach Ball', sx: 47, sy: 55, sw: 32, sh: 32 },
  { name: 'Championship Baseball', sx: 87, sy: 55, sw: 34, sh: 34 }
];

class Game {
  constructor() {
    this.canvas = document.getElementById('gameCanvas');
    this.ctx = this.canvas.getContext('2d');
    this.state = STATES.MENU;
    this.levelIndex = 0;
    this.currentLevel = null;
    this.ball = null;
    this.camera = { x: 0, y: 0, width: 800, height: 450 };

    this.selectedSkin = 0; // Basketball
    this.highScore = parseInt(localStorage.getItem('bounceback_highscore') || '0', 10);
    this.attempts = 3;
    this.shotAttemptsLeft = 3;

    // Shooting Aim Mechanics
    this.aimAngle = -48 * (Math.PI / 180); // radians
    this.aimPower = 13.5;
    this.isChargingPower = false;
    this.powerDir = 1;
    this.isDraggingAim = false;
    this.dragStart = { x: 0, y: 0 };
    this.dragCurrent = { x: 0, y: 0 };

    // Inputs
    this.input = {
      left: false,
      right: false,
      jump: false,
      jumpPressed: false,
      down: false
    };

    // Parallax background elements
    this.bgStars = [];
    for (let i = 0; i < 40; i++) {
      this.bgStars.push({
        x: Math.random() * 800,
        y: Math.random() * 260,
        size: Math.random() * 2 + 1,
        sparkle: Math.random() * Math.PI * 2
      });
    }

    this.setupListeners();
    this.resizeCanvas();
    window.addEventListener('resize', () => this.resizeCanvas());
  }

  resizeCanvas() {
    this.canvas.width = 800;
    this.canvas.height = 450;
    this.camera.width = 800;
    this.camera.height = 450;
  }

    initLevel(index) {
    this.levelIndex = index % LEVEL_DATA.length;
    const levelEl = document.getElementById('levelSelect');
    if (levelEl) levelEl.value = this.levelIndex;
    const data = LEVEL_DATA[this.levelIndex];
    this.currentLevel = new Level(this.levelIndex, data);
    this.ball = new Ball(this.currentLevel.playerStartX, this.currentLevel.playerStartY);
    this.ball.selectedSkin = this.selectedSkin;
    this.camera.x = Math.max(0, this.ball.x - 200);
    this.camera.y = 0;
    this.shotAttemptsLeft = 3;
    this.state = STATES.PLAYING;
    Audio.startMusic();
  }

  setupListeners() {
    window.addEventListener('keydown', (e) => {
      Audio.init();
      if (e.repeat) return;

      if (e.code === 'ArrowLeft' || e.code === 'KeyA') this.input.left = true;
      if (e.code === 'ArrowRight' || e.code === 'KeyD') this.input.right = true;
      if (e.code === 'ArrowDown' || e.code === 'KeyS') this.input.down = true;
      if (e.code === 'Space' || e.code === 'ArrowUp' || e.code === 'KeyW') {
        this.input.jump = true;
        this.input.jumpPressed = true;

        if (this.state === STATES.MENU) {
          this.initLevel(0);
        } else if (this.state === STATES.GAMEOVER) {
          this.initLevel(this.levelIndex);
        } else if (this.state === STATES.VICTORY) {
          this.initLevel(this.levelIndex + 1);
        } else if (this.state === STATES.SHOOTING && !this.ball.isShooting) {
          this.isChargingPower = true;
        }
      }

      // Aim angle adjustment with Up/Down in shooting state
      if (this.state === STATES.SHOOTING && !this.ball.isShooting) {
        if (e.code === 'ArrowUp') this.aimAngle -= 0.05;
        if (e.code === 'ArrowDown') this.aimAngle += 0.05;
        this.aimAngle = Math.max(-1.45, Math.min(-0.4, this.aimAngle));
      }
    });

    window.addEventListener('keyup', (e) => {
      if (e.code === 'ArrowLeft' || e.code === 'KeyA') this.input.left = false;
      if (e.code === 'ArrowRight' || e.code === 'KeyD') this.input.right = false;
      if (e.code === 'ArrowDown' || e.code === 'KeyS') this.input.down = false;
      if (e.code === 'Space' || e.code === 'ArrowUp' || e.code === 'KeyW') {
        this.input.jump = false;
        if (this.state === STATES.SHOOTING && this.isChargingPower && !this.ball.isShooting) {
          this.releaseKeyboardShot();
        }
      }
    });

    // Mouse & Touch Slingshot Aim for the Final Shot
    const getCanvasPos = (evt) => {
      const rect = this.canvas.getBoundingClientRect();
      const clientX = evt.touches ? evt.touches[0].clientX : evt.clientX;
      const clientY = evt.touches ? evt.touches[0].clientY : evt.clientY;
      const scaleX = this.canvas.width / rect.width;
      const scaleY = this.canvas.height / rect.height;
      return {
        x: (clientX - rect.left) * scaleX,
        y: (clientY - rect.top) * scaleY
      };
    };

    const handlePointerDown = (pos) => {
      Audio.init();
      if (this.state === STATES.MENU) {
        this.initLevel(0);
        return;
      }
      if (this.state === STATES.GAMEOVER) {
        this.initLevel(this.levelIndex);
        return;
      }
      if (this.state === STATES.VICTORY) {
        this.initLevel(this.levelIndex + 1);
        return;
      }
      if (this.state === STATES.SHOOTING && !this.ball.isShooting) {
        this.isDraggingAim = true;
        this.dragStart = pos;
        this.dragCurrent = pos;
      }
    };

    const handlePointerMove = (pos) => {
      if (this.isDraggingAim) {
        this.dragCurrent = pos;
      }
    };

    const handlePointerUp = () => {
      if (this.isDraggingAim && this.state === STATES.SHOOTING && !this.ball.isShooting) {
        this.isDraggingAim = false;
        const dx = this.dragStart.x - this.dragCurrent.x;
        const dy = this.dragStart.y - this.dragCurrent.y;
        const dragDist = Math.hypot(dx, dy);

        if (dragDist > 15) {
          // Calculate shot angle and power from drag vector
          const angle = Math.atan2(dy, dx);
          const power = Math.min(18.5, Math.max(7.0, dragDist * 0.12));
          this.executeShot(Math.cos(angle) * power, Math.sin(angle) * power);
        }
      }
    };

    this.canvas.addEventListener('mousedown', (e) => handlePointerDown(getCanvasPos(e)));
    window.addEventListener('mousemove', (e) => handlePointerMove(getCanvasPos(e)));
    window.addEventListener('mouseup', handlePointerUp);

    this.canvas.addEventListener('touchstart', (e) => {
      e.preventDefault();
      handlePointerDown(getCanvasPos(e));
    }, { passive: false });
    window.addEventListener('touchmove', (e) => {
      handlePointerMove(getCanvasPos(e));
    }, { passive: false });
    window.addEventListener('touchend', handlePointerUp);
  }

  releaseKeyboardShot() {
    this.isChargingPower = false;
    const vx = Math.cos(this.aimAngle) * this.aimPower;
    const vy = Math.sin(this.aimAngle) * this.aimPower;
    this.executeShot(vx, vy);
  }

  executeShot(vx, vy) {
    if (this.ball.isShooting) return;
    this.ball.isShooting = true;
    this.ball.vx = Math.abs(vx); // always shoot toward the right (hoop)
    this.ball.vy = vy < 0 ? vy : -vy;
    this.ball.va = -0.15; // Realistic basketball backspin
    Audio.playJump();
    this.currentLevel.addScreenShake(3);
    this.currentLevel.addFloatingText('SHOOT!', this.ball.x, this.ball.y - 25, '#fca311');
  }

  startShootingMode() {
    this.state = STATES.SHOOTING;
    this.ball.inShootingZone = true;
    this.ball.vx = 0;
    this.ball.vy = 0;
    this.ball.isShooting = false;
    this.aimPower = 13.0;

    // Position ball on shooting free throw mark
    this.ball.x = this.currentLevel.shootingZoneX + 40;
    this.ball.y = 10 * this.currentLevel.tileSize - this.ball.radius;

    Audio.playWhistle();
    this.currentLevel.addFloatingText('🏀 CLUTCH BUZZER BEATER! 🏀', this.ball.x, this.ball.y - 60, '#fca311');
    this.currentLevel.addScreenShake(6);
  }

  update() {
    if (this.state === STATES.PLAYING) {
      this.ball.update(this.input, this.currentLevel);
      this.currentLevel.update(this.ball);

      // Camera smoothly follows the basketball
      const targetCamX = this.ball.x - 240;
      this.camera.x += (targetCamX - this.camera.x) * 0.1;
      this.camera.x = Math.max(0, Math.min(this.camera.x, this.currentLevel.widthInTiles * this.currentLevel.tileSize - this.camera.width));

      // Trigger Shooting Mode when reaching Shooting Zone Line
      if (this.ball.x >= this.currentLevel.shootingZoneX) {
        this.startShootingMode();
      }

      // Check Ball Pop / Death
      if (!this.ball.alive) {
        this.attempts--;
        this.currentLevel.spawnBurst(this.ball.x, this.ball.y, '#e63946', 20);
        this.currentLevel.addScreenShake(8);
        if (this.attempts <= 0) {
          this.state = STATES.GAMEOVER;
          Audio.stopMusic();
        } else {
          // Instant respawn at start with brief invulnerability
          setTimeout(() => {
            if (this.state === STATES.PLAYING) {
              this.ball.reset();
              this.camera.x = 0;
            }
          }, 600);
        }
      }
    } else if (this.state === STATES.SHOOTING) {
      // Oscillate power meter if charging via Space
      if (this.isChargingPower) {
        this.aimPower += 0.28 * this.powerDir;
        if (this.aimPower > 18.0) {
          this.aimPower = 18.0;
          this.powerDir = -1;
        } else if (this.aimPower < 7.5) {
          this.aimPower = 7.5;
          this.powerDir = 1;
        }
      }

      // Camera locks smoothly to the basketball hoop arena
      const targetCamX = this.currentLevel.hoop.x - 520;
      this.camera.x += (targetCamX - this.camera.x) * 0.08;

      if (this.ball.isShooting) {
        // Apply shot ballistic physics
        this.ball.x += this.ball.vx;
        this.ball.y += this.ball.vy;
        this.ball.vy += GRAVITY * 0.72; // Slightly floater basketball arc
        this.ball.angle += this.ball.va;

        // Trail
        this.ball.trail.push({ x: this.ball.x, y: this.ball.y, angle: this.ball.angle, alpha: 0.5 });
        if (this.ball.trail.length > 6) this.ball.trail.shift();

        // Floor collision during shot
        const floorY = 11 * this.currentLevel.tileSize - this.ball.radius;
        if (this.ball.y >= floorY) {
          this.ball.y = floorY;
          this.ball.vy = -this.ball.vy * 0.65;
          this.ball.vx *= 0.75;
          Audio.playBounce(0.6);
        }

        this.currentLevel.update(this.ball);

        // Check if shot went in
        if (this.currentLevel.hoop.scored) {
          setTimeout(() => {
            this.state = STATES.VICTORY;
            if (this.currentLevel.score > this.highScore) {
              this.highScore = this.currentLevel.score;
              localStorage.setItem('bounceback_highscore', this.highScore.toString());
            }
          }, 1800);
        } else if (this.ball.x > this.currentLevel.hoop.x + 120 || (Math.abs(this.ball.vx) < 0.2 && this.ball.y >= floorY - 2)) {
          // Missed shot! Rebound!
          this.shotAttemptsLeft--;
          if (this.shotAttemptsLeft > 0) {
            Audio.playWhistle();
            this.currentLevel.addFloatingText('REBOUND! TRY AGAIN!', this.currentLevel.shootingZoneX + 40, 220, '#e63946');
            setTimeout(() => {
              this.ball.isShooting = false;
              this.ball.vx = 0;
              this.ball.vy = 0;
              this.ball.x = this.currentLevel.shootingZoneX + 40;
              this.ball.y = 10 * this.currentLevel.tileSize - this.ball.radius;
            }, 800);
          } else {
            // Out of shots
            this.state = STATES.GAMEOVER;
            Audio.playBuzzer();
          }
        }
      } else {
        this.currentLevel.update(null);
      }
    }

    // Reset single-frame inputs
    this.input.jumpPressed = false;
  }

  draw() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

    // Apply screen shake
    this.ctx.save();
    if (this.currentLevel && this.currentLevel.screenShake > 0) {
      const shakeX = (Math.random() - 0.5) * this.currentLevel.screenShake * 2;
      const shakeY = (Math.random() - 0.5) * this.currentLevel.screenShake * 2;
      this.ctx.translate(shakeX, shakeY);
    }

    // Draw Parallax Sky & Background
    this.drawBackground();

    if (this.state === STATES.PLAYING || this.state === STATES.SHOOTING || this.state === STATES.VICTORY) {
      // Draw Level Tiles & Entities
      this.currentLevel.draw(this.ctx, this.camera);

      // Draw Aim Guide when in Shooting State
      if (this.state === STATES.SHOOTING && !this.ball.isShooting) {
        this.drawAimGuide();
      }

      // Draw Ball
      this.drawBall();

      // Draw HUD
      this.drawHUD();
    }

    this.ctx.restore();

    // Draw UI Overlays (Menu / Game Over / Victory)
    if (this.state === STATES.MENU) {
      this.drawMenu();
    } else if (this.state === STATES.VICTORY) {
      this.drawVictoryScreen();
    } else if (this.state === STATES.GAMEOVER) {
      this.drawGameOverScreen();
    }
  }

  drawBackground() {
    const w = this.canvas.width;
    const h = this.canvas.height;
    const theme = this.currentLevel ? this.currentLevel.theme : 'street';

    // Sky Gradient
    const skyGrad = this.ctx.createLinearGradient(0, 0, 0, h);
    if (theme === 'rooftop') {
      skyGrad.addColorStop(0, '#0d1b2a');
      skyGrad.addColorStop(0.6, '#1b263b');
      skyGrad.addColorStop(1, '#415a77');
    } else if (theme === 'arena') {
      skyGrad.addColorStop(0, '#10002b');
      skyGrad.addColorStop(0.5, '#240046');
      skyGrad.addColorStop(1, '#3c096c');
    } else { // street
      skyGrad.addColorStop(0, '#1f1a3a');
      skyGrad.addColorStop(0.5, '#6a0572');
      skyGrad.addColorStop(0.85, '#ab2567');
      skyGrad.addColorStop(1, '#f77f00');
    }
    this.ctx.fillStyle = skyGrad;
    this.ctx.fillRect(0, 0, w, h);

    // Stars / Arena sparkles
    this.ctx.fillStyle = '#ffffff';
    this.bgStars.forEach(st => {
      st.sparkle += 0.04;
      const alpha = 0.4 + Math.sin(st.sparkle) * 0.4;
      this.ctx.globalAlpha = alpha;
      this.ctx.fillRect(st.x, st.y, st.size, st.size);
    });
    this.ctx.globalAlpha = 1.0;

    // Distant City Skyline (Parallax layer 0.2x)
    const camOffset = this.camera.x * 0.2;
    this.ctx.fillStyle = theme === 'arena' ? '#1d1135' : '#14142b';
    for (let i = 0; i < 20; i++) {
      const bx = ((i * 75 - camOffset) % (w + 150)) - 50;
      const bw = 50 + (i % 3) * 15;
      const bh = 110 + (i % 5) * 30;
      this.ctx.fillRect(bx, h - bh, bw, bh);

      // Lit Windows
      this.ctx.fillStyle = (i % 2 === 0) ? '#ffea00' : '#4cc9f0';
      this.ctx.globalAlpha = 0.35;
      for (let wy = h - bh + 15; wy < h - 40; wy += 18) {
        for (let wx = bx + 8; wx < bx + bw - 10; wx += 12) {
          if ((wx + wy + i) % 3 !== 0) {
            this.ctx.fillRect(wx, wy, 4, 6);
          }
        }
      }
      this.ctx.globalAlpha = 1.0;
      this.ctx.fillStyle = theme === 'arena' ? '#1d1135' : '#14142b';
    }

    // Arena Floodlights
    if (theme === 'arena') {
      this.ctx.fillStyle = 'rgba(255, 255, 220, 0.08)';
      this.ctx.beginPath();
      this.ctx.moveTo(100, 0);
      this.ctx.lineTo(0, h);
      this.ctx.lineTo(350, h);
      this.ctx.closePath();
      this.ctx.fill();

      this.ctx.beginPath();
      this.ctx.moveTo(w - 100, 0);
      this.ctx.lineTo(w - 350, h);
      this.ctx.lineTo(w, h);
      this.ctx.closePath();
      this.ctx.fill();
    }
  }

  drawAimGuide() {
    const ballScreenX = Math.round(this.ball.x - this.camera.x);
    const ballScreenY = Math.round(this.ball.y - this.camera.y);

    let vx, vy;
    if (this.isDraggingAim) {
      const dx = this.dragStart.x - this.dragCurrent.x;
      const dy = this.dragStart.y - this.dragCurrent.y;
      const dist = Math.hypot(dx, dy);
      const angle = Math.atan2(dy, dx);
      const power = Math.min(18.5, Math.max(7.0, dist * 0.12));
      vx = Math.abs(Math.cos(angle) * power);
      vy = Math.sin(angle) * power;

      // Draw Slingshot Band
      this.ctx.save();
      this.ctx.strokeStyle = '#fca311';
      this.ctx.lineWidth = 3;
      this.ctx.beginPath();
      this.ctx.moveTo(ballScreenX, ballScreenY);
      this.ctx.lineTo(this.dragCurrent.x, this.dragCurrent.y);
      this.ctx.stroke();
      this.ctx.restore();
    } else {
      vx = Math.cos(this.aimAngle) * this.aimPower;
      vy = Math.sin(this.aimAngle) * this.aimPower;
    }

    // Simulate and render parabolic trajectory dots
    this.ctx.save();
    let simX = this.ball.x;
    let simY = this.ball.y;
    let simVx = vx;
    let simVy = vy;

    for (let step = 0; step < 36; step++) {
      simX += simVx;
      simY += simVy;
      simVy += GRAVITY * 0.72;

      const dotX = Math.round(simX - this.camera.x);
      const dotY = Math.round(simY - this.camera.y);
      const alpha = Math.max(0.1, 1.0 - (step / 36));

      this.ctx.fillStyle = step % 2 === 0 ? '#fca311' : '#ffffff';
      this.ctx.globalAlpha = alpha;
      this.ctx.beginPath();
      this.ctx.arc(dotX, dotY, Math.max(2, 4 - step * 0.08), 0, Math.PI * 2);
      this.ctx.fill();
    }
    this.ctx.restore();

    // Power Bar Indicator
    const barW = 100;
    const barH = 12;
    const barX = ballScreenX - barW / 2;
    const barY = ballScreenY - 45;

    this.ctx.save();
    this.ctx.fillStyle = 'rgba(0, 0, 0, 0.6)';
    this.ctx.fillRect(barX - 2, barY - 2, barW + 4, barH + 4);
    this.ctx.strokeStyle = '#ffffff';
    this.ctx.lineWidth = 1.5;
    this.ctx.strokeRect(barX - 2, barY - 2, barW + 4, barH + 4);

    const fillRatio = (this.aimPower - 7.5) / (18.0 - 7.5);
    const grad = this.ctx.createLinearGradient(barX, 0, barX + barW, 0);
    grad.addColorStop(0, '#06d6a0');
    grad.addColorStop(0.6, '#ffd166');
    grad.addColorStop(1, '#ef476f');
    this.ctx.fillStyle = grad;
    this.ctx.fillRect(barX, barY, barW * fillRatio, barH);

    this.ctx.font = 'bold 11px "Courier New", monospace';
    this.ctx.fillStyle = '#ffffff';
    this.ctx.textAlign = 'center';
    this.ctx.fillText('POWER / RELEASE [SPACE]', ballScreenX, barY - 6);
    this.ctx.restore();
  }

  drawBall() {
    if (!this.ball || (!this.ball.alive && this.state !== STATES.GAMEOVER)) return;
    const screenX = Math.round(this.ball.x - this.camera.x);
    const screenY = Math.round(this.ball.y - this.camera.y);
    const ballsImg = Assets.images.balls;
    const skin = BALL_SKINS[this.ball.selectedSkin % BALL_SKINS.length];

    // Draw motion trail
    this.ctx.save();
    for (const t of this.ball.trail) {
      const tx = Math.round(t.x - this.camera.x);
      const ty = Math.round(t.y - this.camera.y);
      this.ctx.globalAlpha = t.alpha * 0.4;
      this.ctx.fillStyle = '#f77f00';
      this.ctx.beginPath();
      this.ctx.arc(tx, ty, this.ball.radius * 0.8, 0, Math.PI * 2);
      this.ctx.fill();
    }
    this.ctx.restore();

    this.ctx.save();
    this.ctx.translate(screenX, screenY);
    this.ctx.scale(this.ball.scaleX, this.ball.scaleY);
    this.ctx.rotate(this.ball.angle);

    if (ballsImg) {
      // Draw pixel-perfect ball from sheet
      this.ctx.drawImage(
        ballsImg,
        skin.sx, skin.sy, skin.sw, skin.sh,
        -this.ball.radius, -this.ball.radius,
        this.ball.radius * 2, this.ball.radius * 2
      );
    } else {
      // Fallback procedural basketball
      this.ctx.fillStyle = '#f77f00';
      this.ctx.beginPath();
      this.ctx.arc(0, 0, this.ball.radius, 0, Math.PI * 2);
      this.ctx.fill();
      this.ctx.strokeStyle = '#000000';
      this.ctx.lineWidth = 2;
      this.ctx.stroke();
      this.ctx.beginPath();
      this.ctx.moveTo(-this.ball.radius, 0);
      this.ctx.lineTo(this.ball.radius, 0);
      this.ctx.moveTo(0, -this.ball.radius);
      this.ctx.lineTo(0, this.ball.radius);
      this.ctx.stroke();
    }

    this.ctx.restore();
  }

  drawHUD() {
    this.ctx.save();
    this.ctx.font = 'bold 16px "Courier New", monospace';

    // Score Panel
    this.ctx.fillStyle = 'rgba(15, 23, 42, 0.75)';
    this.ctx.fillRect(16, 12, 175, 52);
    this.ctx.strokeStyle = '#fca311';
    this.ctx.lineWidth = 2;
    this.ctx.strokeRect(16, 12, 175, 52);

    this.ctx.fillStyle = '#ffffff';
    this.ctx.fillText(`SCORE: ${this.currentLevel.score}`, 28, 32);
    this.ctx.fillStyle = '#ffd166';
    let starsStr = '';
    for (let i = 0; i < 3; i++) {
      starsStr += i < this.currentLevel.starsCollected ? '★ ' : '☆ ';
    }
    this.ctx.fillText(`STARS: ${starsStr}`, 28, 52);

    // Distance to Final Hoop Progress Bar
    const barW = 200;
    const barH = 10;
    const barX = (this.canvas.width - barW) / 2;
    const barY = 20;
    const hoopX = this.currentLevel.hoop.x;
    const progress = Math.min(1.0, Math.max(0, this.ball.x / hoopX));

    this.ctx.fillStyle = 'rgba(15, 23, 42, 0.75)';
    this.ctx.fillRect(barX - 4, barY - 4, barW + 8, barH + 8);
    this.ctx.strokeStyle = '#4cc9f0';
    this.ctx.strokeRect(barX - 4, barY - 4, barW + 8, barH + 8);

    this.ctx.fillStyle = '#f72585';
    this.ctx.fillRect(barX, barY, barW * progress, barH);

    this.ctx.font = 'bold 11px "Courier New", monospace';
    this.ctx.fillStyle = '#ffffff';
    this.ctx.textAlign = 'center';
    this.ctx.fillText('COURT RUN ➔ BUZZER BEATER HOOP', this.canvas.width / 2, barY + 22);

    // Level Title
    this.ctx.textAlign = 'right';
    this.ctx.fillStyle = '#ffffff';
    this.ctx.fillText(this.currentLevel.name, this.canvas.width - 24, 28);
    this.ctx.fillStyle = '#ff4d6d';
    this.ctx.fillText(`LIVES: ${'❤ '.repeat(Math.max(0, this.attempts))}`, this.canvas.width - 24, 48);

    if (this.state === STATES.SHOOTING) {
      this.ctx.fillStyle = '#ffd166';
      this.ctx.fillText(`SHOTS LEFT: ${this.shotAttemptsLeft}`, this.canvas.width - 24, 68);
    }
    this.ctx.restore();
  }

  drawMenu() {
    const w = this.canvas.width;
    const h = this.canvas.height;

    this.ctx.save();
    this.ctx.fillStyle = 'rgba(15, 23, 42, 0.88)';
    this.ctx.fillRect(0, 0, w, h);

    // Title
    this.ctx.font = '900 38px "Impact", "Arial Black", sans-serif';
    this.ctx.textAlign = 'center';
    this.ctx.fillStyle = '#f77f00';
    this.ctx.shadowColor = '#d62828';
    this.ctx.shadowBlur = 15;
    this.ctx.fillText('BASKETBALL BOUNCEBACK', w / 2, 95);
    this.ctx.shadowBlur = 0;

    this.ctx.font = 'bold 15px "Courier New", monospace';
    this.ctx.fillStyle = '#ffd166';
    this.ctx.fillText('⚡ DODGE OBSTACLES • SUPER JUMP • SINK THE BUZZER BEATER! ⚡', w / 2, 130);

    // Showcase animated basketball bouncing in center
    const bounceY = 195 + Math.sin(Date.now() * 0.008) * 18;
    const ballsImg = Assets.images.balls;
    const skin = BALL_SKINS[this.selectedSkin];
    if (ballsImg) {
      this.ctx.drawImage(
        ballsImg,
        skin.sx, skin.sy, skin.sw, skin.sh,
        w / 2 - 24, bounceY - 24, 48, 48
      );
    }

    // Shadow below ball
    this.ctx.fillStyle = 'rgba(0, 0, 0, 0.4)';
    this.ctx.beginPath();
    const shadowW = 38 - Math.sin(Date.now() * 0.008) * 8;
    this.ctx.ellipse(w / 2, 225, shadowW, 6, 0, 0, Math.PI * 2);
    this.ctx.fill();

    // Controls Guide
    this.ctx.font = '13px "Courier New", monospace';
    this.ctx.fillStyle = '#ffffff';
    this.ctx.fillText('CONTROLS:', w / 2, 270);
    this.ctx.fillStyle = '#a8dadc';
    this.ctx.fillText('MOVE: [A / D] or [LEFT / RIGHT]   •   SUPER JUMP: [SPACE] or [W]', w / 2, 292);
    this.ctx.fillText('SLAM POUND: [S] or [DOWN] (in air)   •   FINAL SHOT: [SPACE] or DRAG & RELEASE', w / 2, 312);

    // Start prompt pulsing
    const pulse = Math.sin(Date.now() * 0.006) > 0;
    this.ctx.font = 'bold 19px "Courier New", monospace';
    this.ctx.fillStyle = pulse ? '#06d6a0' : '#ffffff';
    this.ctx.fillText('► PRESS [SPACE] OR CLICK ANYWHERE TO PLAY! ◄', w / 2, 365);

    if (this.highScore > 0) {
      this.ctx.font = 'bold 14px "Courier New", monospace';
      this.ctx.fillStyle = '#ffd166';
      this.ctx.fillText(`🏆 ALL-TIME HIGH SCORE: ${this.highScore}`, w / 2, 405);
    }

    this.ctx.restore();
  }

  drawVictoryScreen() {
    const w = this.canvas.width;
    const h = this.canvas.height;

    this.ctx.save();
    this.ctx.fillStyle = 'rgba(15, 23, 42, 0.82)';
    this.ctx.fillRect(0, 0, w, h);

    this.ctx.font = '900 36px "Impact", sans-serif';
    this.ctx.textAlign = 'center';
    this.ctx.fillStyle = '#06d6a0';
    this.ctx.shadowColor = '#06d6a0';
    this.ctx.shadowBlur = 12;
    this.ctx.fillText('★ BUZZER BEATER VICTORY! ★', w / 2, 110);
    this.ctx.shadowBlur = 0;

    this.ctx.font = 'bold 20px "Courier New", monospace';
    this.ctx.fillStyle = '#ffd166';
    this.ctx.fillText(`FINAL SCORE: ${this.currentLevel.score}`, w / 2, 160);

    let starRating = '';
    for (let i = 0; i < 3; i++) {
      starRating += i < this.currentLevel.starsCollected ? '★ ' : '☆ ';
    }
    this.ctx.font = 'bold 28px "Courier New", monospace';
    this.ctx.fillText(starRating, w / 2, 205);

    this.ctx.font = '15px "Courier New", monospace';
    this.ctx.fillStyle = '#ffffff';
    if (this.levelIndex < LEVEL_DATA.length - 1) {
      this.ctx.fillText(`Level ${this.levelIndex + 1} Cleared!`, w / 2, 245);
      this.ctx.font = 'bold 18px "Courier New", monospace';
      this.ctx.fillStyle = '#fca311';
      this.ctx.fillText('► PRESS [SPACE] FOR NEXT LEVEL! ◄', w / 2, 305);
    } else {
      this.ctx.fillText('🏆 YOU ARE THE BOUNCEBACK CHAMPION! 🏆', w / 2, 245);
      this.ctx.font = 'bold 18px "Courier New", monospace';
      this.ctx.fillStyle = '#fca311';
      this.ctx.fillText('► PRESS [SPACE] TO PLAY AGAIN! ◄', w / 2, 305);
    }

    this.ctx.restore();
  }

  drawGameOverScreen() {
    const w = this.canvas.width;
    const h = this.canvas.height;

    this.ctx.save();
    this.ctx.fillStyle = 'rgba(15, 23, 42, 0.88)';
    this.ctx.fillRect(0, 0, w, h);

    this.ctx.font = '900 36px "Impact", sans-serif';
    this.ctx.textAlign = 'center';
    this.ctx.fillStyle = '#e63946';
    this.ctx.shadowColor = '#e63946';
    this.ctx.shadowBlur = 12;
    this.ctx.fillText('GAME OVER - AIRBALL!', w / 2, 130);
    this.ctx.shadowBlur = 0;

    this.ctx.font = 'bold 18px "Courier New", monospace';
    this.ctx.fillStyle = '#ffffff';
    this.ctx.fillText(`FINAL SCORE: ${this.currentLevel.score}`, w / 2, 185);

    this.ctx.font = 'bold 18px "Courier New", monospace';
    this.ctx.fillStyle = '#fca311';
    this.ctx.fillText('► PRESS [SPACE] OR CLICK TO RETRY ◄', w / 2, 260);
    this.ctx.restore();
  }

  start() {
    const loop = () => {
      this.update();
      this.draw();
      requestAnimationFrame(loop);
    };
    requestAnimationFrame(loop);
  }
}

// Global Launcher
window.onload = async () => {
  await Assets.load();
  window.GameInstance = new Game();
  window.GameInstance.start();
};