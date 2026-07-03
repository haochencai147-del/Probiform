// Data Sedimentation - split tab
// This file is part of WSAA2_06.pde and is compiled by Processing with the main sketch.

// Machine memory fields.
float[][] blockTrail = new float[COLS][ROWS];
float[][] trace = new float[COLS][ROWS];
int[][] traceBit = new int[COLS][ROWS];
int lastDataTraceParticleFrame = -99999;
int lastConflictParticleFrame = -99999;
float binaryReadOffset = 0;

// ------------------------------------------------------------
// TRACE / FIELD / DRAWING

void addBlockTrailFromActive(float amount) {
  if (accumulationFull) return;

  int[][] cells = active.cells();

  for (int i = 0; i < cells.length; i++) {
    int x = active.column + cells[i][0];
    int y = active.row + cells[i][1];

    if (x >= 0 && x < COLS && y >= 0 && y < ROWS) {
      blockTrail[x][y] = max(blockTrail[x][y], amount);
    }
  }
}

void updateBlockTrail(float dt) {
  float fade = dt * 0.00042;

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      blockTrail[x][y] = max(0, blockTrail[x][y] - fade);
    }
  }
}

void drawBlockTrail() {
  rectMode(CORNER);
  noStroke();

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      if (blockTrail[x][y] <= 0.01) continue;
      if (dataOccupies(x, y)) continue;

      float px = BOARD_X + x * CELL;
      float py = BOARD_Y + y * CELL;
      float t = constrain(blockTrail[x][y], 0, 1);
      float alpha = map(t, 0, 1, 0, 82);

      fill(38, 92, 190, alpha * 0.75);
      rect(px + 3, py + 3, CELL - 6, CELL - 6);
    }
  }
}

void addTraceFromActive(float amount) {
  if (accumulationFull) return;

  int[][] cells = active.cells();

  for (int i = 0; i < cells.length; i++) {
    int x = active.column + cells[i][0];
    int y = active.row + cells[i][1];

    if (x >= 0 && x < COLS && y >= 0 && y < ROWS) {
      trace[x][y] = max(trace[x][y], amount);
      traceBit[x][y] = pmsdBitForCell(active, i, x, y);
    }
  }
}

int pmsdBitForCell(FallingData data, int cellIndex, int gridX, int gridY) {
  int bitIndex = abs(cellIndex + gridX + gridY) % data.binaryText.length();
  return data.binaryText.charAt(bitIndex) == '1' ? 1 : 0;
}

void updateTrace(float dt) {
  float fade = dt * 0.00028;

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      trace[x][y] = max(0, trace[x][y] - fade);
    }
  }
}

void addDataTraceParticlesFromActive(float amount) {
  // Data Samples remain in trace[][] as theoretical machine memory.
  // The visible falling-block particle effect is intentionally disabled.
}

void addConflictFromActive(float amount) {
  if (active == null || accumulationFull) return;
  if (frameCount - lastConflictParticleFrame < 5 && random(1) < 0.74) return;

  int[][] cells = active.cells();
  if (cells.length == 0) return;

  // Conflict Signals: red flashes mark misreads, low confidence and contradictory machine feedback.
  int bursts = constrain(int(map(amount, 0, 1, 1, 5)), 1, 5);
  for (int i = 0; i < bursts; i++) {
    int[] cell = cells[int(random(cells.length))];
    int gx = active.column + cell[0];
    int gy = active.row + cell[1];
    if (gx < 0 || gx >= COLS || gy < 0 || gy >= ROWS) continue;
    addConflictAtCell(gx, gy, amount);
  }

  lastConflictParticleFrame = frameCount;
}

void addConflictAtCell(int gridX, int gridY, float amount) {
  if (gridX < 0 || gridX >= COLS || gridY < 0 || gridY >= ROWS) return;
  if (conflictParticles.size() > 90 && random(1) < 0.65) return;

  int count = constrain(int(map(amount, 0, 1, 1, 4)), 1, 4);
  for (int i = 0; i < count; i++) {
    float px = BOARD_X + (gridX + random(0.18, 0.82)) * CELL;
    float py = BOARD_Y + (gridY + random(0.18, 0.82)) * CELL;
    conflictParticles.add(new ConflictParticle(px, py, amount));
  }
}

void updateDataTraceParticles(float dt) {
  dataTraceParticles.clear();
}

void updateConflictParticles(float dt) {
  for (int i = conflictParticles.size() - 1; i >= 0; i--) {
    ConflictParticle p = conflictParticles.get(i);
    p.update(dt);
    if (p.dead()) conflictParticles.remove(i);
  }
}

void updatePerceptionBoundary(float dt) {
  if (perceptionBoundary != null) perceptionBoundary.update(dt);
}

void drawDataTraceParticles() {
  // Visible Data Sample dots are disabled; boundary logic still reads trace[][].
}

void drawConflictParticles() {
  for (int i = 0; i < conflictParticles.size(); i++) {
    conflictParticles.get(i).draw();
  }
}

void drawPerceptionBoundary() {
  if (perceptionBoundary != null) perceptionBoundary.draw();
}

void trimDataTraceParticles() {
  while (dataTraceParticles.size() > 180) {
    dataTraceParticles.remove(0);
  }
}

void updateLiveBinaryStream() {
  int maxChars = maxLiveBinaryBits();
  if (frameCount - lastBinaryUpdateFrame < 4 && liveBinaryStream.length() >= maxChars) return;

  do {
    liveBinaryStream += generateLiveBitChunk();
  } while (liveBinaryStream.length() < maxChars);

  if (liveBinaryStream.length() > maxChars) {
    liveBinaryStream = liveBinaryStream.substring(liveBinaryStream.length() - maxChars);
  }
  if (frameCount % 48 == 0) {
    lineFieldDirty = true;
  }
  lastBinaryUpdateFrame = frameCount;
}

String generateLiveBitChunk() {
  float confidence = active == null ? input.confidence() : active.confidence;
  float distance = displayDistanceCm();
  float misread = active == null ? input.conflict : active.misread;
  float corruption = recentCorruptionLevel();
  int shapeParity = abs(currentShapeName.hashCode()) % 2;

  String chunk = "";
  chunk += currentBinaryCode;
  chunk += voiceDelta > voiceThreshold ? "1" : "0";
  chunk += confidence > 0.50 ? "1" : "0";
  chunk += machineValidation > 0.50 ? "1" : "0";
  chunk += distance < 18 ? "1" : "0";
  chunk += speaking ? "1" : "0";
  chunk += accumulationFull ? "1" : "0";
  chunk += soundRaw > voiceBaseline ? "1" : "0";
  chunk += soundLevel > 0.35 ? "1" : "0";
  chunk += misread > 0.40 ? "1" : "0";
  chunk += corruption > 0.35 ? "1" : "0";
  chunk += shapeParity == 1 ? "1" : "0";
  return chunk;
}

float recentCorruptionLevel() {
  float strongest = 0;
  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      if (sediment[x][y].occupied) strongest = max(strongest, sediment[x][y].corruption);
    }
  }
  return strongest;
}

int maxLiveBinaryBits() {
  return liveBinaryBitsPerRow() * BINARY_STREAM_ROWS;
}

int liveBinaryBitsPerRow() {
  if (machineFont == null) return max(1, int(BINARY_W / 24));

  pushStyle();
  useMachineFont(BINARY_STREAM_FONT_SIZE);
  float digitStep = max(1, textWidth("0") + BINARY_DIGIT_EXTRA_SPACING);
  popStyle();

  float groupGap = BINARY_GROUP_GAP;
  int bits = 0;
  float usedW = 0;
  float targetW = BINARY_W - 42;

  while (true) {
    float nextW = digitStep;
    if (bits > 0 && bits % 4 == 0) nextW += groupGap;
    if (usedW + nextW > targetW) break;
    usedW += nextW;
    bits++;
  }

  return max(1, bits);
}

boolean binaryGlitchIndex(int index, int[] glitchIndices) {
  for (int i = 0; i < glitchIndices.length; i++) {
    if (index == glitchIndices[i]) return true;
  }
  return false;
}

void drawLiveBinaryStream() {
  pushStyle();
  textAlign(LEFT, TOP);
  if (!useTerminalFont(BINARY_STREAM_FONT_SIZE)) {
    popStyle();
    return;
  }
  noStroke();

  boolean highRisk = (active != null && active.misread > 0.45) || recentCorruptionLevel() > 0.45;
  drawBinaryTerminalPanel(highRisk);
  drawComputationMonitor(highRisk);

  popStyle();
}

void drawBinaryTerminalPanel(boolean highRisk) {
  pushStyle();
  rectMode(CORNER);
  noStroke();

  float terminalX = BINARY_X + 8;
  useTerminalFont(BINARY_STREAM_FONT_SIZE);
  drawTerminalHeader(terminalX, BINARY_Y + 10, highRisk);

  popStyle();
}

void drawComputationMonitor(boolean highRisk) {
  TerminalRow[] rows = computationRows();
  float terminalX = BINARY_X + 8;
  float rowY = BINARY_Y + 30;
  clip(BINARY_X, BINARY_Y + 20, BINARY_W, BINARY_H - 20);
  useTerminalFont(BINARY_STREAM_FONT_SIZE);
  textAlign(LEFT, TOP);

  for (int i = 0; i < rows.length; i++) {
    drawTerminalRow(rows[i], terminalX, rowY, highRisk && i == 2);
    rowY += BINARY_STREAM_ROW_GAP;
  }
  noClip();
}

void drawTerminalHeader(float x, float y, boolean alert) {
  float[] col = terminalColumns();
  int bodyColor = alert ? color(255, 118, 108, 238) : color(188, 236, 242, 238);

  drawTerminalChunk("PID", x + col[0], y, bodyColor, true);
  drawTerminalChunk("USER", x + col[1], y, bodyColor, true);
  drawTerminalChunk("CPU", x + col[2], y, bodyColor, true);
  drawTerminalChunk("MEM", x + col[3], y, bodyColor, true);
  drawTerminalChunk("STATE", x + col[4], y, bodyColor, true);
  drawTerminalChunk("TIME", x + col[5], y, bodyColor, true);
  drawTerminalChunk("realtime computation", x + col[6], y, bodyColor, true);
}

void drawTerminalRow(TerminalRow row, float x, float y, boolean alert) {
  float[] col = terminalColumns();
  int bodyColor = alert ? color(255, 146, 136, 240) : color(202, 246, 250, 232);
  int numberColor = alert ? color(255, 68, 58, 248) : color(255, 42, 46, 242);

  drawTerminalChunk(str(row.pid), x + col[0], y, numberColor, false);
  drawTerminalChunk(row.user, x + col[1], y, bodyColor, false);
  drawTerminalChunk(nf(constrain(row.cpu, 0, 99.9f), 1, 1), x + col[2], y, numberColor, false);
  drawTerminalChunk(nf(constrain(row.mem, 0, 99.9f), 1, 1), x + col[3], y, numberColor, false);
  drawTerminalChunk(row.state, x + col[4], y, bodyColor, false);
  drawTerminalChunk(row.timeText, x + col[5], y, numberColor, false);
  drawTerminalTextWithRedNumbers(row.command, x + col[6], y, false, alert);
}

float[] terminalColumns() {
  float unit = max(10, textWidth("0"));
  return new float[] {
    0,
    unit * 7.5,
    unit * 18.5,
    unit * 26.5,
    unit * 34.5,
    unit * 45.0,
    unit * 57.5
  };
}

void drawTerminalChunk(String value, float x, float y, int c, boolean header) {
  textAlign(LEFT, header ? CENTER : TOP);
  float cursorX = x;

  for (int i = 0; i < value.length(); i++) {
    String ch = str(value.charAt(i));
    fill(c);
    text(ch, cursorX, y);
    text(ch, cursorX + 0.6, y);
    cursorX += textWidth(ch);
  }
}

void drawTerminalTextWithRedNumbers(String value, float x, float y, boolean header, boolean alert) {
  float cursorX = x;
  textAlign(LEFT, header ? CENTER : TOP);

  for (int i = 0; i < value.length(); i++) {
    String ch = str(value.charAt(i));
    if (!header && terminalNumericChar(value.charAt(i))) {
      fill(alert ? color(255, 68, 58, 248) : color(255, 42, 46, 242));
    } else if (alert) {
      fill(255, 146, 136, 240);
    } else {
      fill(202, 246, 250, header ? 238 : 232);
    }

    text(ch, cursorX, y);
    text(ch, cursorX + 0.6, y);
    cursorX += textWidth(ch);
  }
}

boolean terminalNumericChar(char c) {
  return (c >= '0' && c <= '9') || c == '.' || c == '-' || c == ':';
}

class TerminalRow {
  int pid;
  String user;
  float cpu;
  float mem;
  String state;
  String timeText;
  String command;

  TerminalRow(int pid, String user, float cpu, float mem, String state, String timeText, String command) {
    this.pid = pid;
    this.user = user;
    this.cpu = cpu;
    this.mem = mem;
    this.state = state;
    this.timeText = timeText;
    this.command = command;
  }
}

void drawTerminalFunctionKeys(boolean highRisk) {
  float y = BINARY_Y + BINARY_H - 18;
  noStroke();
  fill(145, 198, 205, 235);
  rect(BINARY_X + 3, y, BINARY_W - 6, 15);

  String[] keys = {
    "F1Help", "F2Setup", "F3Search", "F4Trace", "F5Tree",
    "F6SortBy", "F7Nice-", "F8Nice+", "F9Kill", "F10Quit"
  };

  float x = BINARY_X + 8;
  textAlign(LEFT, CENTER);
  for (int i = 0; i < keys.length; i++) {
    if (x > BINARY_X + BINARY_W - 70) break;
    fill(30, 50, 54, 245);
    text(keys[i], x, y + 8);
    x += textWidth(keys[i]) + 14;
    if (highRisk) stroke(110, 36, 38, 210);
    else stroke(72, 116, 122, 190);
    line(x - 7, y + 2, x - 7, y + 13);
    noStroke();
  }
}

TerminalRow[] computationRows() {
  float confidence = active == null ? input.confidence() : active.confidence;
  float misread = active == null ? input.conflict : active.misread;
  float fillRatio = sedimentFillRatio();
  int occupied = sedimentOccupiedCount();
  int cellCount = active == null ? 0 : active.cells().length;
  String shape = active == null ? "NONE" : active.shapeName;
  String grid = active == null ? "--,--" : active.column + "," + active.row;
  String sensorL = leftValid ? nf(smoothUsL, 1, 1) + "cm" : "--";
  String sensorR = rightValid ? nf(smoothUsR, 1, 1) + "cm" : "--";
  String moveState = pendingMoveSteps > 0 ? ultrasonicDirection + ":" + pendingMoveSteps : ultrasonicDirection;

  TerminalRow[] rows = new TerminalRow[3];
  rows[0] = new TerminalRow(
    15163,
    "sensor",
    sensorCpu(),
    sensorMem(),
    motionDetected ? "R" : "S",
    runtimeText(15163),
    "ultrasonic   L=" + sensorL + "   R=" + sensorR + "   move=" + moveState
  );
  rows[1] = new TerminalRow(
    105,
    "block",
    confidence * 44 + misread * 36,
    confidence * 8.8f,
    accumulationFull ? "T" : "S",
    runtimeText(105),
    "shape=" + shape + "   grid=" + grid + "   cells=" + cellCount
  );
  rows[2] = new TerminalRow(
    205,
    "machine",
    machineValidation * 93 + soundLevel * 24,
    fillRatio * 100,
    machineResponding ? "R" : "S",
    runtimeText(205),
    "verify=" + nf(machineValidation, 1, 2) + "   voice=" + nf(voiceDelta, 1, 1) + "   occ=" + occupied
  );
  return rows;
}

String terminalProcessRow(int pid, String user, int pri, int ni, int virt, int res, int shr, String state, float cpu, float mem, String command) {
  return padLeft(str(pid), 5) + " " +
    padRight(user, 8) +
    padLeft(str(pri), 3) + " " +
    padLeft(str(ni), 3) + " " +
    state + " " +
    padLeft(nf(constrain(cpu, 0, 99.9f), 1, 1), 5) + " " +
    padLeft(nf(constrain(mem, 0, 99.9f), 1, 1), 5) + " " +
    padRight(runtimeText(pid), 8) +
    terminalFit(command, 58);
}

float sensorCpu() {
  float leftActivity = leftValid ? map(smoothUsL, ULTRASONIC_MAX_CM, ULTRASONIC_MIN_CM, 0, 1) : 0;
  float rightActivity = rightValid ? map(smoothUsR, ULTRASONIC_MAX_CM, ULTRASONIC_MIN_CM, 0, 1) : 0;
  float cpuValue = max(leftActivity, rightActivity) * 80;
  if (motionDetected) cpuValue += 16;
  return constrain(cpuValue, 0, 99.9f);
}

float sensorMem() {
  float leftActivity = leftValid ? map(smoothUsL, ULTRASONIC_MAX_CM, ULTRASONIC_MIN_CM, 0, 1) : 0;
  float rightActivity = rightValid ? map(smoothUsR, ULTRASONIC_MAX_CM, ULTRASONIC_MIN_CM, 0, 1) : 0;
  return constrain((leftActivity + rightActivity) * 4.8f, 0, 99.9f);
}

String runtimeText(int pid) {
  int total = millis() / 1000 + pid % 73;
  if (total < 0) total = 0;
  int minutes = (total / 60) % 100;
  int seconds = total % 60;
  int hundredths = (frameCount * 3 + pid) % 100;
  return minutes + ":" + nf(seconds, 2) + "." + nf(hundredths, 2);
}

String padLeft(String value, int width) {
  String result = value;
  while (result.length() < width) result = " " + result;
  return result;
}

String padRight(String value, int width) {
  String result = value;
  while (result.length() < width) result += " ";
  return result;
}

String terminalFit(String value, int maxChars) {
  if (value.length() <= maxChars) return value;
  if (maxChars <= 1) return value.substring(0, maxChars);
  return value.substring(0, maxChars - 1) + ">";
}

void drawBinaryColorWash(boolean highRisk) {
  pushStyle();
  rectMode(CORNER);
  noStroke();

  int washCount = highRisk ? 14 : 8;
  washCount += int(activityLevel * 8);

  for (int i = 0; i < washCount; i++) {
    float x = BINARY_X + random(BINARY_W);
    float y = BINARY_Y - 6 + random(BINARY_H - 8);
    float w = random(18, 96);
    float h = random(7, 22);
    float r = random(1);

    if (r < 0.55) {
      fill(210, 0, 0, random(18, highRisk ? 72 : 46));
    } else if (r < 0.78) {
      fill(32, 170, 84, random(12, 38));
    } else {
      fill(18, 18, 18, random(10, 32));
    }

    rect(x, y, w, h);
  }

  popStyle();
}

void drawBinaryFoldScratches(boolean highRisk) {
  pushStyle();
  strokeCap(SQUARE);
  int scratchCount = highRisk ? 16 : 9;
  scratchCount += int(activityLevel * 8);

  for (int i = 0; i < scratchCount; i++) {
    float y = BINARY_Y - 5 + random(BINARY_H - 10);
    float x = BINARY_X + random(BINARY_W);
    float length = random(22, 140);
    float kink = random(-3.5, 3.5);
    strokeWeight(random(0.5, 1.2));
    if (random(1) < 0.72) stroke(210, 0, 0, random(28, 90));
    else stroke(32, 170, 84, random(18, 54));
    line(x, y, min(BINARY_X + BINARY_W, x + length), y + kink);
  }

  popStyle();
}

void drawBinaryStreamRow(
  String rowStream,
  int globalStartIndex,
  float rowX,
  float rowY,
  float digitStep,
  float groupGap,
  boolean highRisk,
  int[] glitchIndices,
  int visibleLength
) {
  float x = rowX;
  float rightEdge = BINARY_X + BINARY_W;

  for (int i = 0; i < rowStream.length(); i++) {
    int globalIndex = globalStartIndex + i;
    int newness = visibleLength - globalIndex;
    if (i > 0 && i % 4 == 0) x += groupGap;
    if (x > rightEdge) break;

    drawBinaryCharWithGlitch(
      rowStream.charAt(i),
      x,
      rowY,
      newness <= 6,
      highRisk,
      binaryGlitchIndex(globalIndex, glitchIndices)
    );
    x += digitStep;
  }
}

void drawBinaryCharWithGlitch(char bit, float x, float y, boolean isNew, boolean highRisk, boolean glitch) {
  char displayBit = bit;
  float drawY = y;
  color bitColor;
  boolean randomFlip = random(1) < (highRisk ? 0.06 : 0.018) + activityLevel * 0.018;

  if (randomFlip) {
    displayBit = bit == '1' ? '0' : '1';
    glitch = true;
  }

  if (glitch && random(1) < 0.18) {
    bitColor = color(225, 190, 56, 220);
  } else if (glitch && (highRisk || random(1) < 0.45)) {
    bitColor = color(235, 58, 42, 235);
  } else if (glitch && random(1) < 0.65) {
    bitColor = color(95, 205, 118, 190);
  } else if (isNew) {
    bitColor = color(190, 255, 205, 235);
  } else {
    bitColor = color(42, 224, 112, 218);
  }

  if (glitch) {
    drawY += random(-1.2, 1.4);
    x += random(-0.8, 0.8);
    if (random(1) < 0.11) displayBit = '_';
  }
  fill(bitColor);
  text(displayBit, x, drawY);
  text(displayBit, x + 0.65, drawY);

  if (glitch && random(1) < 0.24) {
    fill(80, 255, 140, 58);
    text(displayBit, x + random(-2, 2), drawY + random(-2, 2));
  }
}

void drawBodyField() {
  // Intentionally quiet in the minimal interface.
}

float localDensity(int gx, int gy, int radius) {
  float sum = 0;

  for (int dx = -radius; dx <= radius; dx++) {
    for (int dy = -radius; dy <= radius; dy++) {
      int x = gx + dx;
      int y = gy + dy;

      if (x < 0 || x >= COLS || y < 0 || y >= ROWS) continue;
      if (!sediment[x][y].occupied) continue;

      float d = dist(gx, gy, x, y);
      if (d <= radius) {
        sum += map(d, 0, radius, 1.0, 0.05);
      }
    }
  }

  return constrain(sum / 4.8, 0, 1);
}

void drawProbabilityNoise() {
  // Dense probabilistic texture removed for the minimal machine plane.
}

// ------------------------------------------------------------
// MACHINE PERCEPTION BOUNDARY / DATA TRACE REGION

class DataTraceParticle {
  float x;
  float y;
  float vx;
  float vy;
  float life;
  float maxLife;
  float strength;
  float size;

  DataTraceParticle(float x, float y, float strength) {
    this.x = x;
    this.y = y;
    this.strength = constrain(strength, 0.12, 1.0);
    vx = random(-0.018, 0.018);
    vy = random(-0.020, 0.012);
    maxLife = random(1350, 2600);
    life = maxLife;
    size = random(2.0, 4.2);
  }

  void update(float dt) {
    x += vx * dt;
    y += vy * dt;
    life -= dt;
  }

  void draw() {
    float t = constrain(life / maxLife, 0, 1);
    float alpha = map(t, 0, 1, 0, 155) * strength;

    pushStyle();
    rectMode(CENTER);
    noStroke();
    fill(38, 112, 230, alpha * 0.24);
    rect(x, y, size + 4, size + 4);
    fill(58, 138, 255, alpha);
    rect(x, y, size, size);
    popStyle();
  }

  boolean dead() {
    return life <= 0;
  }
}

class ConflictParticle {
  float x;
  float y;
  float vx;
  float vy;
  float life;
  float maxLife;
  float strength;
  int shapeType;
  float angle;

  ConflictParticle(float x, float y, float strength) {
    this.x = x;
    this.y = y;
    this.strength = constrain(strength, 0.18, 1.0);
    vx = random(-0.085, 0.085);
    vy = random(-0.075, 0.055);
    maxLife = random(280, 720);
    life = maxLife;
    shapeType = int(random(3));
    angle = random(TWO_PI);
  }

  void update(float dt) {
    x += vx * dt;
    y += vy * dt;
    vx *= 0.988;
    vy *= 0.988;
    life -= dt;
  }

  void draw() {
    float t = constrain(life / maxLife, 0, 1);
    float flicker = random(1) < 0.20 ? 0.35 : 1.0;
    float alpha = map(t, 0, 1, 0, 230) * strength * flicker;
    float s = map(strength, 0, 1, 3.5, 8.5);

    pushStyle();
    strokeCap(SQUARE);
    stroke(220, 32, 36, alpha);
    fill(220, 32, 36, alpha * 0.78);
    strokeWeight(1);

    if (shapeType == 0) {
      line(x - s * 0.5, y, x + s * 0.5, y + random(-1.5, 1.5));
    } else if (shapeType == 1) {
      noStroke();
      triangle(
        x + cos(angle) * s * 0.55, y + sin(angle) * s * 0.55,
        x + cos(angle + TWO_PI / 3.0) * s * 0.55, y + sin(angle + TWO_PI / 3.0) * s * 0.55,
        x + cos(angle + TWO_PI * 2.0 / 3.0) * s * 0.55, y + sin(angle + TWO_PI * 2.0 / 3.0) * s * 0.55
      );
    } else {
      noStroke();
      rectMode(CENTER);
      rect(x, y, s * 0.6, s * 0.6);
    }

    popStyle();
  }

  boolean dead() {
    return life <= 0;
  }
}

class PerceptionBoundary {
  float[][] targetOcc = new float[COLS][ROWS];
  float[][] displayOcc = new float[COLS][ROWS];
  float[][] sourceOcc = new float[COLS][ROWS];
  float alpha = 0;
  float conflictMemory = 0;
  int trustedCellCount = 0;
  int lastRebuildFrame = -99999;

  void reset() {
    for (int x = 0; x < COLS; x++) {
      for (int y = 0; y < ROWS; y++) {
        targetOcc[x][y] = 0;
        displayOcc[x][y] = 0;
        sourceOcc[x][y] = 0;
      }
    }

    alpha = 0;
    conflictMemory = 0;
    trustedCellCount = 0;
    lastRebuildFrame = -99999;
  }

  void update(float dt) {
    conflictMemory = max(0, conflictMemory - dt * 0.00070);

    float liveConflict = 0;
    if (active != null) liveConflict = max(liveConflict, active.misread);
    liveConflict = max(liveConflict, recentCorruptionLevel());
    if (machineResponding && (active == null || !active.humanConfirmed)) {
      liveConflict = max(liveConflict, machineNoiseLevel * 0.70);
    }
    conflictMemory = max(conflictMemory, liveConflict);

    int rebuildInterval = hasActiveBoundaryCells() ? 8 : 12;
    if (frameCount - lastRebuildFrame >= rebuildInterval) {
      rebuild();
      lastRebuildFrame = frameCount;
    }

    for (int x = 0; x < COLS; x++) {
      for (int y = 0; y < ROWS; y++) {
        displayOcc[x][y] = lerp(displayOcc[x][y], targetOcc[x][y], targetOcc[x][y] > displayOcc[x][y] ? 0.055 : 0.038);
        if (displayOcc[x][y] < 0.01 && targetOcc[x][y] == 0) displayOcc[x][y] = 0;
      }
    }

    float targetAlpha = boundaryArmed() && trustedCellCount > 0 ? map(constrain(trustedCellCount, 1, 72), 1, 72, 76, 118) : 0;
    alpha = lerp(alpha, targetAlpha, targetAlpha == 0 ? 0.045 : 0.070);
  }

  void rebuild() {
    trustedCellCount = 0;

    for (int x = 0; x < COLS; x++) {
      for (int y = 0; y < ROWS; y++) {
        targetOcc[x][y] = 0;
        sourceOcc[x][y] = 0;
      }
    }

    if (!boundaryArmed()) return;

    // Current Confidence Region: trusted sediment plus recent Data Samples.
    // Machine continuously updates its understanding of human presence rather than detecting a complete body.
    for (int x = 0; x < COLS; x++) {
      for (int y = 0; y < ROWS; y++) {
        float evidence = trustedSedimentEvidence(x, y);
        if (evidence > 0) {
          sourceOcc[x][y] = max(sourceOcc[x][y], map(evidence, 0.10, 1.0, 0.70, 1.0));
        } else if (trustedTraceCell(x, y)) {
          sourceOcc[x][y] = max(sourceOcc[x][y], map(trace[x][y], 0.34, 1.0, 0.44, 0.74));
        }
      }
    }

    addActiveBoundarySource();

    for (int i = 0; i < dataTraceParticles.size(); i++) {
      DataTraceParticle p = dataTraceParticles.get(i);
      if (p.life / p.maxLife < 0.28) continue;
      int gx = int((p.x - BOARD_X) / CELL);
      int gy = int((p.y - BOARD_Y) / CELL);
      if (gx >= 0 && gx < COLS && gy >= 0 && gy < ROWS && !activeOccupies(gx, gy) && hasTrustedNeighbour(gx, gy, 3)) {
        sourceOcc[gx][gy] = max(sourceOcc[gx][gy], 0.38);
      }
    }

    buildProbabilisticBodyTarget();
  }

  boolean boundaryArmed() {
    return nextSedimentPieceId >= 2 || hasActiveBoundaryCells();
  }

  boolean hasActiveBoundaryCells() {
    if (accumulationFull || active == null) return false;
    int[][] cells = active.cells();

    for (int i = 0; i < cells.length; i++) {
      int x = active.column + cells[i][0];
      int y = active.row + cells[i][1];
      if (x >= 0 && x < COLS && y >= 0 && y < ROWS) return true;
    }

    return false;
  }

  void addActiveBoundarySource() {
    if (!hasActiveBoundaryCells()) return;

    int[][] cells = active.cells();
    float confidenceEvidence = active == null ? 0.42 : map(constrain(active.confidence, 0, 1), 0, 1, 0.34, 0.58);

    for (int i = 0; i < cells.length; i++) {
      int x = active.column + cells[i][0];
      int y = active.row + cells[i][1];
      if (x < 0 || x >= COLS || y < 0 || y >= ROWS) continue;

      sourceOcc[x][y] = max(sourceOcc[x][y], confidenceEvidence);

      // Machine Perception Boundary: while falling, the machine sketches a provisional body region.
      if (motionDetected || pendingMoveSteps > 0) {
        int dx = pendingMoveDirection;
        if (dx == 0 && ultrasonicDirection.equals("LEFT")) dx = -1;
        if (dx == 0 && ultrasonicDirection.equals("RIGHT")) dx = 1;
        if (dx != 0) {
          int nx = x + dx;
          if (nx >= 0 && nx < COLS) sourceOcc[nx][y] = max(sourceOcc[nx][y], confidenceEvidence * 0.34);
        }
      }
    }
  }

  void buildProbabilisticBodyTarget() {
    for (int x = 0; x < COLS; x++) {
      for (int y = 0; y < ROWS; y++) {
        if (sourceOcc[x][y] > 0) trustedCellCount++;
        targetOcc[x][y] = sourceOcc[x][y];
      }
    }

    if (trustedCellCount == 0) return;

    boolean hasSediment = hasSedimentBoundarySource();
    boolean activeOnly = hasActiveBoundaryCells() && !hasSediment;
    int expansionPasses = activeOnly ? 2 : trustedCellCount < 5 ? 4 : 5;
    if (hasActiveBoundaryCells() && hasSediment) expansionPasses = max(expansionPasses, 4);
    if (conflictMemory > 0.45 && hasSediment) expansionPasses = min(5, expansionPasses + 1);
    for (int pass = 0; pass < expansionPasses; pass++) {
      float[][] expanded = new float[COLS][ROWS];

      for (int x = 0; x < COLS; x++) {
        for (int y = 0; y < ROWS; y++) {
          expanded[x][y] = targetOcc[x][y];
        }
      }

      for (int x = 0; x < COLS; x++) {
        for (int y = 0; y < ROWS; y++) {
          if (targetOcc[x][y] <= 0.08) continue;

          spreadTo(expanded, x - 1, y, targetOcc[x][y], pass);
          spreadTo(expanded, x + 1, y, targetOcc[x][y], pass);
          spreadTo(expanded, x, y - 1, targetOcc[x][y], pass);
          spreadTo(expanded, x, y + 1, targetOcc[x][y], pass);

          if (!activeOnly && pass == 0 && stableChance(x, y, pass, 0.28)) {
            int dx = stableDirection(x, y, pass);
            int dy = stableDirection(y, x, pass + 3);
            spreadTo(expanded, x + dx, y + dy, targetOcc[x][y] * 0.74, pass + 1);
          }
        }
      }

      targetOcc = expanded;
    }

    addMisreadBulge();
    addPerceptualScan();
  }

  void spreadTo(float[][] expanded, int x, int y, float value, int pass) {
    if (x < 0 || x >= COLS || y < 0 || y >= ROWS) return;
    if (activeOccupies(x, y) && sourceOcc[x][y] == 0) return;

    float falloff = pass == 0 ? 0.72 : pass == 1 ? 0.54 : 0.40;
    float irregular = stableCellNoise(x, y, pass, 0.82, 1.02);
    float nextValue = value * falloff * irregular;

    if (nextValue > 0.075) expanded[x][y] = max(expanded[x][y], nextValue);
  }

  boolean hasSedimentBoundarySource() {
    for (int x = 0; x < COLS; x++) {
      for (int y = 0; y < ROWS; y++) {
        if (trustedSedimentEvidence(x, y) > 0) return true;
      }
    }

    return false;
  }

  float trustedSedimentEvidence(int x, int y) {
    if (!sediment[x][y].occupied) return 0;
    if (sediment[x][y].corruption > 0.78) return 0;
    float trust = sediment[x][y].confidence * 0.58 + sediment[x][y].solidity * 0.42;
    trust *= map(constrain(sediment[x][y].corruption, 0, 0.78), 0, 0.78, 1.0, 0.20);
    if (trust <= 0.10) return 0;
    return constrain(trust, 0.12, 1.0);
  }

  boolean trustedTraceCell(int x, int y) {
    if (trace[x][y] <= 0.34) return false;
    if (activeOccupies(x, y)) return false;
    return hasTrustedNeighbour(x, y, 3);
  }

  boolean hasTrustedNeighbour(int gx, int gy, int radius) {
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        int x = gx + dx;
        int y = gy + dy;
        if (x < 0 || x >= COLS || y < 0 || y >= ROWS) continue;
        if (abs(dx) + abs(dy) > radius) continue;
        if (trustedSedimentEvidence(x, y) > 0) return true;
      }
    }

    return false;
  }

  void addMisreadBulge() {
    float conflict = constrain(conflictMemory, 0, 1);
    if (conflict < 0.28) return;

    int bulgeCount = int(map(conflict, 0.28, 1.0, 1, 3));
    for (int i = 0; i < bulgeCount; i++) {
      int sx = (frameCount / 24 + i * 11) % COLS;
      int sy = (frameCount / 31 + i * 7) % ROWS;
      if (targetOcc[sx][sy] <= 0.20) continue;

      int dx = stableDirection(sx, sy, i);
      int dy = stableDirection(sy, sx, i + 5);
      int steps = 1 + abs((sx * 3 + sy * 5 + i) % 3);

      for (int s = 1; s <= steps; s++) {
        int x = sx + dx * s;
        int y = sy + dy * (((sx + sy + i) % 2 == 0) ? s : 0);
        if (x < 0 || x >= COLS || y < 0 || y >= ROWS) break;
        if (activeOccupies(x, y) && sourceOcc[x][y] == 0) continue;
        targetOcc[x][y] = max(targetOcc[x][y], targetOcc[sx][sy] * map(s, 1, steps, 0.42, 0.18));
      }
    }
  }

  void addPerceptualScan() {
    if (!hasSedimentBoundarySource()) return;

    // Probabilistic Body: settled evidence keeps being re-read by the machine.
    float sensorActivity = constrain(
      soundLevel * 0.22 +
      machineValidation * 0.25 +
      machineNoiseLevel * 0.18 +
      recentCorruptionLevel() * 0.22 +
      (motionDetected ? 0.13 : 0),
      0,
      1
    );

    int phase = frameCount / 36;
    float growChance = map(sensorActivity, 0, 1, 0.05, 0.22);
    float retractChance = map(sensorActivity, 0, 1, 0.03, 0.13);

    float[][] adjusted = new float[COLS][ROWS];
    for (int x = 0; x < COLS; x++) {
      for (int y = 0; y < ROWS; y++) {
        adjusted[x][y] = targetOcc[x][y];
      }
    }

    for (int x = 0; x < COLS; x++) {
      for (int y = 0; y < ROWS; y++) {
        if (targetOcc[x][y] <= 0.12) continue;

        boolean boundaryCell =
          !targetVisible(x - 1, y) ||
          !targetVisible(x + 1, y) ||
          !targetVisible(x, y - 1) ||
          !targetVisible(x, y + 1);

        if (!boundaryCell) continue;

        if (stableChance(x + phase, y, phase, growChance)) {
          int dx = stableDirection(x, y, phase);
          int dy = stableDirection(y, x, phase + 2);
          spreadScan(adjusted, x + dx, y, targetOcc[x][y] * 0.42);
          if (stableChance(x, y + phase, phase + 4, 0.38)) {
            spreadScan(adjusted, x, y + dy, targetOcc[x][y] * 0.36);
          }
        }

        if (sourceOcc[x][y] == 0 && stableChance(x, y + phase, phase + 8, retractChance)) {
          adjusted[x][y] *= map(sensorActivity, 0, 1, 0.92, 0.72);
        }
      }
    }

    targetOcc = adjusted;
  }

  void spreadScan(float[][] adjusted, int x, int y, float value) {
    if (x < 0 || x >= COLS || y < 0 || y >= ROWS) return;
    if (sourceOcc[x][y] > 0) return;
    if (activeOccupies(x, y) && sourceOcc[x][y] == 0) return;
    adjusted[x][y] = max(adjusted[x][y], value);
  }

  boolean targetVisible(int x, int y) {
    if (x < 0 || x >= COLS || y < 0 || y >= ROWS) return false;
    return targetOcc[x][y] > 0.16;
  }

  float stableCellNoise(int x, int y, int salt, float low, float high) {
    float n = noise(x * 0.37 + salt * 5.1, y * 0.41 + salt * 2.7);
    return map(n, 0, 1, low, high);
  }

  boolean stableChance(int x, int y, int salt, float chance) {
    float n = noise(x * 0.61 + salt * 3.3, y * 0.53 + salt * 4.7);
    return n < chance;
  }

  int stableDirection(int x, int y, int salt) {
    return ((x * 17 + y * 31 + salt * 13) % 2 == 0) ? -1 : 1;
  }

  void draw() {
    if (alpha < 1) return;

    // Machine Perception Boundary: pixelated outline of the Probabilistic Body.
    pushStyle();
    strokeCap(SQUARE);
    strokeJoin(MITER);

    float jitter = 0;
    float breakChance = 0;

    noFill();
    stroke(125, 255, 170, alpha * 0.24);
    strokeWeight(3.5);
    drawMaskEdges(jitter, breakChance * 0.38);

    stroke(42, 118, 72, alpha * 0.70);
    strokeWeight(2.0);
    drawMaskEdges(jitter * 0.44, breakChance * 0.68);

    stroke(125, 255, 170, alpha);
    strokeWeight(1.55);
    drawMaskEdges(jitter, breakChance);

    popStyle();
  }

  void drawMaskEdges(float jitter, float breakChance) {
    for (int x = 0; x < COLS; x++) {
      for (int y = 0; y < ROWS; y++) {
        if (!visibleBoundaryCell(x, y)) continue;
        drawEdgeIfOpen(x, y, -1, 0, jitter, breakChance);
        drawEdgeIfOpen(x, y, 1, 0, jitter, breakChance);
        drawEdgeIfOpen(x, y, 0, -1, jitter, breakChance);
        drawEdgeIfOpen(x, y, 0, 1, jitter, breakChance);
      }
    }
  }

  void drawRegionFill() {
    // Internal green occupancy squares are hidden; only the outer perception boundary is visible.
  }

  void drawEdgeIfOpen(int x, int y, int dx, int dy, float jitter, float breakChance) {
    int nx = x + dx;
    int ny = y + dy;
    if (nx >= 0 && nx < COLS && ny >= 0 && ny < ROWS && visibleBoundaryCell(nx, ny)) return;
    if (random(1) < breakChance) return;

    float left = BOARD_X + x * CELL;
    float right = left + CELL;
    float top = BOARD_Y + y * CELL;
    float bottom = top + CELL;
    float ox = 0;
    float oy = 0;

    if (dx == -1) line(left + ox, top + oy, left + ox, bottom + oy);
    else if (dx == 1) line(right + ox, top + oy, right + ox, bottom + oy);
    else if (dy == -1) line(left + ox, top + oy, right + ox, top + oy);
    else if (dy == 1) line(left + ox, bottom + oy, right + ox, bottom + oy);
  }

  boolean visibleBoundaryCell(int x, int y) {
    if (x < 0 || x >= COLS || y < 0 || y >= ROWS) return false;
    return displayOcc[x][y] > 0.16;
  }

  boolean visibleRegionCell(int x, int y) {
    if (x < 0 || x >= COLS || y < 0 || y >= ROWS) return false;
    return displayOcc[x][y] > 0.12;
  }
}

// Custom typed memory and boundary state lives after its classes for Processing's preprocessor.
ArrayList<DataTraceParticle> dataTraceParticles = new ArrayList<DataTraceParticle>();
ArrayList<ConflictParticle> conflictParticles = new ArrayList<ConflictParticle>();
PerceptionBoundary perceptionBoundary;
