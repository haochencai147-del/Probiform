// Data Sedimentation - split tab
// This file is part of WSAA2_06.pde and is compiled by Processing with the main sketch.

// Game timing and PMSD state.
int lastDropTime;
int dropInterval = 500;
boolean accumulationFull = false;

int currentPMSD = 0;
String currentBinaryCode = "0000";
String currentMachineInterpretation = "";
String currentShapeName = "";

final int PMSD_RECENT_MS = 1200;
int lastPresenceTime = -99999;
int lastSoundTime = -99999;
int lastDistanceTime = -99999;

// ------------------------------------------------------------
// INPUT STATE

class InputState {
  float horizontal = 0.5;
  float spatialConfidence = 0.45;
  float conflict = 0;
  boolean softDrop = false;

  void update(float dt) {
    conflict = max(0, conflict - dt * 0.0011);
    spatialConfidence = max(0.25, spatialConfidence - dt * 0.000025);
  }

  float confidence() {
    float agreement = 1.0 - conflict;
    return constrain(spatialConfidence * agreement, 0.05, 1.0);
  }
}

void keyPressed() {
  if (key == 't' || key == 'T') {
    keyboardTestMode = !keyboardTestMode;
    if (keyboardTestMode) {
      stopMachineAudio();
    }
    println("Keyboard test mode: " + (keyboardTestMode ? "ON" : "OFF"));
    return;
  }

  if (keyboardTestMode) {
    handleKeyboardTestKeyPressed();
  }

  if (key == 'a' || key == 'A' || keyCode == LEFT) moveActive(-1);
  if (key == 'd' || key == 'D' || keyCode == RIGHT) moveActive(1);
  if (key == 'w' || key == 'W' || keyCode == UP) rotateActive();
  if (key == 's' || key == 'S' || keyCode == DOWN) input.softDrop = true;
  if (key == 'v' || key == 'V') resetVoiceCalibration();

  if (key == 'q' || key == 'Q') {
    if (keyboardTestMode) {
      testVoiceRaw = max(0, testVoiceRaw - 3);
    } else {
      kyLeftRaw = max(0, kyLeftRaw - 3);
      kyRightRaw = max(0, kyRightRaw - 3);
      soundRaw = max(kyLeftRaw, kyRightRaw);
    }
  }

  if (key == 'e' || key == 'E') {
    if (keyboardTestMode) {
      testVoiceRaw = min(50, testVoiceRaw + 3);
    } else {
      kyLeftRaw = min(50, kyLeftRaw + 3);
      kyRightRaw = min(50, kyRightRaw + 3);
      soundRaw = max(kyLeftRaw, kyRightRaw);
    }
  }

  if (key == 'z' || key == 'Z') {
    if (keyboardTestMode) testMachineRaw = max(0, testMachineRaw - 30);
    else machineRaw = max(0, machineRaw - 30);
  }

  if (key == 'x' || key == 'X') {
    if (keyboardTestMode) testMachineRaw = min(1000, testMachineRaw + 30);
    else machineRaw = min(1000, machineRaw + 30);
  }

  if (key == 'm' || key == 'M') {
    machineAudioEnabled = !machineAudioEnabled;
    if (!machineAudioEnabled) stopMachineAudio();
  }

  if (key == ' ') {
    input.conflict = 1;
    active.misread = 1;
    addTraceFromActive(0.85);
    addConflictFromActive(0.90);
    lineFieldDirty = true;
  }

  if (key == 'c' || key == 'C') clearSediment();
}

void handleKeyboardTestKeyPressed() {
  if (key == 'p' || key == 'P') {
    testPresence = !testPresence;
    if (!testPresence) testDistance = false;
  }

  if (key == 'o' || key == 'O') {
    testDistance = !testDistance;
    if (testDistance) testPresence = true;
  }

  if (key == '[') testUltrasonicCm = constrain(testUltrasonicCm - 2, ULTRASONIC_MIN_CM, ULTRASONIC_MAX_CM);
  if (key == ']') testUltrasonicCm = constrain(testUltrasonicCm + 2, ULTRASONIC_MIN_CM, ULTRASONIC_MAX_CM);

  if (key >= '0' && key <= '8') {
    int rawCode = key == '0' ? 0 : 7 + (key - '0');
    applyKeyboardTestPMSD(rawCode);
  }
}

void applyKeyboardTestPMSD(int rawCode) {
  testPresence = rawCode > 0;
  testDistance = (rawCode & 1) == 1;

  if ((rawCode & 2) == 2) {
    testVoiceRaw = max(testVoiceRaw, voiceBaselineReady ? voiceBaseline + 18 : 28);
  } else {
    testVoiceRaw = 0;
  }

  if ((rawCode & 4) == 4) {
    motionDetected = true;
    lastMotionTime = millis();
  } else {
    motionDetected = false;
    lastMotionTime = -99999;
  }

  if (active == null || active.cells().length == 0) {
    spawnData();
  }
}

void resetVoiceCalibration() {
  voiceBaseline = max(kyLeftRaw, kyRightRaw);
  voiceDelta = 0;
  voiceBaselineReady = voiceBaseline > 0;
  voiceCalibrationStartTime = millis();
  speaking = false;
  externalVoiceCandidate = false;
  speakingFrameCount = 0;
  silenceFrameCount = 0;
  voiceCandidateStartTime = -99999;
  sustainedVoiceCandidateStartTime = -99999;
  lastVoiceSignalTime = -99999;
  voicePeakHold = 0;
  voiceHold = 0;
  voiceConfirm = 0;
  soundLevel = 0;
  voiceEnergy = 0;
  voiceEnvelope = 0;
  directMappedSolidity = 0.12;
  blockSolidity = 0.12;
}

void keyReleased() {
  if (key == 's' || key == 'S' || keyCode == DOWN) {
    input.softDrop = false;
  }
}

// ------------------------------------------------------------
// FALLING DATA / PMSD

void updatePMSDObservationWindow() {
  int now = millis();

  if (shapePresenceNow()) lastPresenceTime = now;
  if (shapeDistanceNow()) lastDistanceTime = now;
  if (shapeSoundNow()) lastSoundTime = now;
  shapeMotionNow();
}

int computePMSDCode() {
  int P = arduinoActive ? 1 : 0;
  int M = motionDetected ? 1 : 0;
  int S = speaking ? 1 : 0;
  int D = shapeDistanceNow() ? 1 : 0;
  if (P == 0) return 0;
  return P * 8 + M * 4 + S * 2 + D;
}

int recentBit(int lastSeenTime, int now) {
  return now - lastSeenTime <= PMSD_RECENT_MS ? 1 : 0;
}

boolean shapePresenceNow() {
  return arduinoActive;
}

boolean shapeSoundNow() {
  return speaking;
}

boolean shapeDistanceNow() {
  return inShapeDistanceRange(usL) || inShapeDistanceRange(usR);
}

boolean shapeMotionNow() {
  boolean sensorMovementNow = false;

  if (ultrasonicDirection.equals("LEFT") || ultrasonicDirection.equals("RIGHT") || pendingMoveSteps > 0) {
    sensorMovementNow = true;
  }

  if (leftValid && previousMotionUsL >= 0 && abs(smoothUsL - previousMotionUsL) > MOTION_DISTANCE_DELTA_CM) {
    sensorMovementNow = true;
  }

  if (rightValid && previousMotionUsR >= 0 && abs(smoothUsR - previousMotionUsR) > MOTION_DISTANCE_DELTA_CM) {
    sensorMovementNow = true;
  }

  if (leftValid) previousMotionUsL = smoothUsL;
  if (rightValid) previousMotionUsR = smoothUsR;

  if (sensorMovementNow) {
    motionDetected = true;
    lastMotionTime = millis();
  }

  if (millis() - lastMotionTime > MOTION_HOLD_MS) {
    motionDetected = false;
  }

  return motionDetected;
}

boolean inShapeDistanceRange(float distanceCm) {
  return distanceCm >= ULTRASONIC_MIN_CM && distanceCm <= ULTRASONIC_MAX_CM;
}

String binary4(int value) {
  return binary(value, 4);
}

String interpretationFromPMSD(int code) {
  switch (code) {
  case 0: return "No presence / no data";
  case 8: return "Presence detected";
  case 9: return "Presence + Distance";
  case 10: return "Presence + Sound";
  case 11: return "Presence + Sound + Distance";
  case 12: return "Presence + Motion";
  case 13: return "Presence + Motion + Distance";
  case 14: return "Presence + Motion + Sound";
  case 15: return "Strong multi-signal presence";
  default: return "Unconfirmed signal without presence";
  }
}

String shapeNameFromPMSD(int code) {
  switch (code) {
  case 0: return "None";
  case 8: return "Point";
  case 9: return "Horizontal block";
  case 10: return "Vertical block";
  case 11: return "L-form";
  case 12: return "Z-form";
  case 13: return "J-form";
  case 14: return "T-form";
  case 15: return "Dense composite block";
  default: return "None";
  }
}

int[][] shapeFromPMSD(int code) {
  switch (code) {
  case 0:
    return new int[][] {};
  case 8:
    return new int[][] { {0, 0} };
  case 9:
    return new int[][] { {-1, 0}, {0, 0}, {1, 0}, {2, 0} };
  case 10:
    return new int[][] { {0, -1}, {0, 0}, {0, 1}, {0, 2} };
  case 11:
    return new int[][] { {0, -1}, {0, 0}, {0, 1}, {1, 1} };
  case 12:
    return new int[][] { {0, -1}, {0, 0}, {1, 0}, {1, 1} };
  case 13:
    return new int[][] { {0, -1}, {0, 0}, {0, 1}, {-1, 1} };
  case 14:
    return new int[][] { {-1, 0}, {0, 0}, {1, 0}, {0, 1} };
  case 15:
    return new int[][] { {0, 0}, {1, 0}, {0, 1}, {1, 1} };
  default:
    return new int[][] {};
  }
}

int interpretPMSDForShape(int rawCode) {
  if (rawCode == 0) return 0;

  float r = random(1);

  switch (rawCode) {
  case 8:
    if (r < 0.65) return 8;
    if (r < 0.82) return 9;
    if (r < 0.94) return 10;
    return 11;
  case 9:
    if (r < 0.60) return 9;
    if (r < 0.78) return 8;
    if (r < 0.90) return 11;
    return 14;
  case 10:
    if (r < 0.60) return 10;
    if (r < 0.78) return 8;
    if (r < 0.90) return 11;
    return 14;
  case 11:
    if (r < 0.55) return 11;
    if (r < 0.70) return 9;
    if (r < 0.85) return 10;
    return 14;
  case 12:
    if (r < 0.55) return 12;
    if (r < 0.70) return 13;
    if (r < 0.85) return 14;
    return 11;
  case 13:
    if (r < 0.55) return 13;
    if (r < 0.70) return 12;
    if (r < 0.85) return 14;
    return 11;
  case 14:
    if (r < 0.50) return 14;
    if (r < 0.68) return 11;
    if (r < 0.84) return 12;
    return 13;
  case 15:
    if (r < 0.45) return 15;
    if (r < 0.62) return 14;
    if (r < 0.77) return 11;
    if (r < 0.89) return 12;
    return 13;
  }

  return rawCode;
}

class FallingData {
  int binaryCode;
  int rawBinaryCode;
  int interpretedShapeCode;
  String binaryText;
  String interpretationText;
  String shapeName;
  int rotation;
  int column;
  int row;
  float confidence;
  float misread;
  float voiceSolidity;
  boolean humanConfirmed;
  boolean machineVerified;
  int lastHumanVoiceTime;

  FallingData(int rawCode) {
    this.rawBinaryCode = rawCode;
    this.interpretedShapeCode = rawCode;
    this.binaryCode = interpretedShapeCode;
    this.binaryText = binary(rawCode, 4);
    this.interpretationText = interpretationFromPMSD(rawCode);
    this.shapeName = shapeNameFromPMSD(interpretedShapeCode);
    rotation = 0;
    column = COLS / 2;
    row = -1;
    confidence = input.confidence();
    misread = input.conflict;
    voiceSolidity = 0.12;
    humanConfirmed = false;
    machineVerified = false;
    lastHumanVoiceTime = -99999;
  }

  int[][] cells() {
    int[][] source = shapeFromPMSD(interpretedShapeCode);
    int[][] result = new int[source.length][2];

    for (int i = 0; i < source.length; i++) {
      int x = source[i][0];
      int y = source[i][1];

      for (int r = 0; r < rotation; r++) {
        int previousX = x;
        x = -y;
        y = previousX;
      }

      result[i][0] = x;
      result[i][1] = y;
    }

    return result;
  }
}

void spawnData() {
  currentPMSD = computePMSDCode();
  currentBinaryCode = binary4(currentPMSD);
  currentMachineInterpretation = interpretationFromPMSD(currentPMSD);

  active = new FallingData(currentPMSD);
  currentShapeName = active.shapeName;

  motionDetected = false;
  lastMotionTime = -99999;
  previousMotionUsL = -1;
  previousMotionUsR = -1;

  pendingMoveDirection = 0;
  pendingMoveSteps = 0;
  ultrasonicX = active.column;
  input.horizontal = active.column / float(COLS - 1);
  lineFieldDirty = true;

  if (currentPMSD == 0 || active.cells().length == 0) {
    return;
  }

  if (!isValid(active.column, active.row, active.rotation)) {
    accumulationFull = true;
  }
}

void updateFallingData(int now) {
  if (accumulationFull) return;

  if (active.cells().length == 0) {
    if (now - lastDropTime >= dropInterval) {
      spawnData();
      lastDropTime = now;
    }
    return;
  }

  active.confidence = lerp(active.confidence, input.confidence(), 0.035);
  active.misread = max(input.conflict, active.misread * 0.985);

  if (active.confidence < 0.22 && frameCount - lastConflictParticleFrame > 16 && random(1) < 0.025) {
    addConflictFromActive(map(active.confidence, 0.22, 0.05, 0.25, 0.75));
  }

  int interval = input.softDrop ? 65 : dropInterval;

  if (now - lastDropTime >= interval) {
    if (isValid(active.column, active.row + 1, active.rotation)) {
      addBlockTrailFromActive(0.74);
      addTraceFromActive(0.38);
      active.row++;
      addDataTraceParticlesFromActive(0.44);
      lineFieldDirty = true;
    } else {
      depositActive();
      spawnData();
    }

    lastDropTime = now;
  }
}

boolean moveActive(int direction) {
  int nextColumn = active.column + direction;

  if (isValid(nextColumn, active.row, active.rotation)) {
    motionDetected = true;
    lastMotionTime = millis();

    addBlockTrailFromActive(0.82);
    addTraceFromActive(0.28);
    active.column = nextColumn;
    addDataTraceParticlesFromActive(0.62);
    ultrasonicX = active.column;
    input.horizontal = active.column / float(COLS - 1);
    lineFieldDirty = true;
    return true;
  }

  return false;
}

void rotateActive() {
  int nextRotation = (active.rotation + 1) % 4;
  int[] horizontalKick = {0, -1, 1, 0, 0};
  int[] verticalKick = {0, 0, 0, -1, -2};

  for (int i = 0; i < horizontalKick.length; i++) {
    int testColumn = active.column + horizontalKick[i];
    int testRow = active.row + verticalKick[i];

    if (isValid(testColumn, testRow, nextRotation)) {
      addBlockTrailFromActive(0.78);
      addTraceFromActive(0.42);
      active.column = testColumn;
      active.row = testRow;
      active.rotation = nextRotation;
      addDataTraceParticlesFromActive(0.70);
      lineFieldDirty = true;
      return;
    }
  }
}

boolean isValid(int column, int row, int rotation) {
  int previousRotation = active.rotation;
  active.rotation = rotation;
  int[][] cells = active.cells();
  active.rotation = previousRotation;

  for (int i = 0; i < cells.length; i++) {
    int x = column + cells[i][0];
    int y = row + cells[i][1];

    if (x < 0 || x >= COLS || y >= ROWS) return false;
    if (y >= 0 && sediment[x][y].occupied) return false;
  }

  return true;
}

void depositActive() {
  int[][] cells = active.cells();
  int pieceId = nextSedimentPieceId++;

  float storedConfidence = constrain(
    active.confidence - active.misread * random(0.15, 0.42),
    0.04, 1
  );

  boolean voiceLocked = humanVoiceConfirmedForLanding();
  float landingSolidity = active.voiceSolidity;

  if (voiceLocked) {
    landingSolidity = constrain(landingSolidity, LANDED_CONFIRMED_SOLIDITY, 1.0);
    storedConfidence = max(storedConfidence, 0.68);
  }

  float storedSolidity = interpretSolidityForSediment(landingSolidity, storedConfidence, active.misread, voiceLocked);

  for (int i = 0; i < cells.length; i++) {
    int x = active.column + cells[i][0];
    int y = active.row + cells[i][1];

    if (x >= 0 && x < COLS && y >= 0 && y < ROWS) {
      int landedBit = pmsdBitForCell(active, i, x, y);
      sediment[x][y].store(storedConfidence, active.misread, storedSolidity, pieceId, active.machineVerified, active.interpretedShapeCode);
      trace[x][y] = max(trace[x][y], 0.95);
      traceBit[x][y] = landedBit;
      if (active.misread > 0.42 || storedConfidence < 0.28) {
        addConflictAtCell(x, y, active.misread + (1.0 - storedConfidence) * 0.35);
      }
    }
  }

  lineFieldDirty = true;
}

boolean humanVoiceConfirmedForLanding() {
  if (active == null) return false;
  boolean recentVoice = millis() - active.lastHumanVoiceTime <= VOICE_LANDING_MEMORY_MS;
  return active.humanConfirmed && recentVoice && active.voiceSolidity >= LANDED_CONFIRMED_SOLIDITY * 0.92;
}

float interpretSolidityForSediment(float sourceSolidity, float confidence, float misread, boolean voiceLocked) {
  if (voiceLocked) {
    return constrain(sourceSolidity, LANDED_CONFIRMED_SOLIDITY, 1.0);
  }

  return constrain(sourceSolidity, 0.10, LANDED_CONFIRMED_SOLIDITY - 0.04);
}

// Custom typed game state lives after its classes for Processing's preprocessor.
FallingData active;
InputState input = new InputState();
