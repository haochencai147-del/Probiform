// Data Sedimentation - split tab
// This file is part of WSAA2_06.pde and is compiled by Processing with the main sketch.

// Sensor and audio state.
Serial arduinoPort;
final int SERIAL_BAUD_RATE = 115200;

// Keyboard-only test mode. Set this to false when testing with Arduino again,
// or press T while the sketch is running.
boolean keyboardTestMode = true;
boolean testPresence = true;
boolean testDistance = true;
float testUltrasonicCm = 17;
float testVoiceRaw = 0;
float testMachineRaw = 0;

float usL = -1;
float usR = -1;
float smoothUsL = -1;
float smoothUsR = -1;
boolean leftValid = false;
boolean rightValid = false;
String ultrasonicDirection = "NONE";
boolean arduinoActive = false;
boolean ultrasonicDataPending = false;
boolean ultrasonicTriggerArmed = true;

final float ULTRASONIC_MIN_CM = 5;
final float ULTRASONIC_MAX_CM = 30;
final float ULTRASONIC_DIRECTION_GAP_CM = 5;

int lastMoveTime = 0;
final int moveCooldown = 190;
int pendingMoveDirection = 0;
int pendingMoveSteps = 0;

boolean motionDetected = false;
int lastMotionTime = -99999;
final int MOTION_HOLD_MS = 900;

float previousMotionUsL = -1;
float previousMotionUsR = -1;
final float MOTION_DISTANCE_DELTA_CM = 1.8;

float ultrasonicX = COLS / 2;

// KY-038 human voice.
float soundRaw = 0;
float kyLeftRaw = 0;
float kyRightRaw = 0;
float kyCombinedRaw = 0;

float soundLevel = 0;
float voiceEnergy = 0;
float blockSolidity = 0.12;
float directMappedSolidity = 0.12;
final float LANDED_CONFIRMED_SOLIDITY = 0.62;
final float LANDED_LOCKED_SOLIDITY = 0.70;
final int VOICE_LANDING_MEMORY_MS = 2600;

float voiceEnvelope = 0;
float voicePeakHold = 0;
float voiceHold = 0;
float voiceConfirm = 0;

float voiceBaseline = 0;
float voiceDelta = 0;
float effectiveVoiceThreshold = 18;
int voiceCalibrationStartTime = -99999;
final int VOICE_CALIBRATION_MS = 2600;

boolean speaking = false;
boolean externalVoiceCandidate = false;
boolean voiceBaselineReady = false;

int voiceThreshold = 17;
float voiceActivationMargin = 3.5;
int speakingFramesNeeded = 3;
int silenceFramesNeeded = 18;

int strongVoiceFramesNeeded = 2;
int normalVoiceFramesNeeded = 4;
float voiceCandidateThreshold = 4.5;
float strongVoiceThreshold = 12.0;
int voiceCandidateStartTime = -99999;
int sustainedVoiceCandidateStartTime = -99999;
int lastVoiceSignalTime = -99999;
final int VOICE_CONFIRM_MS = 460;
final int VOICE_RELEASE_MS = 260;
final int VOICE_BASELINE_LEARN_MS = 1800;
final int VOICE_BASELINE_FORCE_RELEASE_MS = 2600;

int speakingFrameCount = 0;
int silenceFrameCount = 0;

// MAX9814 machine feedback.
float machineRaw = 0;
float maxLeftRaw = 0;
float maxRightRaw = 0;
float machineNoiseLevel = 0;
float targetMachineNoise = 0;

float machineValidation = 0;
float targetMachineValidation = 0;

float machineLow = 40;
float machineHigh = 320;

boolean machineResponding = false;
boolean selfNoiseOnly = false;

float machineNoiseThreshold = 0.45;

int lastMachineRotateTime = 0;
final int machineRotateCooldown = 900;
float machineRotatePressure = 0;

// Machine audio synthesis.
Env signalEnv;
SinOsc signalBeep;
WhiteNoise signalClick;

boolean machineAudioEnabled = true;

int lastBeepTime = 0;
int beepInterval = 260;

// ------------------------------------------------------------
// SERIAL INPUT

void initArduinoSerial() {
  String[] ports = Serial.list();

  if (ports.length == 0) {
    println("No serial ports found.");
    return;
  }

  int selectedPort = -1;

  for (int i = 0; i < ports.length; i++) {
    String portName = ports[i].toLowerCase();
    if (portName.indexOf("usbmodem") >= 0 ||
        portName.indexOf("usbserial") >= 0 ||
        portName.indexOf("arduino") >= 0) {
      selectedPort = i;
      break;
    }
  }

  if (selectedPort < 0) selectedPort = 0;

  try {
    arduinoPort = new Serial(this, ports[selectedPort], SERIAL_BAUD_RATE);
    arduinoPort.clear();
    println("Arduino serial port: " + ports[selectedPort]);
  }
  catch (Exception e) {
    arduinoPort = null;
    println("Could not open serial port: " + e.getMessage());
  }
}

void readSerialData() {
  if (arduinoPort == null) return;

  while (arduinoPort.available() > 0) {
    String line = arduinoPort.readStringUntil('\n');
    if (line == null) break;
    parseSerialLine(trim(line));
  }
}

void updateKeyboardTestInput(float dt) {
  if (!keyboardTestMode) return;

  if (!voiceBaselineReady) {
    voiceBaseline = 0;
    voiceBaselineReady = true;
    voiceCalibrationStartTime = millis() - VOICE_CALIBRATION_MS;
  }

  arduinoActive = testPresence;

  if (!testPresence) {
    usL = -1;
    usR = -1;
    smoothUsL = -1;
    smoothUsR = -1;
    leftValid = false;
    rightValid = false;
    ultrasonicDataPending = false;
    ultrasonicDirection = "NONE";
    pendingMoveDirection = 0;
    pendingMoveSteps = 0;
  } else if (testDistance) {
    usL = testUltrasonicCm;
    usR = testUltrasonicCm;
    ultrasonicDataPending = true;
    lastPresenceTime = millis();
    lastDistanceTime = millis();
  } else {
    usL = -1;
    usR = -1;
    ultrasonicDataPending = true;
    lastPresenceTime = millis();
  }

  kyLeftRaw = testVoiceRaw;
  kyRightRaw = testVoiceRaw;
  soundRaw = testVoiceRaw;
  maxLeftRaw = testMachineRaw;
  maxRightRaw = testMachineRaw;
  machineRaw = testMachineRaw;
}

void parseSerialLine(String line) {
  if (line == null || line.length() == 0) return;

  String upperLine = line.toUpperCase();

  if (upperLine.indexOf("ACTIVE DATA") >= 0 ||
      upperLine.indexOf("MIC_") >= 0 ||
      upperLine.indexOf("US_L") >= 0 ||
      upperLine.indexOf("US_R") >= 0 ||
      upperLine.indexOf("IR:") >= 0) {
    arduinoActive = true;
    lastPresenceTime = millis();
  }

  if (upperLine.indexOf("SYSTEM STOP") >= 0 ||
      upperLine.indexOf("WAITING") >= 0) {
    arduinoActive = false;
    ultrasonicDataPending = false;
    leftValid = false;
    rightValid = false;
    smoothUsL = -1;
    smoothUsR = -1;
    ultrasonicTriggerArmed = true;
    pendingMoveDirection = 0;
    pendingMoveSteps = 0;
    ultrasonicDirection = "NONE";
    lastPresenceTime = -99999;
    lastMotionTime = -99999;
    lastSoundTime = -99999;
    lastDistanceTime = -99999;
    previousMotionUsL = -1;
    previousMotionUsR = -1;
  } else if (upperLine.indexOf("SYSTEM START") >= 0 ||
             upperLine.indexOf("ACTIVE DATA") >= 0) {
    arduinoActive = true;
    lastPresenceTime = millis();
  }

  String[] micBlValues = match(upperLine, "MIC_BL(?:\\s+KY038)?\\s*:?\\s*(-?\\d+(?:\\.\\d+)?)");
  String[] micBrValues = match(upperLine, "MIC_BR(?:\\s+KY038)?\\s*:?\\s*(-?\\d+(?:\\.\\d+)?)");

  if (micBlValues != null || micBrValues != null) {
    if (micBlValues != null) kyLeftRaw = float(micBlValues[1]);
    if (micBrValues != null) kyRightRaw = float(micBrValues[1]);

    kyCombinedRaw = max(kyLeftRaw, kyRightRaw);
    soundRaw = kyCombinedRaw;
  }

  String[] micFlMaxValues = match(upperLine, "MIC_FL(?:\\s+MAX9814)?\\s*:?\\s*(-?\\d+(?:\\.\\d+)?)");
  String[] micFrMaxValues = match(upperLine, "MIC_FR(?:\\s+MAX9814)?\\s*:?\\s*(-?\\d+(?:\\.\\d+)?)");

  if (micFlMaxValues != null || micFrMaxValues != null) {
    if (micFlMaxValues != null) maxLeftRaw = float(micFlMaxValues[1]);
    if (micFrMaxValues != null) maxRightRaw = float(micFrMaxValues[1]);

    machineRaw = max(maxLeftRaw, maxRightRaw);
  }

  String[] values = match(
    line,
    "US_L:\\s*(-?\\d+(?:\\.\\d+)?)\\s*cm\\s+US_R:\\s*(-?\\d+(?:\\.\\d+)?)\\s*cm"
  );

  if (values != null) {
    usL = float(values[1]);
    usR = float(values[2]);
    ultrasonicDataPending = true;
  }
}

// ------------------------------------------------------------
// KY-038 VOICE / SOLIDITY

void updateVoiceState() {
  soundRaw = max(kyLeftRaw, kyRightRaw);
  int now = millis();

  if (!voiceBaselineReady && soundRaw > 0) {
    voiceBaseline = soundRaw;
    voiceBaselineReady = true;
    voiceCalibrationStartTime = now;
  }

  boolean calibratingVoice =
    voiceBaselineReady &&
    now - voiceCalibrationStartTime < VOICE_CALIBRATION_MS;

  if (calibratingVoice) {
    voiceBaseline = lerp(voiceBaseline, soundRaw, 0.22);
    voiceDelta = 0;
    soundLevel = lerp(soundLevel, 0, 0.35);
    voiceEnergy = soundLevel;
    voiceEnvelope = soundLevel;
    voicePeakHold = max(0, voicePeakHold - 0.05);
    voiceHold = 0;
    voiceConfirm = 0;
    speaking = false;
    externalVoiceCandidate = false;
    speakingFrameCount = 0;
    silenceFrameCount++;
    voiceCandidateStartTime = -99999;
    directMappedSolidity = 0.12;
    blockSolidity = lerp(blockSolidity, 0.12, 0.10);
    return;
  }

  voiceDelta = max(0, soundRaw - voiceBaseline);

  float targetSoundLevel = constrain(map(voiceDelta, voiceCandidateThreshold, 18, 0, 1), 0, 1);
  if (targetSoundLevel > soundLevel) {
    soundLevel = lerp(soundLevel, targetSoundLevel, 0.38);
  } else {
    soundLevel = lerp(soundLevel, targetSoundLevel, 0.10);
  }

  voiceEnergy = soundLevel;
  voiceEnvelope = soundLevel;

  boolean voiceCandidate = voiceDelta >= voiceCandidateThreshold;
  boolean strongCandidate = voiceDelta >= strongVoiceThreshold && soundLevel > 0.20;
  boolean releaseCandidate = voiceDelta < voiceCandidateThreshold * 0.55 || soundLevel < 0.04;

  if (voiceCandidate) {
    if (sustainedVoiceCandidateStartTime < 0) sustainedVoiceCandidateStartTime = now;

    int sustainedVoiceMs = now - sustainedVoiceCandidateStartTime;

    if (sustainedVoiceMs > VOICE_BASELINE_LEARN_MS) {
      float learnRate = strongCandidate ? 0.045 : 0.025;
      if (sustainedVoiceMs > VOICE_BASELINE_FORCE_RELEASE_MS) learnRate = 0.12;

      voiceBaseline = lerp(voiceBaseline, soundRaw, learnRate);
      voiceDelta = max(0, soundRaw - voiceBaseline);
      targetSoundLevel = constrain(map(voiceDelta, voiceCandidateThreshold, 18, 0, 1), 0, 1);
      soundLevel = lerp(soundLevel, targetSoundLevel, 0.28);
      voiceEnergy = soundLevel;
      voiceEnvelope = soundLevel;
      voiceCandidate = voiceDelta >= voiceCandidateThreshold;
      strongCandidate = voiceDelta >= strongVoiceThreshold && soundLevel > 0.20;
      releaseCandidate = voiceDelta < voiceCandidateThreshold * 0.55 || soundLevel < 0.04;

      if (sustainedVoiceMs > VOICE_BASELINE_FORCE_RELEASE_MS && voiceDelta < strongVoiceThreshold) {
        speaking = false;
        speakingFrameCount = 0;
        voiceCandidateStartTime = -99999;
      }
    }
  } else {
    sustainedVoiceCandidateStartTime = -99999;
  }

  if (!voiceCandidate) {
    float followRate = soundRaw < voiceBaseline ? 0.10 : 0.006;
    voiceBaseline = lerp(voiceBaseline, soundRaw, followRate);
    voiceDelta = max(0, soundRaw - voiceBaseline);
    if (voiceDelta < voiceCandidateThreshold * 0.55) {
      soundLevel = lerp(soundLevel, 0, 0.35);
      voiceEnergy = soundLevel;
      voiceEnvelope = soundLevel;
      releaseCandidate = true;
    }
  }

  if (voiceCandidate) {
    if (voiceCandidateStartTime < 0) voiceCandidateStartTime = now;
    lastVoiceSignalTime = now;
    speakingFrameCount++;
    silenceFrameCount = 0;
  } else if (releaseCandidate) {
    voiceCandidateStartTime = -99999;
    silenceFrameCount++;
    if (voiceDelta < voiceCandidateThreshold * 0.45 ||
        now - lastVoiceSignalTime >= VOICE_RELEASE_MS) {
      speaking = false;
      speakingFrameCount = 0;
    }
  } else {
    speakingFrameCount = 0;
    silenceFrameCount = 0;
  }

  if (strongCandidate && speakingFrameCount >= strongVoiceFramesNeeded) {
    speaking = true;
  }

  if (voiceCandidate && now - voiceCandidateStartTime >= VOICE_CONFIRM_MS) {
    speaking = true;
  }

  externalVoiceCandidate = voiceCandidate;
  effectiveVoiceThreshold = voiceCandidateThreshold;

  if (voiceCandidate) {
    voicePeakHold = max(voicePeakHold, soundLevel);
  } else {
    voicePeakHold = max(0, voicePeakHold - 0.025);
  }

  directMappedSolidity = solidityFromKYRaw(voiceDelta);

  updateActiveVoiceMemory(voiceCandidate, strongCandidate, now);

  if (active != null) {
    blockSolidity = active.voiceSolidity;
  } else {
    blockSolidity = 0.12;
  }

  voiceHold = speaking ? soundLevel : 0;
  voiceConfirm = voiceHold;

  selfNoiseOnly = false;
}

void updateActiveVoiceMemory(boolean voiceCandidate, boolean strongCandidate, int now) {
  if (active == null) return;

  if ((speaking && voiceCandidate) || strongCandidate) {
    float voiceStrength = constrain(soundLevel, 0, 1);
    float confirmedSolidity = map(voiceStrength, 0, 1, 0.28, 0.78);

    if (strongCandidate) {
      float strongAmount = constrain(map(voiceDelta, strongVoiceThreshold, 18, 0, 1), 0, 1);
      confirmedSolidity = max(confirmedSolidity, map(strongAmount, 0, 1, LANDED_CONFIRMED_SOLIDITY, 0.86));
    }

    active.voiceSolidity = lerp(active.voiceSolidity, confirmedSolidity, 0.18);
    active.humanConfirmed = active.voiceSolidity >= LANDED_CONFIRMED_SOLIDITY;
    active.lastHumanVoiceTime = now;
  } else if (voiceCandidate) {
    float candidateSolidity = map(soundLevel, 0, 1, 0.18, 0.46);
    candidateSolidity = min(candidateSolidity, LANDED_CONFIRMED_SOLIDITY - 0.04);
    active.voiceSolidity = lerp(active.voiceSolidity, candidateSolidity, 0.12);
    active.lastHumanVoiceTime = now;
  } else {
    active.voiceSolidity = lerp(active.voiceSolidity, active.humanConfirmed ? LANDED_CONFIRMED_SOLIDITY : 0.12, active.humanConfirmed ? 0.008 : 0.040);
    if (active.voiceSolidity < 0.46) {
      active.humanConfirmed = false;
    }
  }
}

float solidityFromKYRaw(float value) {
  if (value < 1.8) return 0.12;
  if (value < 3.6) return map(value, 1.8, 3.6, 0.12, 0.28);
  if (value < 9.0) return map(value, 3.6, 9.0, 0.28, 0.72);
  if (value < 18.0) return map(value, 9.0, 18.0, 0.72, 1.0);
  return 1.0;
}

// ------------------------------------------------------------
// MAX9814 MACHINE FEEDBACK

void updateMachineFeedback() {
  targetMachineNoise = constrain(map(machineRaw, machineLow, machineHigh, 0, 1), 0, 1);
  machineNoiseLevel = lerp(machineNoiseLevel, targetMachineNoise, 0.08);
  machineResponding = machineNoiseLevel > machineNoiseThreshold;
  selfNoiseOnly = false;

  boolean activeHumanConfirmed = active != null && active.humanConfirmed;

  if (machineResponding && activeHumanConfirmed) {
    targetMachineValidation = machineNoiseLevel;
  } else {
    targetMachineValidation = 0;
  }

  machineValidation = lerp(machineValidation, targetMachineValidation, 0.10);

  if (active != null && activeHumanConfirmed && machineValidation > 0.42) {
    active.machineVerified = true;
    active.confidence = max(active.confidence, 0.62 + machineValidation * 0.25);
    active.misread = max(0, active.misread - 0.015);
  }

  if (active != null && machineResponding && !activeHumanConfirmed && random(1) < 0.012) {
    addConflictFromActive(machineNoiseLevel * 0.55);
  }

  beepInterval = int(map(machineNoiseLevel, 0, 1, 1600, 520));

  if (!arduinoActive || !machineAudioEnabled) {
    stopMachineAudio();
  } else if (millis() - lastBeepTime > beepInterval) {
    float freq = map(machineNoiseLevel, 0, 1, 220, 620);
    float amp = map(machineNoiseLevel, 0, 1, 0.006, 0.026);

    signalBeep.freq(freq);
    signalBeep.amp(amp);
    signalEnv.play(signalBeep, 0.006, 0.05, amp * 0.5, 0.16);

    signalClick.amp(amp * 0.04);
    signalEnv.play(signalClick, 0.004, 0.018, amp * 0.04, 0.08);

    lastBeepTime = millis();
  }
}

void stopMachineAudio() {
  if (signalBeep != null) signalBeep.amp(0);
  if (signalClick != null) signalClick.amp(0);
}

void updateMachineSelfRotation() {
  if (accumulationFull) return;
  if (active == null) return;
  if (active.cells().length == 0) return;
  if (!machineResponding) return;
  if (active.humanConfirmed) return;
  if (active.voiceSolidity >= LANDED_CONFIRMED_SOLIDITY) return;

  if (millis() - lastMachineRotateTime < machineRotateCooldown) return;

  float fillPressure = sedimentFillRatio();

  float uncertainty =
    (1.0 - active.confidence) * 0.35 +
    active.misread * 0.30 +
    machineNoiseLevel * 0.20 +
    fillPressure * 0.15;

  uncertainty = constrain(uncertainty, 0, 1);
  if (active.humanConfirmed) uncertainty *= 0.45;
  if (active.machineVerified) uncertainty *= 0.25;
  machineRotatePressure = uncertainty;

  float rotateChance = 0.002;

  if (fillPressure > 0.35) {
    rotateChance += map(fillPressure, 0.35, 0.85, 0.004, 0.030);
  }

  rotateChance += uncertainty * 0.025;

  if (systemAge01 > 0.65) {
    rotateChance *= 1.45;
  }

  if (random(1) < rotateChance) {
    int oldRotation = active.rotation;

    rotateActive();

    if (active.rotation != oldRotation) {
      active.misread = min(1.0, active.misread + 0.08);
      addTraceFromActive(0.65);
      addConflictFromActive(0.38);
      lineFieldDirty = true;
      lastMachineRotateTime = millis();
    }
  }
}

// ------------------------------------------------------------
// ULTRASONIC CONTROL

void updateUltrasonicControl() {
  if (!arduinoActive) {
    ultrasonicDataPending = false;
    leftValid = false;
    rightValid = false;
    ultrasonicTriggerArmed = true;
    pendingMoveDirection = 0;
    pendingMoveSteps = 0;
    ultrasonicDirection = "NONE";
    return;
  }

  if (!ultrasonicDataPending) return;
  ultrasonicDataPending = false;

  leftValid = usL >= ULTRASONIC_MIN_CM && usL <= ULTRASONIC_MAX_CM;
  rightValid = usR >= ULTRASONIC_MIN_CM && usR <= ULTRASONIC_MAX_CM;

  if (leftValid) {
    if (smoothUsL < 0) smoothUsL = usL;
    else smoothUsL = lerp(smoothUsL, usL, 0.15);
  } else {
    smoothUsL = -1;
  }

  if (rightValid) {
    if (smoothUsR < 0) smoothUsR = usR;
    else smoothUsR = lerp(smoothUsR, usR, 0.15);
  } else {
    smoothUsR = -1;
  }

  if (leftValid && !rightValid) {
    ultrasonicDirection = "LEFT";
  } else if (rightValid && !leftValid) {
    ultrasonicDirection = "RIGHT";
  } else if (leftValid && rightValid) {
    float difference = smoothUsL - smoothUsR;

    if (difference < -ULTRASONIC_DIRECTION_GAP_CM) {
      ultrasonicDirection = "LEFT";
    } else if (difference > ULTRASONIC_DIRECTION_GAP_CM) {
      ultrasonicDirection = "RIGHT";
    } else {
      ultrasonicDirection = "NONE";
    }
  } else {
    ultrasonicDirection = "NONE";
  }

  if (ultrasonicDirection.equals("NONE")) {
    ultrasonicTriggerArmed = true;
  } else if (ultrasonicTriggerArmed && pendingMoveSteps == 0) {
    float controllingDistance = ultrasonicDirection.equals("LEFT") ? usL : usR;

    pendingMoveDirection = ultrasonicDirection.equals("LEFT") ? -1 : 1;
    pendingMoveSteps = distanceToMoveSteps(controllingDistance);
    ultrasonicTriggerArmed = false;
  }
}

void applyUltrasonicToActiveBlock() {
  if (!arduinoActive || accumulationFull || pendingMoveSteps <= 0) return;
  if (millis() - lastMoveTime < moveCooldown) return;

  boolean moved = moveActive(pendingMoveDirection);
  lastMoveTime = millis();

  if (moved) {
    pendingMoveSteps--;
  } else {
    pendingMoveSteps = 0;
    pendingMoveDirection = 0;
  }

  if (pendingMoveSteps == 0) pendingMoveDirection = 0;
}

int distanceToMoveSteps(float distanceCm) {
  if (distanceCm < 5 || distanceCm > 30) return 0;
  if (distanceCm <= 10) return 3;
  if (distanceCm <= 18) return 2;
  return 1;
}

// ------------------------------------------------------------
// DEBUG

void drawSensorDebug() {
  drawHUD();
}
