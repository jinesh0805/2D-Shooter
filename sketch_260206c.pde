// --- GLOBAL VARIABLES ---
ArrayList<Bullet> bullets;
ArrayList<Enemy> enemies;
ArrayList<GunPickup> pickups; 

int score = 0;
boolean gameOver = false;

// WORLD VARIABLES
float worldWidth = 5000;
float worldHeight = 5000;

// Player Variables
float playerX, playerY;
float playerSize = 100; 
float playerSpeed = 10; // INCREASED SPEED (Was 7)

// Gun System
int currentGun = 0; // 0=None, 1=Pistol, 2=AK47, 3=Shotgun, 4=Sniper
int gunCooldown = 0; 
int pickupTimer = 0; 

// AMMO & RELOAD SYSTEM
int maxAmmo = 300;       
int currentAmmo = 0;   
boolean isReloading = false;
int reloadTimer = 0;
int reloadTimeNeeded = 0; 

// Images
PImage imgPlayerNoGun, imgPistol, imgAK, imgShotgun, imgSniper, imgEnemy;

// Inputs
boolean up, down, left, right;
boolean isShooting = false; 

void setup() {
  fullScreen(); 
  
  // --- IMAGE LOADING ---
  imgPlayerNoGun = loadImage("nogun.png");
  imgPistol = loadImage("images.png");      
  imgAK = loadImage("Ak47.png");            
  imgShotgun = loadImage("Shotgun.png");    
  imgSniper = loadImage("snipper.png");     
  imgEnemy = loadImage("enemy.png");
  
  bullets = new ArrayList<Bullet>();
  enemies = new ArrayList<Enemy>();
  pickups = new ArrayList<GunPickup>();
  
  playerX = worldWidth/2;
  playerY = worldHeight/2;
  
  pickups.add(new GunPickup(playerX + 300, playerY));
  
  rectMode(CENTER);
  imageMode(CENTER);
  textAlign(CENTER, CENTER);
  noStroke();
}

void draw() {
  if (gameOver) {
    background(20);
    displayGameOver();
  } else {
    playGame();
  }
}

void playGame() {
  background(20); 
  
  // --- 1. MOVEMENT LOGIC (IMPROVED) ---
  float moveX = 0;
  float moveY = 0;

  if (up)    moveY = -1;
  if (down)  moveY = 1;
  if (left)  moveX = -1;
  if (right) moveX = 1;

  // Normalize Vector (Fixes diagonal speed boost)
  if (moveX != 0 || moveY != 0) {
    // This makes sure you don't run faster diagonally
    float magnitude = sqrt(moveX*moveX + moveY*moveY);
    moveX /= magnitude;
    moveY /= magnitude;
    
    // Apply Speed
    playerX += moveX * playerSpeed;
    playerY += moveY * playerSpeed;
  }

  // Constrain player to world bounds
  playerX = constrain(playerX, playerSize/2, worldWidth - playerSize/2);
  playerY = constrain(playerY, playerSize/2, worldHeight - playerSize/2);

  // --- 2. CAMERA ---
  pushMatrix();
  translate(width/2 - playerX, height/2 - playerY);
  
  // Draw Grid 
  noFill(); stroke(255); rect(worldWidth/2, worldHeight/2, worldWidth, worldHeight);
  stroke(40);
  for(int x=0; x<=worldWidth; x+=200) line(x, 0, x, worldHeight);
  for(int y=0; y<=worldHeight; y+=200) line(0, y, worldWidth, y);
  noStroke();

  // --- 3. DRAW PLAYER ---
  pushMatrix();
  translate(playerX, playerY);
  
  float angle = atan2(mouseY - height/2, mouseX - width/2);
  rotate(angle); 
  
  // Draw the correct sprite based on gun
  if (currentGun == 0) {
    if (imgPlayerNoGun != null) image(imgPlayerNoGun, 0, 0, 180, 180);
    else { fill(0, 255, 255); ellipse(0,0,100,100); }
  } 
  else if (currentGun == 1) { if (imgPistol != null) image(imgPistol, 0, 0, 200, 200); } 
  else if (currentGun == 2) { if (imgAK != null) image(imgAK, 10, 0, 250, 200); } 
  else if (currentGun == 3) { if (imgShotgun != null) image(imgShotgun, 10, 0, 250, 200); } 
  else if (currentGun == 4) { if (imgSniper != null) image(imgSniper, 10, 0, 280, 200); }
  
  popMatrix(); 

  // --- 4. RELOAD LOGIC ---
  if (isReloading) {
    reloadTimer--;
    
    // Draw Reload Bar above player
    fill(50); rect(playerX, playerY - 100, 100, 15);
    fill(255, 255, 0); 
    float barWidth = map(reloadTimer, reloadTimeNeeded, 0, 0, 100);
    rect(playerX - 50 + barWidth/2, playerY - 100, barWidth, 15);
    
    fill(255); textSize(20); text("RELOADING...", playerX, playerY - 120);
    
    if (reloadTimer <= 0) {
      isReloading = false;
      currentAmmo = maxAmmo; 
    }
  }

  // --- 5. SHOOTING ---
  if (gunCooldown > 0) gunCooldown--;
  
  if (isShooting && currentGun > 0 && gunCooldown == 0 && !isReloading) {
    if (currentAmmo > 0) {
      fireGun(angle);
      currentAmmo--; 
    } else {
      startReload(); 
    }
  }

  // --- 6. PICKUPS ---
  pickupTimer++;
  if (pickupTimer > 180) { 
    pickups.add(new GunPickup(random(100, worldWidth-100), random(100, worldHeight-100)));
    pickupTimer = 0;
  }
  
  for (int i = pickups.size() - 1; i >= 0; i--) {
    GunPickup p = pickups.get(i);
    p.display();
    if (dist(playerX, playerY, p.x, p.y) < 100) { 
       equipGun(p.type); 
       score += 50;
       pickups.remove(i);
    }
  }

  // --- 7. LOGIC ---
  handleEnemies();
  handleBullets();
  
  popMatrix(); 
  
  // --- UI ---
  fill(255); textSize(50); 
  text("Score: " + score, 150, 80);
  
  // WEAPON UI
  textAlign(RIGHT, BOTTOM);
  
  String gunName = "Knife";
  if(currentGun==1) gunName="Pistol";
  if(currentGun==2) gunName="AK-47";
  if(currentGun==3) gunName="Shotgun";
  if(currentGun==4) gunName="Sniper";
  
  if (currentGun > 0) {
    if (isReloading) {
      fill(255, 255, 0);
      text("RELOADING", width - 50, height - 100);
    } else {
      if(currentAmmo < maxAmmo * 0.3) fill(255, 50, 50);
      else fill(255);
      text(currentAmmo + " / " + maxAmmo, width - 50, height - 100);
    }
  }
  
  fill(255); textSize(40);
  text(gunName, width - 50, height - 50);
  textAlign(CENTER, CENTER); 
}

// --- HELPER: Set Gun Stats ---
void equipGun(int type) {
  currentGun = type;
  isReloading = false;
  
  if (type == 1) { maxAmmo = 12; reloadTimeNeeded = 60; } // Pistol
  else if (type == 2) { maxAmmo = 30; reloadTimeNeeded = 90; } // AK
  else if (type == 3) { maxAmmo = 6;  reloadTimeNeeded = 100; } // Shotgun
  else if (type == 4) { maxAmmo = 5;  reloadTimeNeeded = 120; } // Sniper
  
  currentAmmo = maxAmmo; 
}

void startReload() {
  if (currentGun > 0 && currentAmmo < maxAmmo) {
    isReloading = true;
    reloadTimer = reloadTimeNeeded;
  }
}

void fireGun(float angle) {
  float barrelLen = 80;
  if (currentGun == 2) barrelLen = 130; 
  if (currentGun == 3) barrelLen = 130; 
  if (currentGun == 4) barrelLen = 160; 

  float spawnX = playerX + cos(angle) * barrelLen;
  float spawnY = playerY + sin(angle) * barrelLen;

  if (currentGun == 1) { 
    bullets.add(new Bullet(spawnX, spawnY, angle, 18));
    gunCooldown = 20; 
  } else if (currentGun == 2) { 
    float spread = random(-0.1, 0.1); 
    bullets.add(new Bullet(spawnX, spawnY, angle + spread, 22));
    gunCooldown = 6; 
  } else if (currentGun == 3) { 
    bullets.add(new Bullet(spawnX, spawnY, angle, 18));
    bullets.add(new Bullet(spawnX, spawnY, angle - 0.15, 18));
    bullets.add(new Bullet(spawnX, spawnY, angle + 0.15, 18));
    gunCooldown = 45; 
  } else if (currentGun == 4) { 
    bullets.add(new Bullet(spawnX, spawnY, angle, 35)); 
    gunCooldown = 60; 
  }
}

void handleBullets() {
  for (int i = bullets.size() - 1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    b.update();
    b.display();
    if (b.x < 0 || b.x > worldWidth || b.y < 0 || b.y > worldHeight) bullets.remove(i);
  }
}

void handleEnemies() {
  int difficultyFactor = score / 50; 
  int currentSpawnRate = 60 - difficultyFactor;
  if (currentSpawnRate < 15) currentSpawnRate = 15; 
  
  if (frameCount % currentSpawnRate == 0) enemies.add(new Enemy());
  
  for (int i = enemies.size() - 1; i >= 0; i--) {
    Enemy e = enemies.get(i);
    e.update();
    e.display();
    
    if (dist(e.x, e.y, playerX, playerY) < 100) gameOver = true;
    
    for (int j = bullets.size() - 1; j >= 0; j--) {
      Bullet b = bullets.get(j);
      if (dist(e.x, e.y, b.x, b.y) < (e.size/2 + b.size/2)) {
        score += 10;
        enemies.remove(i);
        bullets.remove(j);
        break; 
      }
    }
  }
}

void displayGameOver() {
  fill(255, 0, 0); textSize(100);
  text("GAME OVER", width/2, height/2);
  textSize(50); fill(255);
  text("Score: " + score, width/2, height/2 + 120);
  text("Press R to Restart", width/2, height/2 + 200);
}

// --- INPUTS ---
void mousePressed() { isShooting = true; }
void mouseReleased() { isShooting = false; }
void keyPressed() {
  if (key == 'w' || key == 'W') up = true;
  if (key == 's' || key == 'S') down = true;
  if (key == 'a' || key == 'A') left = true;
  if (key == 'd' || key == 'D') right = true;
  if (key == 'r' || key == 'R') {
    if (gameOver) resetGame();
    else startReload(); 
  }
}
void keyReleased() {
  if (key == 'w' || key == 'W') up = false;
  if (key == 's' || key == 'S') down = false;
  if (key == 'a' || key == 'A') left = false;
  if (key == 'd' || key == 'D') right = false;
}
void resetGame() {
  score = 0; bullets.clear(); enemies.clear(); pickups.clear();
  currentGun = 0; playerX = worldWidth/2; playerY = worldHeight/2;
  gameOver = false; pickups.add(new GunPickup(playerX + 300, playerY));
}

// --- CLASSES ---
class Bullet {
  float x, y, vx, vy, size;
  Bullet(float startX, float startY, float angle, float speed) {
    x = startX; y = startY;
    vx = cos(angle) * speed; vy = sin(angle) * speed; size = 15;
  }
  void update() { x += vx; y += vy; }
  void display() { fill(255, 255, 0); ellipse(x, y, size, size); }
}

class Enemy {
  float x, y, speed, size;
  Enemy() {
    size = 200; 
    speed = random(2, 4.5);
    float angle = random(TWO_PI);
    float dist = random(1000, 1800); 
    x = playerX + cos(angle) * dist;
    y = playerY + sin(angle) * dist;
    if(x < 0) x = 0; if(x > worldWidth) x = worldWidth;
    if(y < 0) y = 0; if(y > worldHeight) y = worldHeight;
  }
  void update() {
    float angle = atan2(playerY - y, playerX - x);
    x += cos(angle) * speed; y += sin(angle) * speed;
  }
  void display() {
    pushMatrix();
    translate(x, y);
    float angle = atan2(playerY - y, playerX - x);
    rotate(angle + PI/2);
    if (imgEnemy != null) image(imgEnemy, 0, 0, 250, 250); 
    else { fill(255, 0, 100); rect(0, 0, size, size); }
    popMatrix();
  }
}

class GunPickup {
  float x, y;
  int type; 
  GunPickup(float px, float py) {
    x = px; y = py;
    type = int(random(1, 5)); 
  }
  void display() {
    noStroke(); fill(0, 255, 0, 100); ellipse(x, y, 150, 150); 
    if(type == 1 && imgPistol != null) image(imgPistol, x, y, 100, 100);
    else if(type == 2 && imgAK != null) image(imgAK, x, y, 100, 100);
    else if(type == 3 && imgShotgun != null) image(imgShotgun, x, y, 100, 100);
    else if(type == 4 && imgSniper != null) image(imgSniper, x, y, 100, 100);
    else { fill(255); textSize(30); text("GUN", x, y); }
  }
}
