// Data Sedimentation – Constructing a Probabilistic Body
// Ultrasonic = position data
// KY-038 = human voice confirmation / solidity data
// MAX9814 = machine feedback / verification / corruption + synthesized sound

import processing.serial.*;
import processing.sound.*;
import java.util.ArrayList;

class Osc {
  float angle;
  float speed;

  Osc(float angle, float speed) {
    this.angle = angle;
    this.speed = speed;
  }

  float next() {
    angle += speed;
    return sin(angle);
  }
}

class Split {
  Osc osc;
  float val;
  int index;

  Split(int index, float speed) {
    this.index = index;
    val = random(0.2, 0.8);
    osc = new Osc(random(TWO_PI), speed);
  }
}

int generation(int index) {
  return floor(log(index + 1) / log(2));
}


// Core board constants stay in the main tab so every system can read them.
final int COLS = 28;
final int ROWS = 20;
final int MAX_CELL = 36;
int CELL = MAX_CELL;

final int GAME_DURATION_MS = 180000;
int gameStartTime = 0;
float systemAge01 = 0;
int lastFrameTime;


void settings() {
  fullScreen();
  smooth(4);
}

void setup() {
  frameRate(60);
  computeWin95Layout();
  loadPageBackground();
  loadMainWindowShape();
  loadGroupLogoShape();
  loadGeneratedWindowImage();

  loadMachineFont();
  loadHumanFont();

  signalBeep = new SinOsc(this);
  signalClick = new WhiteNoise(this);
  signalEnv = new Env(this);

  signalBeep.play();
  signalClick.play();
  signalBeep.amp(0);
  signalClick.amp(0);

  splits = new Split[round(pow(2, LINE_DEPTH)) - 1];

  for (int i = 0; i < splits.length; i++) {
    int gen = generation(i);
    float speed = map(gen, 0, LINE_DEPTH, 0.001, 0.03);
    if (i % 2 == 0) speed *= -1;
    splits[i] = new Split(i, speed);
  }

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      sediment[x][y] = new DataCell();
      blockTrail[x][y] = 0;
      trace[x][y] = 0;
      traceBit[x][y] = 0;
    }
  }

  perceptionBoundary = new PerceptionBoundary();
  spawnData();
  lastFrameTime = millis();
  lastDropTime = millis();
  initArduinoSerial();
  gameStartTime = millis();
}

boolean fontInstalled(String fontName) {
  String[] available = PFont.list();
  for (int i = 0; i < available.length; i++) {
    if (available[i].equals(fontName)) return true;
  }
  return false;
}

void loadHumanFont() {
  humanFont = machineFont;
  terminalFont = machineFont;
}

void loadMachineFont() {
  java.io.File dataFont = new java.io.File(dataPath("INTR-PIXEL-intr_soft.otf"));
  if (dataFont.exists()) {
    machineFont = createFont("INTR-PIXEL-intr_soft.otf", 18, true);
    return;
  }

  String installedIntrFont = "INTR-PIXEL-intr_soft_7.1_6.5_15.0_11.3_6.0_5.0_subtract_center";
  if (fontInstalled(installedIntrFont)) {
    machineFont = createFont(installedIntrFont, 18, true);
    return;
  }

  if (fontInstalled("INTR-PIXEL-intr_soft")) {
    machineFont = createFont("INTR-PIXEL-intr_soft", 18, true);
    return;
  }

  if (fontInstalled("FF Path")) {
    machineFont = createFont("FF Path", 18, true);
    return;
  }

  if (fontInstalled("FF Path Regular")) {
    machineFont = createFont("FF Path Regular", 18, true);
    return;
  }
  if (fontInstalled("FFPath-Regular")) {
    machineFont = createFont("FFPath-Regular", 18, true);
    return;
  }
  if (fontInstalled("FFPath")) {
    machineFont = createFont("FFPath", 18, true);
    return;
  }

  dataFont = new java.io.File(dataPath("FFPath.ttf"));
  if (dataFont.exists()) {
    machineFont = createFont("FFPath.ttf", 18, true);
    return;
  }

  dataFont = new java.io.File(dataPath("FFPath-Regular.ttf"));
  if (dataFont.exists()) {
    machineFont = createFont("FFPath-Regular.ttf", 18, true);
    return;
  }

  println("INTR Pixel font not found.");
}

void useHumanFont(float size) {
  if (humanFont != null) textFont(humanFont, size);
}

boolean useMachineFont(float size) {
  if (machineFont == null) return false;
  textFont(machineFont, size);
  return true;
}

boolean useTerminalFont(float size) {
  return useMachineFont(size);
}

void drawHeavyText(String value, float x, float y) {
  text(value, x, y);
  text(value, x + 0.75, y);
}

void draw() {
  int now = millis();
  float dt = min(50, now - lastFrameTime);
  lastFrameTime = now;

  input.update(dt);
  if (keyboardTestMode) {
    updateKeyboardTestInput(dt);
  } else {
    readSerialData();
  }
  systemAge01 = constrain((millis() - gameStartTime) / float(GAME_DURATION_MS), 0, 1);

  updateMachineFeedback();
  updateVoiceState();
  updateUltrasonicControl();
  updatePMSDObservationWindow();
  applyUltrasonicToActiveBlock();
  updateMachineSelfRotation();

  updateTrace(dt);
  updateDataTraceParticles(dt);
  updateConflictParticles(dt);
  updateBlockTrail(dt);
  updateSediment(dt);
  applySedimentGravity();
  updateFallingData(now);
  addBlockTrailFromActive(0.58);
  addTraceFromActive(0.52);
  updatePerceptionBoundary(dt);
  updateLineField();
  updateLiveBinaryStream();
  updateMachineIndicator();

  drawPageBackground();
  updateLifeDots(dt);
  drawLifeDots();
  drawUI();
  drawWin95Frame();

  clip(BOARD_X, BOARD_Y, BOARD_W, BOARD_H);
  drawBoardGrid();
  drawBlockTrail();
  drawInferredFakeBlocks();
  drawDataTraceParticles();
  drawConflictParticles();
  drawPerceptionBoundary();

  drawSediment();
  drawFallingData();
  drawActiveOuterOutline();

  drawCRTOverlay();
  noClip();

  drawLiveBinaryStream();
  drawWin95Scrollbars();
  drawMachineIndicator();
  drawRightLowerDrawnRegion();
  drawProjectTitleOverlay();
}


// Additional sketch tabs:
// Sensors.pde          serial input, KY-038, MAX9814, ultrasonic control
// InterfaceView.pde    Win95-style interface and HUD
// GameInputData.pde    input state, PMSD interpretation, falling data
// MemoryBoundary.pde   trace memory, conflict signals, Machine Perception Boundary
// SedimentSystem.pde   sediment storage, verification, decay, gravity
// BlockDrawing.pde     sediment/active block drawing and inferred paths
// LineFieldUtility.pde background line field helpers
