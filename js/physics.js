// Physics Engine & Ball Dynamics for Basketball Bounceback
const GRAVITY = 0.58;
const BASE_BOUNCE = -9.8;
const JUMP_BOUNCE = -14.2;
const SPRING_BOUNCE = -18.5;
const SLAM_SPEED = 16.0;
const SLAM_REBOUND = -15.5;

class Ball {
  constructor(x, y) {
    this.startX = x;
    this.startY = y;
    this.reset();
  }

  reset() {
    this.x = this.startX;
    this.y = this.startY;
    this.vx = 0;
    this.vy = 0;
    this.radius = 15;
    this.angle = 0;
    this.va = 0;
    this.scaleX = 1.0;
    this.scaleY = 1.0;
    this.isGrounded = false;
    this.isSlamming = false;
    this.hasDoubleJumped = false;
    this.alive = true;
    this.popped = false;
    this.trail = [];
    this.inShootingZone = false;
    this.isShooting = false;
    this.shotComplete = false;
    this.selectedSkin = 0; // 1 = Basketball, 0 = Tennis, 2 = Soccer, 3 = 8-Ball, 4 = Beach, 5 = Baseball
  }

  update(input, level) {
    if (!this.alive || this.inShootingZone) return;

    // Horizontal Movement
    const accel = 0.65;
    const maxSpeed = 5.2;
    const friction = 0.88;

    if (input.left) {
      this.vx -= accel;
      if (this.vx < -maxSpeed) this.vx = -maxSpeed;
    } else if (input.right) {
      this.vx += accel;
      if (this.vx > maxSpeed) this.vx = maxSpeed;
    } else {
      this.vx *= friction;
      if (Math.abs(this.vx) < 0.05) this.vx = 0;
    }

    // Slam / Ground Pound
    if (input.down && !this.isGrounded && !this.isSlamming) {
      this.isSlamming = true;
      this.vy = SLAM_SPEED;
      this.vx *= 0.3;
      Audio.playSlam();
      level.addScreenShake(6);
    }

    // Air recovery / double jump
    if (input.jumpPressed && !this.isGrounded && !this.hasDoubleJumped && !this.isSlamming) {
      this.hasDoubleJumped = true;
      this.vy = JUMP_BOUNCE * 0.85;
      Audio.playJump();
      this.scaleX = 0.8;
      this.scaleY = 1.3;
      level.spawnBurst(this.x, this.y, '#ffffff', 8);
    }

    // Apply Gravity
    if (!this.isSlamming) {
      this.vy += GRAVITY;
      if (this.vy > 14) this.vy = 14;
    }

    // Rotate ball based on horizontal velocity & air spin
    this.va = this.vx * 0.04 + (this.isSlamming ? 0.2 : 0);
    this.angle += this.va;

    // Smoothly restore squash & stretch to 1.0
    this.scaleX += (1.0 - this.scaleX) * 0.18;
    this.scaleY += (1.0 - this.scaleY) * 0.18;

    // Movement integration & tile collisions
    this.x += this.vx;
    this.resolveTileCollisionsX(level);

    this.y += this.vy;
    this.resolveTileCollisionsY(level, input);

    // Save trail for high speed
    if (Math.abs(this.vx) > 3.5 || Math.abs(this.vy) > 10 || this.isSlamming) {
      this.trail.push({ x: this.x, y: this.y, angle: this.angle, alpha: 0.6 });
      if (this.trail.length > 7) this.trail.shift();
    } else if (this.trail.length > 0) {
      this.trail.shift();
    }

    // Check bottom boundary (fall into pit)
    if (this.y > level.heightInTiles * level.tileSize + 60) {
      this.kill('Fell into pit');
    }
  }

  resolveTileCollisionsX(level) {
    const ts = level.tileSize;
    const minTileX = Math.floor((this.x - this.radius) / ts);
    const maxTileX = Math.floor((this.x + this.radius) / ts);
    const minTileY = Math.floor((this.y - this.radius + 2) / ts);
    const maxTileY = Math.floor((this.y + this.radius - 2) / ts);

    for (let ty = minTileY; ty <= maxTileY; ty++) {
      for (let tx = minTileX; tx <= maxTileX; tx++) {
        const tile = level.getTile(tx, ty);
        if (tile && tile.solid && !tile.oneWay) {
          if (this.vx > 0) {
            this.x = tx * ts - this.radius;
            this.vx = -this.vx * 0.5; // Wall bounce
            Audio.playBounce(0.6);
            this.scaleX = 0.75;
            this.scaleY = 1.25;
          } else if (this.vx < 0) {
            this.x = (tx + 1) * ts + this.radius;
            this.vx = -this.vx * 0.5;
            Audio.playBounce(0.6);
            this.scaleX = 0.75;
            this.scaleY = 1.25;
          }
        }
      }
    }
  }

  resolveTileCollisionsY(level, input) {
    const ts = level.tileSize;
    const minTileX = Math.floor((this.x - this.radius + 3) / ts);
    const maxTileX = Math.floor((this.x + this.radius - 3) / ts);
    const minTileY = Math.floor((this.y - this.radius) / ts);
    const maxTileY = Math.floor((this.y + this.radius) / ts);

    this.isGrounded = false;

    for (let ty = minTileY; ty <= maxTileY; ty++) {
      for (let tx = minTileX; tx <= maxTileX; tx++) {
        const tile = level.getTile(tx, ty);
        if (!tile) continue;

        // Spike collision (hazard)
        if (tile.isSpike) {
          const spikeBox = {
            x: tx * ts + 4,
            y: ty * ts + 6,
            w: ts - 8,
            h: ts - 6
          };
          if (this.intersectsRect(spikeBox)) {
            this.kill('Popped by spikes!');
            return;
          }
        }

        // Spring trampoline
        if (tile.isSpring) {
          const springBox = { x: tx * ts, y: ty * ts + 6, w: ts, h: ts - 6 };
          if (this.intersectsRect(springBox) && this.vy > 0) {
            this.y = ty * ts - this.radius;
            this.vy = SPRING_BOUNCE;
            this.isSlamming = false;
            this.hasDoubleJumped = false;
            this.scaleX = 0.65;
            this.scaleY = 1.45;
            level.triggerSpring(tx, ty);
            Audio.playSpring();
            level.addScreenShake(4);
            return;
          }
        }

        // Solid floor/ceiling collision
        if (tile.solid) {
          if (tile.oneWay) {
            // One-way platform: only land when falling downward and feet cross top surface
            const prevY = this.y - this.vy;
            if (this.vy > 0 && prevY + this.radius <= ty * ts + 8 && this.y + this.radius >= ty * ts) {
              this.handleGroundImpact(ty * ts, input, level);
              return;
            }
          } else {
            // Full solid block
            if (this.vy > 0) { // Landing on ground
              this.handleGroundImpact(ty * ts, input, level);
              return;
            } else if (this.vy < 0) { // Hitting ceiling
              this.y = (ty + 1) * ts + this.radius;
              this.vy = 0;
              this.scaleX = 1.3;
              this.scaleY = 0.7;
              Audio.playBounce(0.5);
              return;
            }
          }
        }
      }
    }
  }

  handleGroundImpact(groundY, input, level) {
    this.y = groundY - this.radius;
    this.isGrounded = true;
    this.hasDoubleJumped = false;

    if (this.isSlamming) {
      this.isSlamming = false;
      this.vy = SLAM_REBOUND;
      this.scaleX = 1.5;
      this.scaleY = 0.55;
      Audio.playBounce(1.5);
      level.addScreenShake(8);
      level.spawnDust(this.x, this.y + this.radius, 14);
      level.defeatNearbyEnemies(this.x, this.y, 80);
      return;
    }

    // Normal Bounce vs Boost Jump Bounce
    const bounceForce = Math.abs(this.vy);
    const volume = Math.min(1.2, Math.max(0.4, bounceForce / 8));
    Audio.playBounce(volume);

    // If Jump key is held or pressed upon impact, boost the bounce!
    if (input.jump || input.jumpPressed) {
      this.vy = JUMP_BOUNCE;
      Audio.playJump();
      this.scaleX = 0.75;
      this.scaleY = 1.35;
      level.spawnDust(this.x, this.y + this.radius, 6);
    } else {
      this.vy = BASE_BOUNCE;
      this.scaleX = 1.3;
      this.scaleY = 0.7;
      level.spawnDust(this.x, this.y + this.radius, 4);
    }
  }

  intersectsRect(r) {
    const cx = Math.max(r.x, Math.min(this.x, r.x + r.w));
    const cy = Math.max(r.y, Math.min(this.y, r.y + r.h));
    const distSq = (this.x - cx) * (this.x - cx) + (this.y - cy) * (this.y - cy);
    return distSq < (this.radius * this.radius);
  }

  kill(reason) {
    if (!this.alive) return;
    this.alive = false;
    this.popped = true;
    Audio.playHit();
  }
}
