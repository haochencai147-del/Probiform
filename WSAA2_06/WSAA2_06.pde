// Data Sedimentation – Constructing a Probabilistic Body
// Ultrasonic = position data
// KY-038 = human voice confirmation / solidity data
// MAX9814 = machine feedback / verification / corruption + synthesized sound

import processing.serial.*;
import processing.sound.*;
import oscP5.*;
import netP5.*;
import java.util.ArrayList;
import java.util.HashMap;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;

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
  surface.setResizable(true);
  computeWin95Layout();
  loadPageBackground();
  loadMainWindowShape();
  loadGroupLogoShape();
  loadGeneratedWindowImage();

  loadMachineFont();
  loadHumanFont();
  initOscBridge();
  initMachineSound();

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      sediment[x][y] = new DataCell();
      blockTrail[x][y] = 0;
      trace[x][y] = 0;
      traceBit[x][y] = 0;
    }
  }

  perceptionBoundary = new PerceptionBoundary();
  lastClearParticipantTime = millis();
  unattendedTimeoutMs = int(random(UNATTENDED_TIMEOUT_MIN_MS, UNATTENDED_TIMEOUT_MAX_MS + 1));
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
  if (humanFont != null) textFont(humanFont, size * FONT_SCALE);
}

boolean useMachineFont(float size) {
  if (machineFont == null) return false;
  textFont(machineFont, size * FONT_SCALE);
  return true;
}

boolean useTerminalFont(float size) {
  return useMachineFont(size);
}

float ui(float value) {
  return value * UI_SCALE;
}

void drawHeavyText(String value, float x, float y) {
  text(value, x, y);
  text(value, x + ui(0.75), y);
}

void windowResized() {
  computeWin95Layout();
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
  updateParticipationMode();
  applyUltrasonicToActiveBlock();

  updateTrace(dt);
  updateConflictParticles(dt);
  updateBlockTrail(dt);
  updateSediment(dt);
  applySedimentGravity();
  updateFallingData(now);
  updateMachineSound(dt);
  addBlockTrailFromActive(0.58);
  addTraceFromActive(0.52);
  updatePerceptionBoundary(dt);
  updateLiveBinaryStream();
  updateMachineIndicator();
  updateAutoQrArchive();

  drawPageBackground();
  drawUI();
  drawWin95Frame();

  clip(BOARD_DISPLAY_X, BOARD_Y, BOARD_DISPLAY_W, BOARD_H);
  pushMatrix();
  translate(BOARD_DISPLAY_X, 0);
  scale(BOARD_RENDER_SCALE_X, 1);
  translate(-BOARD_X, 0);
  drawLiquefiedBoardField();
  drawInferredFakeBlocks();
  drawConflictParticles();
  drawPerceptionBoundary();

  drawSediment();
  drawFallingData();
  drawActiveOuterOutline();
  drawLRInputIndicators();
  drawUnattendedModeNotice();

  sendOscToMax();
  noClip();
  popMatrix();

  drawLiveBinaryStream();
  drawWin95Scrollbars();
  drawMachineIndicator();
  drawProjectTitleOverlay();
  drawQrArchiveOverlay();
}


// Additional sketch tabs:
// Sensors.pde          serial input, KY-038, MAX9814, ultrasonic control
// InterfaceView.pde    Win95-style interface and HUD
// GameInputData.pde    input state, PMSD interpretation, falling data
// MemoryBoundary.pde   trace memory, conflict signals, Machine Perception Boundary
// SedimentSystem.pde   sediment storage, verification, decay, gravity
// BlockDrawing.pde     sediment/active block drawing and inferred paths
// QrArchive.pde        QR archive generation and display
