// Entities: Collectibles, Defenders, Springs, Net Physics, Particles, and Basketball Hoop

// Particle System
class Particle {
  constructor(x, y, vx, vy, color, size, life, gravity = 0.2, shape = 'square') {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.color = color;
    this.size = size;
    this.maxLife = life;
    this.life = life;
    this.gravity = gravity;
    this.shape = shape; // 'square', 'circle', 'confetti'
    this.angle = Math.random() * Math.PI * 2;
    this.spin = (Math.random() - 0.5) * 0.3;
  }

  update() {
    this.x += this.vx;
    this.y += this.vy;
    this.vy += this.gravity;
    this.vx *= 0.96;
    this.life--;
    this.angle += this.spin;
  }

  draw(ctx, camera) {
    if (this.life <= 0) return;
    const alpha = Math.max(0, this.life / this.maxLife);
    ctx.save();
    ctx.globalAlpha = alpha;
    ctx.fillStyle = this.color;
    ctx.translate(Math.round(this.x - camera.x), Math.round(this.y - camera.y));
    ctx.rotate(this.angle);

    if (this.shape === 'confetti') {
      ctx.fillRect(-this.size, -this.size * 0.5, this.size * 2, this.size);
    } else if (this.shape === 'circle') {
      ctx.beginPath();
      ctx.arc(0, 0, this.size, 0, Math.PI * 2);
      ctx.fill();
    } else {
      ctx.fillRect(-this.size / 2, -this.size / 2, this.size, this.size);
    }
    ctx.restore();
  }
}

// Golden Star / Trophy Collectible
class Star {
  constructor(x, y, id) {
    this.x = x;
    this.y = y;
    this.startY = y;
    this.id = id;
    this.collected = false;
    this.bobTimer = Math.random() * Math.PI * 2;
    this.sparkleTimer = 0;
  }

  update(ball, level) {
    if (this.collected) return;
    this.bobTimer += 0.08;
    this.y = this.startY + Math.sin(this.bobTimer) * 5;

    // Sparkle particles
    this.sparkleTimer++;
    if (this.sparkleTimer % 18 === 0) {
      level.particles.push(new Particle(
        this.x + (Math.random() - 0.5) * 16,
        this.y + (Math.random() - 0.5) * 16,
        (Math.random() - 0.5) * 0.8,
        -Math.random() * 0.8,
        '#ffe66d',
        2,
        25,
        -0.02,
        'square'
      ));
    }

    // Collision with ball
    const dx = ball.x - this.x;
    const dy = ball.y - this.y;
    const distSq = dx * dx + dy * dy;
    if (distSq < (ball.radius + 14) * (ball.radius + 14)) {
      this.collected = true;
      level.score += 250;
      level.starsCollected++;
      Audio.playStar(level.starsCollected);
      level.spawnBurst(this.x, this.y, '#ffd166', 16, 'circle');
      level.addFloatingText('+250 STAR!', this.x, this.y - 15, '#ffd166');
    }
  }

  draw(ctx, camera) {
    if (this.collected) return;
    const tm = Assets.images.tilemap;
    const screenX = Math.round(this.x - camera.x - 12);
    const screenY = Math.round(this.y - camera.y - 12);

    if (tm) {
      // Tile 151 is coin/medal (col 11, row 7 in tilemap_packed)
      ctx.drawImage(tm, 11 * 18, 7 * 18, 18, 18, screenX, screenY, 24, 24);
    } else {
      // Fallback star rendering
      ctx.save();
      ctx.fillStyle = '#ffd166';
      ctx.beginPath();
      ctx.arc(screenX + 12, screenY + 12, 10, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    }
  }
}

// Patrolling Defender Enemy (Uses Kenney Character sprites)
class Defender {
  constructor(x, y, patrolDistance, type = 'walker', speed = 1.2) {
    this.startX = x;
    this.x = x;
    this.y = y;
    this.patrolDistance = patrolDistance;
    this.type = type; // 'walker', 'flyer', 'crawler'
    this.speed = speed;
    this.vx = speed;
    this.alive = true;
    this.animTimer = 0;
    this.frame = 0;
    this.width = 28;
    this.height = 28;
  }

  update(ball, level) {
    if (!this.alive) return;

    this.animTimer += 0.12;
    this.frame = Math.floor(this.animTimer) % 2;

    this.x += this.vx;
    if (this.x > this.startX + this.patrolDistance) {
      this.vx = -Math.abs(this.speed);
    } else if (this.x < this.startX - this.patrolDistance) {
      this.vx = Math.abs(this.speed);
    }

    if (this.type === 'flyer') {
      this.y += Math.sin(this.animTimer * 1.5) * 1.2;
    }

    // Collision with ball
    const dx = ball.x - this.x;
    const dy = ball.y - this.y;
    const distSq = dx * dx + dy * dy;

    if (distSq < (ball.radius + this.width * 0.45) * (ball.radius + this.width * 0.45)) {
      // If ball is falling from above or slamming -> STOMP DEFENDER!
      if (ball.vy > 1.0 && ball.y < this.y - 4) {
        this.alive = false;
        ball.vy = ball.isSlamming ? SLAM_REBOUND : JUMP_BOUNCE;
        ball.isSlamming = false;
        ball.hasDoubleJumped = false;
        level.score += 200;
        Audio.playStomp();
        level.spawnBurst(this.x, this.y, '#4d908e', 14);
        level.addFloatingText('+200 DUNK!', this.x, this.y - 20, '#06d6a0');
        level.addScreenShake(5);
      } else {
        // Player popped by defender!
        ball.kill('Blocked by defender!');
      }
    }
  }

  draw(ctx, camera) {
    if (!this.alive) return;
    const screenX = Math.round(this.x - camera.x - this.width / 2);
    const screenY = Math.round(this.y - camera.y - this.height / 2);
    const chars = Assets.images.characters;

    if (chars) {
      let charCol = 0;
      let charRow = 0;
      if (this.type === 'walker') {
        charCol = this.frame; // 0 or 1 (walker animation)
        charRow = 0;
      } else if (this.type === 'crawler') {
        charCol = 6 + this.frame; // spike crawler
        charRow = 1;
      } else if (this.type === 'flyer') {
        charCol = 3 + this.frame; // flying bat
        charRow = 2;
      }

      ctx.save();
      if (this.vx < 0) {
        ctx.translate(screenX + this.width, screenY);
        ctx.scale(-1, 1);
        ctx.drawImage(chars, charCol * 24, charRow * 24, 24, 24, 0, 0, this.width, this.height);
      } else {
        ctx.drawImage(chars, charCol * 24, charRow * 24, 24, 24, screenX, screenY, this.width, this.height);
      }
      ctx.restore();
    } else {
      ctx.fillStyle = '#e63946';
      ctx.fillRect(screenX, screenY, this.width, this.height);
    }
  }
}

// Moving Platform
class MovingPlatform {
  constructor(x, y, rangeX, rangeY, speed = 1.0, widthInTiles = 3) {
    this.startX = x;
    this.startY = y;
    this.x = x;
    this.y = y;
    this.rangeX = rangeX;
    this.rangeY = rangeY;
    this.speed = speed;
    this.progress = 0;
    this.width = widthInTiles * 36;
    this.height = 18;
  }

  update(ball) {
    this.progress += 0.02 * this.speed;
    const prevX = this.x;
    const prevY = this.y;

    this.x = this.startX + Math.sin(this.progress) * this.rangeX;
    this.y = this.startY + Math.cos(this.progress) * this.rangeY;

    const dx = this.x - prevX;
    const dy = this.y - prevY;

    // Check if ball is standing on platform
    if (ball.vy >= 0 &&
        ball.x >= this.x - 10 &&
        ball.x <= this.x + this.width + 10 &&
        ball.y + ball.radius >= this.y - 4 &&
        ball.y + ball.radius <= this.y + 16) {
      ball.y = this.y - ball.radius;
      ball.x += dx;
      ball.isGrounded = true;
      ball.hasDoubleJumped = false;
      ball.vy = BASE_BOUNCE;
      Audio.playBounce(0.8);
      ball.scaleX = 1.3;
      ball.scaleY = 0.7;
    }
  }

  draw(ctx, camera) {
    const tm = Assets.images.tilemap;
    const screenX = Math.round(this.x - camera.x);
    const screenY = Math.round(this.y - camera.y);

    if (tm) {
      const tileCount = Math.floor(this.width / 36);
      for (let i = 0; i < tileCount; i++) {
        const sx = screenX + i * 36;
        let tileId = 46; // middle stone/wood platform
        if (i === 0) tileId = 45; // left edge
        if (i === tileCount - 1) tileId = 47; // right edge
        const col = tileId % 20;
        const row = Math.floor(tileId / 20);
        ctx.drawImage(tm, col * 18, row * 18, 18, 18, sx, screenY, 36, 36);
      }
    } else {
      ctx.fillStyle = '#f4a261';
      ctx.fillRect(screenX, screenY, this.width, this.height);
    }
  }
}

// Cloth / Verlet Mesh Simulation for the Basketball Net
class NetCloth {
  constructor(rimLeftX, rimRightX, rimY) {
    this.leftX = rimLeftX;
    this.rightX = rimRightX;
    this.y = rimY;
    this.points = [];
    this.constraints = [];
    this.initMesh();
  }

  initMesh() {
    this.points = [];
    this.constraints = [];
    const cols = 5;
    const rows = 5;
    const w = this.rightX - this.leftX;
    const h = 42;

    for (let r = 0; r < rows; r++) {
      const rowY = this.y + (r / (rows - 1)) * h;
      // Net narrows slightly as it goes down
      const rowWidth = w * (1.0 - (r / rows) * 0.32);
      const rowStartX = this.leftX + (w - rowWidth) / 2;

      for (let c = 0; c < cols; c++) {
        const px = rowStartX + (c / (cols - 1)) * rowWidth;
        const pinned = (r === 0); // Top row pinned to the rim!
        this.points.push({
          x: px,
          y: rowY,
          oldX: px,
          oldY: rowY,
          pinned: pinned
        });
      }
    }

    // Connect horizontal and vertical constraints
    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        const idx = r * cols + c;
        // Right neighbor
        if (c < cols - 1) {
          const rightIdx = idx + 1;
          const dist = Math.hypot(this.points[idx].x - this.points[rightIdx].x, this.points[idx].y - this.points[rightIdx].y);
          this.constraints.push({ p1: idx, p2: rightIdx, length: dist });
        }
        // Bottom neighbor
        if (r < rows - 1) {
          const downIdx = idx + cols;
          const dist = Math.hypot(this.points[idx].x - this.points[downIdx].x, this.points[idx].y - this.points[downIdx].y);
          this.constraints.push({ p1: idx, p2: downIdx, length: dist });
        }
      }
    }
  }

  update(ball) {
    const gravity = 0.15;
    // Verlet integration
    for (const p of this.points) {
      if (p.pinned) continue;
      const vx = (p.x - p.oldX) * 0.92;
      const vy = (p.y - p.oldY) * 0.92;
      p.oldX = p.x;
      p.oldY = p.y;
      p.x += vx;
      p.y += vy + gravity;

      // Ball collision pushing the net cloth
      if (ball) {
        const dx = p.x - ball.x;
        const dy = p.y - ball.y;
        const dist = Math.hypot(dx, dy);
        if (dist < ball.radius + 3 && dist > 0.001) {
          const push = (ball.radius + 3 - dist);
          p.x += (dx / dist) * push * 0.7;
          p.y += (dy / dist) * push * 0.7;
        }
      }
    }

    // Solve constraints 3 iterations
    for (let iter = 0; iter < 3; iter++) {
      for (const c of this.constraints) {
        const p1 = this.points[c.p1];
        const p2 = this.points[c.p2];
        const dx = p2.x - p1.x;
        const dy = p2.y - p1.y;
        const dist = Math.hypot(dx, dy);
        if (dist > 0.0001) {
          const diff = (dist - c.length) / dist;
          if (!p1.pinned) {
            p1.x += dx * 0.5 * diff;
            p1.y += dy * 0.5 * diff;
          }
          if (!p2.pinned) {
            p2.x -= dx * 0.5 * diff;
            p2.y -= dy * 0.5 * diff;
          }
        }
      }
    }
  }

  draw(ctx, camera) {
    ctx.save();
    ctx.strokeStyle = '#ffffff';
    ctx.lineWidth = 1.5;
    ctx.globalAlpha = 0.9;

    for (const c of this.constraints) {
      const p1 = this.points[c.p1];
      const p2 = this.points[c.p2];
      ctx.beginPath();
      ctx.moveTo(Math.round(p1.x - camera.x), Math.round(p1.y - camera.y));
      ctx.lineTo(Math.round(p2.x - camera.x), Math.round(p2.y - camera.y));
      ctx.stroke();
    }
    ctx.restore();
  }
}

// Final Climax: Championship Basketball Hoop & Backboard
class BasketballHoop {
  constructor(x, y) {
    this.x = x;
    this.y = y;
    this.rimWidth = 44;
    this.rimHeight = 6;
    this.rimLeft = x - this.rimWidth / 2;
    this.rimRight = x + this.rimWidth / 2;
    this.rimY = y;

    // Backboard dimensions
    this.backboardX = this.rimRight + 3;
    this.backboardY = y - 56;
    this.backboardW = 8;
    this.backboardH = 75;

    // Pole
    this.poleX = this.backboardX + this.backboardW;
    this.poleW = 12;

    // Net
    this.net = new NetCloth(this.rimLeft, this.rimRight, this.rimY);
    this.scored = false;
    this.scoredTimer = 0;
    this.isSwish = true;
  }

  update(ball, level) {
    this.net.update(ball);

    if (!ball.isShooting) return;

    // 1. Backboard collision
    if (ball.x + ball.radius >= this.backboardX &&
        ball.x - ball.radius <= this.backboardX + this.backboardW &&
        ball.y >= this.backboardY &&
        ball.y <= this.backboardY + this.backboardH) {
      ball.x = this.backboardX - ball.radius;
      ball.vx = -Math.abs(ball.vx) * 0.55; // Rebound off backboard
      ball.vy *= 0.85;
      this.isSwish = false;
      Audio.playRim();
      level.addScreenShake(3);
      level.spawnBurst(this.backboardX, ball.y, '#e76f51', 6);
    }

    // 2. Rim edges collision (Left tip & Right tip)
    const tips = [
      { x: this.rimLeft, y: this.rimY },
      { x: this.rimRight, y: this.rimY }
    ];

    tips.forEach(tip => {
      const dx = ball.x - tip.x;
      const dy = ball.y - tip.y;
      const dist = Math.hypot(dx, dy);
      if (dist < ball.radius + 3) {
        this.isSwish = false;
        Audio.playRim();
        level.addScreenShake(3);
        const nx = dx / dist;
        const ny = dy / dist;
        // Reflect velocity along rim normal with bounce restitution
        const dot = ball.vx * nx + ball.vy * ny;
        if (dot < 0) {
          ball.vx -= 1.6 * dot * nx;
          ball.vy -= 1.6 * dot * ny;
          ball.vx += (Math.random() - 0.5) * 1.5; // slight rattle jitter
        }
        ball.x = tip.x + nx * (ball.radius + 3);
        ball.y = tip.y + ny * (ball.radius + 3);
      }
    });

    // 3. Goal Detection: Ball passing downward through the rim plane between left and right tips!
    const prevY = ball.y - ball.vy;
    if (!this.scored &&
        prevY <= this.rimY &&
        ball.y >= this.rimY &&
        ball.x > this.rimLeft + 5 &&
        ball.x < this.rimRight - 5 &&
        ball.vy > 0) {
      this.scored = true;
      ball.shotComplete = true;
      Audio.playSwish();
      Audio.playCheer();
      Audio.playBuzzer();
      level.addScreenShake(10);

      // Trigger Confetti explosion
      for (let i = 0; i < 90; i++) {
        const colors = ['#f72585', '#7209b7', '#3a0ca3', '#4361ee', '#4cc9f0', '#ffd166', '#06d6a0'];
        const col = colors[Math.floor(Math.random() * colors.length)];
        level.particles.push(new Particle(
          this.x + (Math.random() - 0.5) * 40,
          this.y + (Math.random() - 0.5) * 20,
          (Math.random() - 0.5) * 9,
          -Math.random() * 8 - 3,
          col,
          Math.random() * 5 + 3,
          80,
          0.16,
          'confetti'
        ));
      }

      if (this.isSwish) {
        level.score += 1000;
        level.addFloatingText('🔥 CLEAN SWISH! +1000 PTS! 🔥', this.x - 30, this.y - 70, '#ffd166');
      } else {
        level.score += 600;
        level.addFloatingText('🏀 IT GOES IN! +600 PTS! 🏀', this.x - 20, this.y - 70, '#06d6a0');
      }
    }
  }

  draw(ctx, camera) {
    const rx = Math.round(this.x - camera.x);
    const ry = Math.round(this.y - camera.y);
    const bbx = Math.round(this.backboardX - camera.x);
    const bby = Math.round(this.backboardY - camera.y);

    // Support Pole
    ctx.fillStyle = '#495057';
    ctx.fillRect(bbx + this.backboardW, bby + 20, this.poleW, 200);

    // Mounting Bracket
    ctx.fillStyle = '#6c757d';
    ctx.fillRect(bbx - 8, ry - 3, 10, 6);

    // Backboard (Glass with red border & target box)
    ctx.fillStyle = 'rgba(230, 240, 255, 0.85)';
    ctx.fillRect(bbx, bby, this.backboardW, this.backboardH);
    ctx.strokeStyle = '#e63946';
    ctx.lineWidth = 2;
    ctx.strokeRect(bbx, bby, this.backboardW, this.backboardH);

    // Backboard inner target square
    ctx.fillStyle = '#e63946';
    ctx.fillRect(bbx, ry - 22, this.backboardW, 18);

    // Draw the simulated net cloth
    this.net.draw(ctx, camera);

    // Front Rim (Orange Steel)
    const rimScreenLeft = Math.round(this.rimLeft - camera.x);
    const rimScreenRight = Math.round(this.rimRight - camera.x);
    ctx.save();
    ctx.strokeStyle = '#f77f00';
    ctx.lineWidth = 4;
    ctx.beginPath();
    ctx.moveTo(rimScreenLeft, ry);
    ctx.lineTo(rimScreenRight, ry);
    ctx.stroke();

    // Rim tips (bolts)
    ctx.fillStyle = '#d62828';
    ctx.beginPath();
    ctx.arc(rimScreenLeft, ry, 3.5, 0, Math.PI * 2);
    ctx.arc(rimScreenRight, ry, 3.5, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }
}