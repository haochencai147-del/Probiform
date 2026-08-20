// Data Sedimentation - split tab
// This file is part of WSAA2_06.pde and is compiled by Processing with the main sketch.

// Game timing and PMSD state.
int lastDropTime;
int dropInterval = 500;
boolean accumulationFull = false;
boolean exhibitionAutoplayEnabled = true;
int exhibitionRecycleCount = 0;
final int PARTICIPANT_HISTORY_SIZE = 16;
int[] participantShapeHistory = new int[PARTICIPANT_HISTORY_SIZE];
int[] participantColumnHistory = new int[PARTICIPANT_HISTORY_SIZE];
int participantHistoryCount = 0;
int participantHistoryWrite = 0;

boolean probabilisticFallRotationEnabled = true;
final int PROB_ROTATION_MAX = 2;
final int PROB_ROTATION_MIN_ROW_GAP = 2;
final int PROB_ROTATION_TRIGGER_DISTANCE = 5;
final float PROB_ROTATION_SCORE_THRESHOLD = 1.15;

int currentPMSD = 0;
String currentBinaryCode = "0000";
String currentMachineInterpretation = "";
String currentShapeName = "";

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
  if (key == 'u' || key == 'U') {
    toggleArduinoSerialConnection();
    return;
  }

  if (key == 't' || key == 'T') {
    keyboardTestMode = !keyboardTestMode;
    if (keyboardTestMode) {
      stopMachineAudio();
    }
    println("Keyboard test mode: " + (keyboardTestMode ? "ON" : "OFF"));
    return;
  }

  if (key == 'p' || key == 'P') {
    generateCurrentQrArchive();
    return;
  }

  if (key == 'i' || key == 'I') {
    showLatestQrArchive();
    return;
  }
  if (key == 'v' || key == 'V') {
    sendArduinoCommand("STOP_SYSTEM");
    return;
  }
  if (key == 'b' || key == 'B') {
    resetVoiceCalibration();
    return;
  }
  if (key == 'm' || key == 'M') {
    machineAudioEnabled = !machineAudioEnabled;
    if (!machineAudioEnabled) stopMachineAudio();
    return;
  }
  if (key == 'c' || key == 'C') {
    clearSediment();
    return;
  }

  // Movement and simulated sensor input are available only in the
  // keyboard fallback used when Arduino hardware is not connected.
  if (!keyboardTestMode) return;
  handleKeyboardTestKeyPressed();

  if (key == 'a' || key == 'A' || keyCode == LEFT) {
    notifyLRIndicator(-1);
    moveActive(-1);
  }
  if (key == 'd' || key == 'D' || keyCode == RIGHT) {
    notifyLRIndicator(1);
    moveActive(1);
  }
  if (key == 'w' || key == 'W' || keyCode == UP) rotateActive();
  if (key == 's' || key == 'S' || keyCode == DOWN) {
    markClearParticipantEvidence();
    input.softDrop = true;
  }
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

  if (key == ' ') {
    input.conflict = 1;
    active.misread = 1;
    addTraceFromActive(0.85);
    addConflictFromActive(0.90);
  }

}

void handleKeyboardTestKeyPressed() {
  if (key == 'r' || key == 'R') {
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
  int probabilisticRotationsUsed;
  int lastProbabilisticRotationRow;
  boolean lowConfidenceInference;
  int unattendedDriftCount;
  int lastUnattendedDriftRow;

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
    probabilisticRotationsUsed = 0;
    lastProbabilisticRotationRow = -99999;
    lowConfidenceInference = false;
    unattendedDriftCount = 0;
    lastUnattendedDriftRow = -99999;
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
  boolean inferredBirth = exhibitionAutoplayEnabled && unattendedMode;
  currentPMSD = inferredBirth ? inferUnattendedPMSDCode() : computePMSDCode();
  currentBinaryCode = binary4(currentPMSD);
  currentMachineInterpretation = inferredBirth
    ? "LOW-CONFIDENCE ENVIRONMENTAL INFERENCE"
    : interpretationFromPMSD(currentPMSD);

  active = new FallingData(currentPMSD);
  active.lowConfidenceInference = inferredBirth;
  if (inferredBirth) {
    active.confidence = unattendedInferenceConfidence();
    active.misread = constrain(0.18 + (1.0 - active.confidence) * 0.20, 0.18, 0.38);
    active.voiceSolidity = constrain(0.10 + unattendedAmbientAudioLevel() * 0.12, 0.10, 0.24);
  }
  currentShapeName = active.shapeName;

  if (currentPMSD != 0 && active.cells().length > 0) {
    boolean outletFound = placeActiveAtExhibitionOutlet();
    if (!outletFound && exhibitionAutoplayEnabled) {
      int recycleRows = chooseExhibitionRecycleRows();
      recycleExhibitionRows(recycleRows);
      outletFound = placeActiveAtExhibitionOutlet();
      currentMachineInterpretation = "RECYCLE " + recycleRows + " ROWS";
    }
    accumulationFull = !outletFound;
  }

  motionDetected = false;
  lastMotionTime = -99999;
  previousMotionUsL = -1;
  previousMotionUsR = -1;

  pendingMoveDirection = 0;
  pendingMoveSteps = 0;
  lastUltrasonicStepRequestTime = -99999;
  ultrasonicX = active.column;
  input.horizontal = active.column / float(COLS - 1);

  if (currentPMSD == 0 || active.cells().length == 0) {
    return;
  }

  if (!isValid(active.column, active.row, active.rotation)) accumulationFull = true;
}

int inferUnattendedPMSDCode() {
  float audio = unattendedAmbientAudioLevel();
  float radar = weakRadarEvidence();
  boolean distanceEvidence = leftValid || rightValid ||
    inShapeDistanceRange(usL) || inShapeDistanceRange(usR);

  int environmentCode = 8;
  if (radar > 0.10 || millis() - lastAmbientUltrasonicMotionTime < 4500) environmentCode |= 4;
  if (audio > 0.12) environmentCode |= 2;
  if (distanceEvidence) environmentCode |= 1;

  // Historical participant data acts as a prior, while current weak sensor
  // evidence can reassert individual M/S/D bits.
  if (participantHistoryCount > 0 && random(1) < 0.46) {
    int historyIndex = int(random(participantHistoryCount));
    int historicalCode = participantShapeHistory[historyIndex];
    int code = 8 | (historicalCode & 7);
    if (radar > random(0.18, 0.72)) code |= 4;
    if (audio > random(0.16, 0.70)) code |= 2;
    if (distanceEvidence && random(1) < 0.72) code |= 1;
    return constrain(code, 8, 15);
  }

  return environmentCode;
}

float unattendedInferenceConfidence() {
  float ultrasoundEvidence = (leftValid || rightValid || inShapeDistanceRange(usL) || inShapeDistanceRange(usR)) ? 1 : 0;
  float evidence = unattendedAmbientAudioLevel() * 0.34 +
    weakRadarEvidence() * 0.46 + ultrasoundEvidence * 0.20;
  return constrain(0.08 + evidence * 0.20, 0.08, 0.28);
}

boolean placeActiveAtExhibitionOutlet() {
  if (active == null || active.cells().length == 0) return false;
  int[][] cells = active.cells();
  int minOffsetX = 999;
  int maxOffsetX = -999;
  int minOffsetY = 999;
  for (int i = 0; i < cells.length; i++) {
    minOffsetX = min(minOffsetX, cells[i][0]);
    maxOffsetX = max(maxOffsetX, cells[i][0]);
    minOffsetY = min(minOffsetY, cells[i][1]);
  }

  int firstColumn = max(0, -minOffsetX);
  int lastColumn = min(COLS - 1, COLS - 1 - maxOffsetX);
  int candidateCount = lastColumn - firstColumn + 1;
  if (candidateCount <= 0) return false;

  int entryRow = max(active.row, -minOffsetY);
  int[] validColumns = new int[candidateCount];
  int validCount = 0;
  for (int candidate = firstColumn; candidate <= lastColumn; candidate++) {
    if (isValid(candidate, entryRow, active.rotation)) validColumns[validCount++] = candidate;
  }
  if (validCount == 0) return false;

  // Participant and unattended blocks both use a uniform random legal outlet.
  // Sensor/history data may influence an inferred shape, but not its spawn side.
  active.column = validColumns[int(random(validCount))];
  return true;
}

int chooseExhibitionRecycleRows() {
  // Preserve the accumulated field: release only the minimum space needed.
  // If one row is not enough, the next update will release one more row.
  return 1;
}

void updateFallingData(int now) {
  if (accumulationFull) {
    if (exhibitionAutoplayEnabled) {
      recycleExhibitionRows(chooseExhibitionRecycleRows());
      accumulationFull = false;
      spawnData();
      lastDropTime = now;
    }
    return;
  }
  if (active.cells().length == 0) {
    if (now - lastDropTime >= dropInterval) {
      spawnData();
      lastDropTime = now;
    }
    return;
  }

  if (active.lowConfidenceInference) {
    active.confidence = lerp(active.confidence, unattendedInferenceConfidence(), 0.020);
  } else {
    active.confidence = lerp(active.confidence, input.confidence(), 0.035);
  }
  active.misread = max(input.conflict, active.misread * 0.985);

  if (!active.lowConfidenceInference && active.confidence < 0.22 &&
      frameCount - lastConflictParticleFrame > 16 && random(1) < 0.025) {
    addConflictFromActive(map(active.confidence, 0.22, 0.05, 0.25, 0.75));
  }

  int interval = input.softDrop ? 65 : dropInterval;

  if (now - lastDropTime >= interval) {
    if (isValid(active.column, active.row + 1, active.rotation)) {
      addBlockTrailFromActive(0.74);
      addTraceFromActive(0.38);
      active.row++;
      if (active.lowConfidenceInference) applyUnattendedInferenceDrift();
      else maybeProbabilisticRotateActiveDuringFall();
    } else {
      depositActive();
      spawnData();
    }

    lastDropTime = now;
  }
}

void applyUnattendedInferenceDrift() {
  if (active == null || !active.lowConfidenceInference) return;
  if (active.unattendedDriftCount >= 3) return;
  if (active.row - active.lastUnattendedDriftRow < 3) return;

  float audio = unattendedAmbientAudioLevel();
  float radar = weakRadarEvidence();
  float chance = constrain(0.08 + audio * 0.16 + radar * 0.18, 0.08, 0.32);
  if (random(1) >= chance) return;

  boolean changed = false;
  if (random(1) < 0.56) {
    int direction = random(1) < 0.5 ? -1 : 1;
    if (isValid(active.column + direction, active.row, active.rotation)) {
      active.column += direction;
      changed = true;
    }
  } else if (active.probabilisticRotationsUsed < 2) {
    int turn = random(1) < 0.5 ? 1 : 3;
    int nextRotation = (active.rotation + turn) % 4;
    if (tryRotateActiveTo(nextRotation, 0.30, 0.18)) {
      active.probabilisticRotationsUsed++;
      changed = true;
    }
  }

  if (changed) {
    active.unattendedDriftCount++;
    active.lastUnattendedDriftRow = active.row;
    currentMachineInterpretation = "WEAK SIGNAL / HYPOTHESIS DRIFT";
  }
}

boolean moveActive(int direction) {
  markClearParticipantEvidence();
  int nextColumn = active.column + direction;

  if (isValid(nextColumn, active.row, active.rotation)) {
    motionDetected = true;
    lastMotionTime = millis();

    addBlockTrailFromActive(0.82);
    addTraceFromActive(0.28);
    active.column = nextColumn;
    ultrasonicX = active.column;
    input.horizontal = active.column / float(COLS - 1);
    return true;
  }

  return false;
}

void rotateActive() {
  markClearParticipantEvidence();
  int nextRotation = (active.rotation + 1) % 4;
  tryRotateActiveTo(nextRotation, 0.78, 0.42);
}

void maybeProbabilisticRotateActiveDuringFall() {
  if (!probabilisticFallRotationEnabled) return;
  if (active == null || active.cells().length == 0) return;
  if (active.row < 0) return;
  if (active.probabilisticRotationsUsed >= PROB_ROTATION_MAX) return;
  if (active.row - active.lastProbabilisticRotationRow < PROB_ROTATION_MIN_ROW_GAP) return;

  int distance = landingDistanceForRotation(active.column, active.row, active.rotation);
  if (distance > PROB_ROTATION_TRIGGER_DISTANCE) return;

  int currentRotation = active.rotation;
  float currentScore = rotationLandingScore(active.column, active.row, currentRotation);
  float bestScore = currentScore;
  float secondScore = -9999;
  int bestRotation = currentRotation;
  int secondRotation = currentRotation;
  int bestColumn = active.column;
  int bestRow = active.row;
  int secondColumn = active.column;
  int secondRow = active.row;

  for (int r = 0; r < 4; r++) {
    if (r == currentRotation) continue;
    int[] fit = fittedRotationPlacement(r);
    if (fit == null) continue;

    float score = rotationLandingScore(fit[0], fit[1], r);
    if (score > bestScore) {
      secondScore = bestScore;
      secondRotation = bestRotation;
      secondColumn = bestColumn;
      secondRow = bestRow;
      bestScore = score;
      bestRotation = r;
      bestColumn = fit[0];
      bestRow = fit[1];
    } else if (score > secondScore) {
      secondScore = score;
      secondRotation = r;
      secondColumn = fit[0];
      secondRow = fit[1];
    }
  }

  if (bestRotation == currentRotation) return;
  if (bestScore - currentScore < PROB_ROTATION_SCORE_THRESHOLD) return;

  float misreadChance = map(constrain(active.confidence, 0.05, 1.0), 0.05, 1.0, 0.20, 0.04);
  int chosenRotation = bestRotation;
  int chosenColumn = bestColumn;
  int chosenRow = bestRow;
  if (secondRotation != currentRotation && secondScore > currentScore && random(1) < misreadChance) {
    chosenRotation = secondRotation;
    chosenColumn = secondColumn;
    chosenRow = secondRow;
  }

  currentMachineInterpretation = "HYPOTHESIS TEST";

  if (applyRotationPlacement(chosenColumn, chosenRow, chosenRotation, 0.56, 0.26)) {
    active.probabilisticRotationsUsed++;
    active.lastProbabilisticRotationRow = active.row;
  }
}

int[] fittedRotationPlacement(int nextRotation) {
  int[] horizontalKick = {0, -1, 1, 0, 0};
  int[] verticalKick = {0, 0, 0, -1, -2};

  for (int i = 0; i < horizontalKick.length; i++) {
    int testColumn = active.column + horizontalKick[i];
    int testRow = active.row + verticalKick[i];
    if (isValid(testColumn, testRow, nextRotation)) {
      return new int[] {testColumn, testRow};
    }
  }

  return null;
}

boolean applyRotationPlacement(int column, int row, int rotation, float trailStrength, float traceStrength) {
  if (!isValid(column, row, rotation)) return false;

  addBlockTrailFromActive(trailStrength);
  addTraceFromActive(traceStrength);
  active.column = column;
  active.row = row;
  active.rotation = rotation;
  return true;
}

int landingDistanceForRotation(int column, int row, int rotation) {
  int distance = 0;
  while (isValid(column, row + distance + 1, rotation)) {
    distance++;
    if (distance > ROWS) break;
  }
  return distance;
}

float rotationLandingScore(int column, int row, int rotation) {
  int landingRow = row + landingDistanceForRotation(column, row, rotation);
  int previousRotation = active.rotation;
  active.rotation = rotation;
  int[][] cells = active.cells();
  active.rotation = previousRotation;

  int contact = 0;
  int holes = 0;
  int minY = ROWS;
  int maxY = -ROWS;
  boolean[] touchedColumns = new boolean[COLS];

  for (int i = 0; i < cells.length; i++) {
    int x = column + cells[i][0];
    int y = landingRow + cells[i][1];
    if (x < 0 || x >= COLS || y < 0 || y >= ROWS) continue;

    minY = min(minY, y);
    maxY = max(maxY, y);
    touchedColumns[x] = true;

    if (y + 1 >= ROWS || sediment[x][y + 1].occupied) contact += 3;
    if (x > 0 && sediment[x - 1][y].occupied) contact++;
    if (x < COLS - 1 && sediment[x + 1][y].occupied) contact++;

    for (int scanY = y + 1; scanY < ROWS; scanY++) {
      if (!sediment[x][scanY].occupied) {
        holes++;
        break;
      }
    }
  }

  int roughness = 0;
  int previousHeight = -1;
  for (int x = 0; x < COLS; x++) {
    if (!touchedColumns[x]) continue;
    int height = projectedColumnHeight(column, landingRow, rotation, x);
    if (previousHeight >= 0) roughness += abs(height - previousHeight);
    previousHeight = height;
  }

  float stabilityWeight = map(constrain(active.confidence, 0.05, 1.0), 0.05, 1.0, 0.8, 1.45);
  float heightPenalty = max(0, ROWS - minY) * 0.025;
  return contact * stabilityWeight - holes * 2.15 - roughness * 0.42 - heightPenalty - (maxY - minY) * 0.08;
}

int projectedColumnHeight(int column, int landingRow, int rotation, int targetX) {
  int previousRotation = active.rotation;
  active.rotation = rotation;
  int[][] cells = active.cells();
  active.rotation = previousRotation;

  int topY = ROWS;
  for (int y = 0; y < ROWS; y++) {
    if (sediment[targetX][y].occupied) {
      topY = y;
      break;
    }
  }

  for (int i = 0; i < cells.length; i++) {
    int x = column + cells[i][0];
    int y = landingRow + cells[i][1];
    if (x == targetX && y >= 0 && y < ROWS) topY = min(topY, y);
  }

  return ROWS - topY;
}

boolean tryRotateActiveTo(int nextRotation, float trailStrength, float traceStrength) {
  int[] horizontalKick = {0, -1, 1, 0, 0};
  int[] verticalKick = {0, 0, 0, -1, -2};

  for (int i = 0; i < horizontalKick.length; i++) {
    int testColumn = active.column + horizontalKick[i];
    int testRow = active.row + verticalKick[i];

    if (isValid(testColumn, testRow, nextRotation)) {
      addBlockTrailFromActive(trailStrength);
      addTraceFromActive(traceStrength);
      active.column = testColumn;
      active.row = testRow;
      active.rotation = nextRotation;
      return true;
    }
  }

  return false;
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
  triggerOscDropBang();
  triggerMachineDropClick();
  notifyBlockDepositedForQr();

  int[][] cells = active.cells();
  int pieceId = nextSedimentPieceId++;

  if (!active.lowConfidenceInference && active.interpretedShapeCode >= 8) {
    participantShapeHistory[participantHistoryWrite] = active.interpretedShapeCode;
    participantColumnHistory[participantHistoryWrite] = constrain(active.column, 0, COLS - 1);
    participantHistoryWrite = (participantHistoryWrite + 1) % PARTICIPANT_HISTORY_SIZE;
    participantHistoryCount = min(PARTICIPANT_HISTORY_SIZE, participantHistoryCount + 1);
  }

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
      boolean storedMachineVerified = active.machineVerified && !active.lowConfidenceInference;
      sediment[x][y].store(storedConfidence, active.misread, storedSolidity, pieceId, storedMachineVerified, active.interpretedShapeCode, active.rotation, active.lowConfidenceInference);
      trace[x][y] = max(trace[x][y], 0.95);
      traceBit[x][y] = landedBit;
      if (!active.lowConfidenceInference && (active.misread > 0.42 || storedConfidence < 0.28)) {
        addConflictAtCell(x, y, active.misread + (1.0 - storedConfidence) * 0.35);
      }
    }
  }

}

boolean humanVoiceConfirmedForLanding() {
  if (active == null) return false;
  if (active.lowConfidenceInference) return false;
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
