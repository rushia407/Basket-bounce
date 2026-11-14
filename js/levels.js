// Level Definitions and World Construction for Basketball Bounceback

class Level {
  constructor(index, data) {
    this.index = index;
    this.name = data.name;
    this.theme = data.theme; // 'street', 'rooftop', 'arena'
    this.tileSize = 36;
    this.widthInTiles = data.map[0].length;
    this.heightInTiles = data.map.length;
    this.rawMap = data.map;

    this.tiles = [];
    this.stars = [];
    this.defenders = [];
    this.movingPlatforms = [];
    this.particles = [];
    this.floatingTexts = [];
    this.hoop = null;
    this.shootingZoneX = 0;
    this.playerStartX = 72;
    this.playerStartY = 300;

    this.score = 0;
    this.starsCollected = 0;
    this.totalStars = 0;
    this.screenShake = 0;
    this.springAnimations = {}; // tx,ty -> timer

    this.parseMap(data);
  }

  parseMap(data) {
    let starId = 0;
    for (let y = 0; y < this.heightInTiles; y++) {
      this.tiles[y] = [];
      for (let x = 0; x < this.widthInTiles; x++) {
        const val = this.rawMap[y][x];
        let tileObj = null;

        if (val === 1) { // Ground surface
          tileObj = { solid: true, tileId: 1 };
        } else if (val === 2) { // Ground fill / dirt
          tileObj = { solid: true, tileId: 21 };
        } else if (val === 3) { // Brick / solid block
          tileObj = { solid: true, tileId: 41 };
        } else if (val === 4) { // One-way wooden bridge platform
          tileObj = { solid: true, oneWay: true, tileId: 85 };
        } else if (val === 5) { // Floor spike hazard
          tileObj = { isSpike: true, tileId: 68 };
        } else if (val === 6) { // Ceiling spike hazard
          tileObj = { isSpike: true, tileId: 69 };
        } else if (val === 7) { // Spring pad
          tileObj = { isSpring: true, tileId: 107 };
        }

        this.tiles[y][x] = tileObj;

        // Entities parsed from map
        const worldX = x * this.tileSize;
        const worldY = y * this.tileSize;

        if (val === 8) { // Star
          this.stars.push(new Star(worldX + 18, worldY + 18, starId++));
          this.totalStars++;
        } else if (val === 9) { // Walker Defender
          this.defenders.push(new Defender(worldX + 18, worldY + 18, 54, 'walker', 1.2));
        } else if (val === 10) { // Flyer Defender
          this.defenders.push(new Defender(worldX + 18, worldY + 18, 70, 'flyer', 1.5));
        } else if (val === 11) { // Crawler Defender
          this.defenders.push(new Defender(worldX + 18, worldY + 18, 40, 'crawler', 0.9));
        } else if (val === 15) { // Shooting Zone Line
          this.shootingZoneX = worldX;
        } else if (val === 16) { // Basketball Hoop
          this.hoop = new BasketballHoop(worldX + 18, worldY + 18);
        } else if (val === 18) { // Player start
          this.playerStartX = worldX;
          this.playerStartY = worldY;
        }
      }
    }

    // Add moving platforms defined in level data
    if (data.movingPlatforms) {
      data.movingPlatforms.forEach(p => {
        this.movingPlatforms.push(new MovingPlatform(p.x, p.y, p.rangeX, p.rangeY, p.speed, p.width));
      });
    }

    // Default hoop position if not in map
    if (!this.hoop) {
      this.hoop = new BasketballHoop((this.widthInTiles - 4) * this.tileSize, 280);
      this.shootingZoneX = (this.widthInTiles - 12) * this.tileSize;
    }
  }

  getTile(tx, ty) {
    if (ty < 0 || ty >= this.heightInTiles || tx < 0 || tx >= this.widthInTiles) return null;
    return this.tiles[ty][tx];
  }

  triggerSpring(tx, ty) {
    const key = `${tx},${ty}`;
    this.springAnimations[key] = 15; // 15 frames of extended spring animation
  }

  addScreenShake(amount) {
    this.screenShake = Math.max(this.screenShake, amount);
  }

  spawnBurst(x, y, color, count = 10, shape = 'square') {
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = Math.random() * 4 + 1;
      this.particles.push(new Particle(
        x, y,
        Math.cos(angle) * speed,
        Math.sin(angle) * speed,
        color,
        Math.random() * 4 + 2,
        Math.floor(Math.random() * 20 + 15),
        0.15,
        shape
      ));
    }
  }

  spawnDust(x, y, count = 6) {
    for (let i = 0; i < count; i++) {
      this.particles.push(new Particle(
        x + (Math.random() - 0.5) * 12,
        y,
        (Math.random() - 0.5) * 2.5,
        -Math.random() * 2,
        '#d3d3d3',
        Math.random() * 3 + 2,
        18,
        0.05,
        'circle'
      ));
    }
  }

  addFloatingText(text, x, y, color = '#ffffff') {
    this.floatingTexts.push({
      text, x, y, color,
      life: 50,
      maxLife: 50
    });
  }

  defeatNearbyEnemies(x, y, radius) {
    this.defenders.forEach(d => {
      if (d.alive) {
        const dist = Math.hypot(d.x - x, d.y - y);
        if (dist < radius) {
          d.alive = false;
          this.score += 200;
          this.spawnBurst(d.x, d.y, '#e63946', 12);
          this.addFloatingText('+200 SLAM!', d.x, d.y - 15, '#ff4d6d');
        }
      }
    });
  }

  update(ball) {
    if (this.screenShake > 0) this.screenShake *= 0.88;
    if (this.screenShake < 0.2) this.screenShake = 0;

    // Update spring animations
    for (const k in this.springAnimations) {
      this.springAnimations[k]--;
      if (this.springAnimations[k] <= 0) delete this.springAnimations[k];
    }

    // Update Stars
    this.stars.forEach(s => s.update(ball, this));

    // Update Defenders
    this.defenders.forEach(d => d.update(ball, this));

    // Update Moving Platforms
    this.movingPlatforms.forEach(p => p.update(ball));

    // Update Hoop
    if (this.hoop) {
      this.hoop.update(ball, this);
    }

    // Update Particles
    for (let i = this.particles.length - 1; i >= 0; i--) {
      this.particles[i].update();
      if (this.particles[i].life <= 0) {
        this.particles.splice(i, 1);
      }
    }

    // Update Floating Texts
    for (let i = this.floatingTexts.length - 1; i >= 0; i--) {
      const ft = this.floatingTexts[i];
      ft.y -= 0.8;
      ft.life--;
      if (ft.life <= 0) this.floatingTexts.splice(i, 1);
    }
  }

  draw(ctx, camera) {
    const tm = Assets.images.tilemap;
    const ts = this.tileSize;

    const startCol = Math.max(0, Math.floor(camera.x / ts));
    const endCol = Math.min(this.widthInTiles - 1, Math.ceil((camera.x + camera.width) / ts));
    const startRow = Math.max(0, Math.floor(camera.y / ts));
    const endRow = Math.min(this.heightInTiles - 1, Math.ceil((camera.y + camera.height) / ts));

    // Draw Map Tiles
    for (let ty = startRow; ty <= endRow; ty++) {
      for (let tx = startCol; tx <= endCol; tx++) {
        const tile = this.tiles[ty][tx];
        if (!tile) continue;

        const screenX = Math.round(tx * ts - camera.x);
        const screenY = Math.round(ty * ts - camera.y);

        let tileId = tile.tileId;
        // Check spring compression animation
        if (tile.isSpring) {
          const key = `${tx},${ty}`;
          if (this.springAnimations[key] > 0) {
            tileId = 108; // Extended spring tile
          } else {
            tileId = 107; // Normal spring tile
          }
        }

        if (tm) {
          const col = tileId % 20;
          const row = Math.floor(tileId / 20);
          ctx.drawImage(tm, col * 18, row * 18, 18, 18, screenX, screenY, ts, ts);
        } else {
          // Fallback colored rects
          if (tile.isSpike) ctx.fillStyle = '#e63946';
          else if (tile.isSpring) ctx.fillStyle = '#ffbe0b';
          else ctx.fillStyle = '#3a86ff';
          ctx.fillRect(screenX, screenY, ts, ts);
        }
      }
    }

    // Draw Shooting Zone / Free Throw Line
    if (this.shootingZoneX > 0) {
      const lineX = Math.round(this.shootingZoneX - camera.x);
      ctx.save();
      ctx.strokeStyle = '#fca311';
      ctx.setLineDash([8, 6]);
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.moveTo(lineX, 0);
      ctx.lineTo(lineX, camera.height);
      ctx.stroke();

      // Free throw semi-circle arc on court ground
      ctx.setLineDash([]);
      ctx.strokeStyle = 'rgba(252, 163, 17, 0.7)';
      ctx.lineWidth = 3;
      const groundScreenY = Math.round(11 * ts - camera.y);
      ctx.beginPath();
      ctx.arc(lineX + 50, groundScreenY, 65, Math.PI * 0.5, Math.PI * 1.5, true);
      ctx.stroke();

      ctx.font = 'bold 12px "Courier New", monospace';
      ctx.fillStyle = '#fca311';
      ctx.textAlign = 'center';
      ctx.fillText('⚡ BUZZER BEATER ZONE ⚡', lineX - 2, 40);
      ctx.restore();
    }

    // Draw Moving Platforms
    this.movingPlatforms.forEach(p => p.draw(ctx, camera));

    // Draw Stars
    this.stars.forEach(s => s.draw(ctx, camera));

    // Draw Defenders
    this.defenders.forEach(d => d.draw(ctx, camera));

    // Draw Basketball Hoop
    if (this.hoop) {
      this.hoop.draw(ctx, camera);
    }

    // Draw Particles
    this.particles.forEach(p => p.draw(ctx, camera));

    // Draw Floating Texts
    this.floatingTexts.forEach(ft => {
      const alpha = Math.max(0, ft.life / ft.maxLife);
      ctx.save();
      ctx.globalAlpha = alpha;
      ctx.font = 'bold 15px "Courier New", monospace';
      ctx.fillStyle = ft.color;
      ctx.strokeStyle = '#000000';
      ctx.lineWidth = 3;
      const tx = Math.round(ft.x - camera.x);
      const ty = Math.round(ft.y - camera.y);
      ctx.strokeText(ft.text, tx, ty);
      ctx.fillText(ft.text, tx, ty);
      ctx.restore();
    });
  }
}

// 3 Hand-Crafted Game Jam Level Maps
const LEVEL_DATA = [
  // LEVEL 1: Street Court Warmup
  {
    name: 'Level 1: Street Court Warmup',
    theme: 'street',
    map: [
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,4,4,4,0,0,0,0,0,0,0,3,3,3,0,0,0,0,0,0,0,4,4,4,0,0,0,0,0,0,0,0,0,16,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,18,0,0,0,0,0,0,5,0,0,0,0,0,0,0,7,0,0,9,0,0,5,5,0,0,7,0,0,0,9,0,5,0,0,15,0,0,0,0,0,0,0,0,0,0,0,0],
      [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
      [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2]
    ]
  },

  // LEVEL 2: Rooftop Jam (Moving platforms, ceiling spikes, tricky gaps)
  {
    name: 'Level 2: Rooftop Jam',
    theme: 'rooftop',
    map: [
      [6,6,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,4,4,0,0,0,0,0,0,0,3,3,3,0,0,0,0,0,0,0,3,3,3,0,0,0,0,0,0,0,0,16,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,18,0,0,0,5,0,0,11,0,0,7,0,0,0,0,0,0,0,0,0,9,0,0,5,5,0,0,0,0,0,11,0,5,0,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
      [2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2]
    ],
    movingPlatforms: [
      { x: 12 * 36, y: 10 * 36, rangeX: 30, rangeY: 0, speed: 1.2, width: 2 },
      { x: 27 * 36, y: 9 * 36, rangeX: 0, rangeY: 40, speed: 1.5, width: 2 }
    ]
  },

  // LEVEL 3: Championship Arena (Grand Stadium, Flying Bat Defenders, Buzzer Beater Climax)
  {
    name: 'Level 3: Championship Arena',
    theme: 'arena',
    map: [
      [6,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,3,3,0,0,0,0,0,0,0,0,0,0,4,4,4,0,0,0,0,0,0,0,3,3,3,0,0,0,0,0,0,0,0,16,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [0,18,0,0,5,0,0,10,0,0,7,0,0,0,0,0,0,0,9,0,5,5,5,0,0,7,0,0,10,0,0,0,0,11,0,5,5,0,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      [1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
      [2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2]
    ],
    movingPlatforms: [
      { x: 12 * 36, y: 10 * 36, rangeX: 35, rangeY: 0, speed: 1.4, width: 2 },
      { x: 27 * 36, y: 9 * 36, rangeX: 0, rangeY: 45, speed: 1.6, width: 2 }
    ]
  }
];