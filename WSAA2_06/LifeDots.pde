// Data Sedimentation - split tab
// Living red sensor organisms for the left exhibition margin.

final int LIFE_DOT_COUNT = 30;
final int LIFE_PARTICLE_COUNT = 150;

boolean lifeDotsReady = false;
float[] lifeDotX = new float[LIFE_DOT_COUNT];
float[] lifeDotY = new float[LIFE_DOT_COUNT];
float[] lifeDotSize = new float[LIFE_DOT_COUNT];
float[] lifeDotPhase = new float[LIFE_DOT_COUNT];
float[] lifeParticleAngle = new float[LIFE_PARTICLE_COUNT];
float[] lifeParticleRadius = new float[LIFE_PARTICLE_COUNT];
float[] lifeParticleSpeed = new float[LIFE_PARTICLE_COUNT];
float[] lifeParticleSize = new float[LIFE_PARTICLE_COUNT];

float lifePulse = 0;
float lifeScatter = 0;
float lifeWake = 0;

void initLifeDots() {
  for (int i = 0; i < LIFE_DOT_COUNT; i++) {
    float t = LIFE_DOT_COUNT == 1 ? 0 : i / float(LIFE_DOT_COUNT - 1);
    lifeDotY[i] = constrain(t + random(-0.018, 0.018), 0.02, 0.98);
    lifeDotX[i] = constrain(0.54 + sin(t * TWO_PI * 2.1) * 0.10 + random(-0.12, 0.12), 0.22, 0.82);
    lifeDotSize[i] = random(10, 19);
    lifeDotPhase[i] = random(TWO_PI);
  }

  for (int i = 0; i < LIFE_PARTICLE_COUNT; i++) {
    lifeParticleAngle[i] = random(TWO_PI);
    lifeParticleRadius[i] = random(0.04, 0.46);
    lifeParticleSpeed[i] = random(0.0018, 0.0075) * (random(1) < 0.5 ? -1 : 1);
    lifeParticleSize[i] = random(1.3, 3.2);
  }

  lifeDotsReady = true;
}

void updateLifeDots(float dt) {
  if (!lifeDotsReady) initLifeDots();

  float voiceActivity = constrain(map(voiceDelta, 0, max(1, strongVoiceThreshold), 0, 1), 0, 1);
  float distance = displayDistanceCm();
  float distanceActivity = constrain(map(distance, ULTRASONIC_MAX_CM, ULTRASONIC_MIN_CM, 0, 1), 0, 1);
  float motionActivity = motionDetected || pendingMoveSteps > 0 || ultrasonicDataPending ? 1 : 0;
  float sensorLife = constrain(
    voiceActivity * 0.46 +
    distanceActivity * 0.22 +
    machineValidation * 0.22 +
    motionActivity * 0.10,
    0,
    1
  );

  if (!arduinoActive) sensorLife *= 0.36;

  lifePulse = lerp(lifePulse, sensorLife, 0.10);
  lifeScatter = lerp(lifeScatter, max(distanceActivity, motionActivity), 0.075);
  lifeWake = lerp(lifeWake, speaking || externalVoiceCandidate ? 1 : 0, 0.12);

  float speedBoost = 1 + lifePulse * 2.8 + machineValidation * 1.8;
  for (int i = 0; i < LIFE_PARTICLE_COUNT; i++) {
    lifeParticleAngle[i] += lifeParticleSpeed[i] * dt * speedBoost;
  }
}

void drawLifeDots() {
  if (!lifeDotsReady) initLifeDots();

  float left = 24;
  float right = max(left + 120, WIN_X - 34);
  float top = max(56, WIN_Y + 8);
  float bottom = min(height - 90, BINARY_Y + BINARY_H - 6);
  float areaW = right - left;
  float areaH = bottom - top;
  if (areaW < 80 || areaH < 120) return;

  pushStyle();
  rectMode(CORNER);
  noStroke();

  float centerX = left + areaW * 0.55;
  float centerY = top + areaH * 0.50;
  float voiceGlow = constrain(map(voiceDelta, 0, max(1, strongVoiceThreshold), 0, 1), 0, 1);
  float systemGlow = constrain(0.28 + lifePulse * 0.72, 0, 1);
  float breath = 0.5 + 0.5 * sin(frameCount * (0.035 + lifePulse * 0.09));

  drawLifeMainDots(left, top, areaW, areaH, systemGlow, voiceGlow, breath);

  popStyle();
}

void drawLifeParticles(float left, float top, float areaW, float areaH, float centerX, float centerY, float systemGlow, float breath) {
  float orbitW = areaW * (0.24 + lifeScatter * 0.18);
  float orbitH = areaH * (0.24 + lifeWake * 0.16);

  for (int i = 0; i < LIFE_PARTICLE_COUNT; i++) {
    float r = lifeParticleRadius[i];
    float wobble = noise(i * 7.3, frameCount * 0.012) - 0.5;
    float px = centerX + cos(lifeParticleAngle[i]) * orbitW * r + wobble * areaW * 0.10 * lifeScatter;
    float py = centerY + sin(lifeParticleAngle[i] * 1.37) * orbitH * r + wobble * areaH * 0.05;
    float a = 26 + 95 * systemGlow + 45 * breath;
    float s = lifeParticleSize[i] * (0.8 + lifePulse * 1.2);
    fill(255, 0, 0, a);
    ellipse(px, py, s, s);
  }
}

void drawLifeMainDots(float left, float top, float areaW, float areaH, float systemGlow, float voiceGlow, float breath) {
  for (int i = 0; i < LIFE_DOT_COUNT; i++) {
    float wave = sin(frameCount * (0.035 + lifePulse * 0.055) + lifeDotPhase[i]);
    float tremor = (noise(i * 12.1, frameCount * 0.026) - 0.5) * lifeScatter;
    float x = left + areaW * (lifeDotX[i] + tremor * 0.15);
    float y = top + areaH * lifeDotY[i] + wave * (2.0 + lifePulse * 8.0);
    float s = lifeDotSize[i] * (0.85 + breath * 0.18 + voiceGlow * 0.42);
    float alpha = 145 + systemGlow * 90 + voiceGlow * 20;

    fill(255, 0, 0, 28 + alpha * 0.18);
    ellipse(x, y, s * 2.3, s * 2.3);
    fill(255, 0, 0, 70 + alpha * 0.28);
    ellipse(x, y, s * 1.45, s * 1.45);
    fill(255, 0, 0, alpha);
    ellipse(x, y, s, s);
  }
}
