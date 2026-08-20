// Data Sedimentation - split tab
// This file is part of WSAA2_06.pde and is compiled by Processing with the main sketch.

// Sensor and audio state.
Serial arduinoPort;
final int SERIAL_BAUD_RATE = 115200;

// Keyboard-only test mode. Set this to false when testing with Arduino again,
// or press T while the sketch is running.
boolean keyboardTestMode = false;
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

// Exhibition participation state. Arduino activity only means that the sensor
// system is running; it does not by itself prove that a visitor is present.
boolean unattendedMode = false;
boolean sensorSystemReadyWaiting = false;
boolean sensorSystemRestartDetected = false;
boolean sensorSystemHasBeenActive = false;
int lastClearParticipantTime = 0;
int unattendedTimeoutMs = 12000;
final int UNATTENDED_TIMEOUT_MIN_MS = 10000;
final int UNATTENDED_TIMEOUT_MAX_MS = 15000;
final int PARTICIPANT_SENSOR_HOLD_MS = 1300;
final float RADAR_PARTICIPANT_MIN_ENERGY = 48;
final float RADAR_PARTICIPANT_MAX_DISTANCE_CM = 600;
int lastAmbientUltrasonicMotionTime = -99999;
float previousAmbientUsL = -1;
float previousAmbientUsR = -1;

int radarTargetState = 0;
float radarMovingEnergy = 0;
float radarStationaryEnergy = 0;
float radarMovingDistance = 0;
float radarStationaryDistance = 0;
int lastRadarPacketTime = -99999;

final float ULTRASONIC_MIN_CM = 5;
final float ULTRASONIC_MAX_CM = 30;
final float ULTRASONIC_DIRECTION_GAP_CM = 5;
final int ULTRASONIC_PACKET_TIMEOUT_MS = 760;

int lastMoveTime = 0;
final int moveCooldown = 190;
final int ultrasonicRepeatInterval = 260;
int lastUltrasonicStepRequestTime = -99999;
int lastUltrasonicPacketTime = -99999;
int lastUltrasonicControlTime = -99999;
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
float amplifiedVoiceDelta = 0;
float autoVoiceGain = 1.0;
float autoVoicePeak = 1.0;
int voiceCalibrationStartTime = -99999;
final int VOICE_CALIBRATION_MS = 2600;

boolean speaking = false;
boolean externalVoiceCandidate = false;
boolean voiceBaselineReady = false;

int voiceThreshold = 17;

int strongVoiceFramesNeeded = 2;
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

float machineNoiseThreshold = 0.45;

// Machine audio synthesis.
boolean machineAudioEnabled = true;

int lastBeepTime = 0;
int beepInterval = 260;

// ------------------------------------------------------------
// SERIAL INPUT

void initArduinoSerial() {
  if (arduinoPort != null) {
    println("Arduino serial port is already connected.");
    return;
  }

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

void disconnectArduinoSerial() {
  if (arduinoPort != null) {
    try {
      arduinoPort.stop();
    }
    catch (Exception e) {
      println("Arduino serial close warning: " + e.getMessage());
    }
    arduinoPort = null;
  }

  arduinoActive = false;
  sensorSystemReadyWaiting = false;
  sensorSystemRestartDetected = false;
  ultrasonicDataPending = false;
  usL = -1;
  usR = -1;
  smoothUsL = -1;
  smoothUsR = -1;
  leftValid = false;
  rightValid = false;
  previousAmbientUsL = -1;
  previousAmbientUsR = -1;
  lastUltrasonicPacketTime = -99999;
  lastAmbientUltrasonicMotionTime = -99999;
  clearUltrasonicControlState();

  radarTargetState = 0;
  radarMovingEnergy = 0;
  radarStationaryEnergy = 0;
  radarMovingDistance = 0;
  radarStationaryDistance = 0;
  lastRadarPacketTime = -99999;

  stopMachineAudio();
  println("Arduino serial: DISCONNECTED");
}

void toggleArduinoSerialConnection() {
  if (arduinoPort == null) {
    println("Arduino serial: CONNECTING...");
    initArduinoSerial();
  } else {
    disconnectArduinoSerial();
  }
}

void readSerialData() {
  if (arduinoPort == null) return;

  int linesRead = 0;
  while (arduinoPort.available() > 0 && linesRead < 24) {
    String line = arduinoPort.readStringUntil('\n');
    if (line == null) break;
    parseSerialLine(trim(line));
    linesRead++;
  }
}

void sendArduinoCommand(String command) {
  if (arduinoPort == null) {
    println("Arduino command skipped, no serial port: " + command);
    return;
  }

  arduinoPort.write(command + "\n");
  println("Arduino command sent: " + command);
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
    lastUltrasonicStepRequestTime = -99999;
    lastUltrasonicPacketTime = -99999;
    lastUltrasonicControlTime = -99999;
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

  if (upperLine.indexOf("SENSOR SYSTEM READY") >= 0 ||
      upperLine.indexOf("WAITING FOR HEART TOUCH TO START") >= 0) {
    sensorSystemRestartDetected = sensorSystemHasBeenActive;
    sensorSystemReadyWaiting = true;
    arduinoActive = false;

  }

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
    lastUltrasonicStepRequestTime = -99999;
    lastUltrasonicPacketTime = -99999;
    lastUltrasonicControlTime = -99999;
    ultrasonicDirection = "NONE";
    lastPresenceTime = -99999;
    lastMotionTime = -99999;
    lastSoundTime = -99999;
    lastDistanceTime = -99999;
    previousMotionUsL = -1;
    previousMotionUsR = -1;
    lastUltrasonicPacketTime = -99999;
    lastUltrasonicControlTime = -99999;
  } else if (upperLine.indexOf("SYSTEM START") >= 0 ||
             upperLine.indexOf("ACTIVE DATA") >= 0) {
    arduinoActive = true;
    sensorSystemHasBeenActive = true;
    sensorSystemReadyWaiting = false;
    sensorSystemRestartDetected = false;
    lastPresenceTime = millis();
  }

  String[] radarValues = match(
    upperLine,
    "LD_STATE\\s*:\\s*(\\d+)\\s+LD_MOVE\\s*:\\s*(\\d+)\\s+LD_STILL\\s*:\\s*(\\d+)\\s+LD_MDIST\\s*:\\s*(\\d+)\\s+LD_SDIST\\s*:\\s*(\\d+)"
  );
  if (radarValues != null) {
    radarTargetState = int(radarValues[1]);
    radarMovingEnergy = float(radarValues[2]);
    radarStationaryEnergy = float(radarValues[3]);
    radarMovingDistance = float(radarValues[4]);
    radarStationaryDistance = float(radarValues[5]);
    lastRadarPacketTime = millis();
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

  if (values == null) {
    String[] leftValue = match(line, "US_L\\s*:?\\s*(-?\\d+(?:\\.\\d+)?)");
    String[] rightValue = match(line, "US_R\\s*:?\\s*(-?\\d+(?:\\.\\d+)?)");
    if (leftValue != null || rightValue != null) {
      values = new String[] {
        "",
        leftValue != null ? leftValue[1] : str(usL),
        rightValue != null ? rightValue[1] : str(usR)
      };
    }
  }

  if (values != null) {
    usL = float(values[1]);
    usR = float(values[2]);
    ultrasonicDataPending = true;
    arduinoActive = true;
    lastPresenceTime = millis();
    lastDistanceTime = millis();
    lastUltrasonicPacketTime = millis();
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
    amplifiedVoiceDelta = 0;
    autoVoiceGain = lerp(autoVoiceGain, 1.0, 0.08);
    autoVoicePeak = lerp(autoVoicePeak, 1.0, 0.08);
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
  updateAutoVoiceGain(voiceDelta);
  amplifiedVoiceDelta = voiceDelta * autoVoiceGain;

  float targetSoundLevel = constrain(map(amplifiedVoiceDelta, voiceCandidateThreshold, 18, 0, 1), 0, 1);
  if (targetSoundLevel > soundLevel) {
    soundLevel = lerp(soundLevel, targetSoundLevel, 0.38);
  } else {
    soundLevel = lerp(soundLevel, targetSoundLevel, 0.10);
  }

  voiceEnergy = soundLevel;
  voiceEnvelope = soundLevel;

  boolean voiceCandidate = amplifiedVoiceDelta >= voiceCandidateThreshold;
  boolean strongCandidate = amplifiedVoiceDelta >= strongVoiceThreshold && soundLevel > 0.20;
  boolean releaseCandidate = amplifiedVoiceDelta < voiceCandidateThreshold * 0.55 || soundLevel < 0.04;

  if (voiceCandidate) {
    if (sustainedVoiceCandidateStartTime < 0) sustainedVoiceCandidateStartTime = now;

    int sustainedVoiceMs = now - sustainedVoiceCandidateStartTime;

    if (sustainedVoiceMs > VOICE_BASELINE_LEARN_MS) {
      float learnRate = strongCandidate ? 0.045 : 0.025;
      if (sustainedVoiceMs > VOICE_BASELINE_FORCE_RELEASE_MS) learnRate = 0.12;

      voiceBaseline = lerp(voiceBaseline, soundRaw, learnRate);
      voiceDelta = max(0, soundRaw - voiceBaseline);
      updateAutoVoiceGain(voiceDelta);
      amplifiedVoiceDelta = voiceDelta * autoVoiceGain;
      targetSoundLevel = constrain(map(amplifiedVoiceDelta, voiceCandidateThreshold, 18, 0, 1), 0, 1);
      soundLevel = lerp(soundLevel, targetSoundLevel, 0.28);
      voiceEnergy = soundLevel;
      voiceEnvelope = soundLevel;
      voiceCandidate = amplifiedVoiceDelta >= voiceCandidateThreshold;
      strongCandidate = amplifiedVoiceDelta >= strongVoiceThreshold && soundLevel > 0.20;
      releaseCandidate = amplifiedVoiceDelta < voiceCandidateThreshold * 0.55 || soundLevel < 0.04;

      if (sustainedVoiceMs > VOICE_BASELINE_FORCE_RELEASE_MS && amplifiedVoiceDelta < strongVoiceThreshold) {
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
    updateAutoVoiceGain(voiceDelta);
    amplifiedVoiceDelta = voiceDelta * autoVoiceGain;
    if (amplifiedVoiceDelta < voiceCandidateThreshold * 0.55) {
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
    if (amplifiedVoiceDelta < voiceCandidateThreshold * 0.45 ||
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

  if (voiceCandidate) {
    voicePeakHold = max(voicePeakHold, soundLevel);
  } else {
    voicePeakHold = max(0, voicePeakHold - 0.025);
  }

  directMappedSolidity = solidityFromKYRaw(amplifiedVoiceDelta);

  updateActiveVoiceMemory(voiceCandidate, strongCandidate, now);

  if (active != null) {
    blockSolidity = active.voiceSolidity;
  } else {
    blockSolidity = 0.12;
  }

  voiceHold = speaking ? soundLevel : 0;
  voiceConfirm = voiceHold;
}

void updateAutoVoiceGain(float rawDelta) {
  if (!arduinoActive) {
    autoVoiceGain = lerp(autoVoiceGain, 1.0, 0.06);
    autoVoicePeak = lerp(autoVoicePeak, 1.0, 0.06);
    return;
  }

  autoVoicePeak = max(rawDelta, autoVoicePeak * 0.985);
  float targetGain = constrain(12.0 / max(2.0, autoVoicePeak), 0.80, 5.50);
  if (rawDelta < 0.65) targetGain = min(targetGain, 2.30);
  autoVoiceGain = lerp(autoVoiceGain, targetGain, 0.045);
}

void updateActiveVoiceMemory(boolean voiceCandidate, boolean strongCandidate, int now) {
  if (active == null) return;

  // Ambient audio may shape an unattended inference, but it must never
  // promote an autonomous block into a human-confirmed/verified block.
  if (active.lowConfidenceInference) {
    active.humanConfirmed = false;
    active.machineVerified = false;
    active.lastHumanVoiceTime = -99999;
    active.voiceSolidity = min(active.voiceSolidity, 0.24);
    return;
  }

  if ((speaking && voiceCandidate) || strongCandidate) {
    float voiceStrength = constrain(soundLevel, 0, 1);
    float confirmedSolidity = map(voiceStrength, 0, 1, 0.28, 0.78);

    if (strongCandidate) {
      float strongAmount = constrain(map(amplifiedVoiceDelta, strongVoiceThreshold, 18, 0, 1), 0, 1);
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

  boolean activeHumanConfirmed = active != null &&
    !active.lowConfidenceInference && active.humanConfirmed;

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

    lastBeepTime = millis();
  }
}

void stopMachineAudio() {
  muteMachineSound();

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

  if (!ultrasonicDataPending) {
    if (millis() - lastUltrasonicPacketTime > ULTRASONIC_PACKET_TIMEOUT_MS) {
      clearUltrasonicControlState();
    }
    return;
  }
  ultrasonicDataPending = false;

  if (usL >= ULTRASONIC_MIN_CM && usL <= ULTRASONIC_MAX_CM) {
    if (previousAmbientUsL >= 0 && abs(usL - previousAmbientUsL) >= 2.4) {
      lastAmbientUltrasonicMotionTime = millis();
    }
    previousAmbientUsL = usL;
  }
  if (usR >= ULTRASONIC_MIN_CM && usR <= ULTRASONIC_MAX_CM) {
    if (previousAmbientUsR >= 0 && abs(usR - previousAmbientUsR) >= 2.4) {
      lastAmbientUltrasonicMotionTime = millis();
    }
    previousAmbientUsR = usR;
  }

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
    releaseUltrasonicMoveState();
  } else if (ultrasonicTriggerArmed && pendingMoveSteps == 0) {
    float controllingDistance = ultrasonicDirection.equals("LEFT") ? usL : usR;

    pendingMoveDirection = ultrasonicDirection.equals("LEFT") ? -1 : 1;
    pendingMoveSteps = distanceToMoveSteps(controllingDistance);
    ultrasonicTriggerArmed = false;
    lastUltrasonicStepRequestTime = millis();
    lastUltrasonicControlTime = millis();
  } else if (pendingMoveSteps == 0 && millis() - lastUltrasonicStepRequestTime >= ultrasonicRepeatInterval) {
    requestRepeatedUltrasonicMove();
  }
}

void clearUltrasonicControlState() {
  leftValid = false;
  rightValid = false;
  smoothUsL = -1;
  smoothUsR = -1;
  ultrasonicDirection = "NONE";
  releaseUltrasonicMoveState();
}

void releaseUltrasonicMoveState() {
  ultrasonicTriggerArmed = true;
  pendingMoveDirection = 0;
  pendingMoveSteps = 0;
}

void requestRepeatedUltrasonicMove() {
  if (!ultrasonicDirection.equals("LEFT") && !ultrasonicDirection.equals("RIGHT")) return;
  if (pendingMoveSteps > 0) return;
  if (millis() - lastUltrasonicStepRequestTime < ultrasonicRepeatInterval) return;

  float controllingDistance = ultrasonicDirection.equals("LEFT") ? smoothUsL : smoothUsR;
  if (controllingDistance < ULTRASONIC_MIN_CM || controllingDistance > ULTRASONIC_MAX_CM) return;

  pendingMoveDirection = ultrasonicDirection.equals("LEFT") ? -1 : 1;
  pendingMoveSteps = max(1, distanceToMoveSteps(controllingDistance));
  lastUltrasonicStepRequestTime = millis();
  lastUltrasonicControlTime = millis();
}

void applyUltrasonicToActiveBlock() {
  // In unattended mode the readings influence the next birth position. They
  // do not continuously steer a block as though a confirmed visitor existed.
  if (unattendedMode) return;
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

void markClearParticipantEvidence() {
  lastClearParticipantTime = millis();
  if (active != null && active.lowConfidenceInference) {
    active.lowConfidenceInference = false;
    active.confidence = max(active.confidence, 0.48);
    active.misread = min(active.misread, 0.16);
    currentMachineInterpretation = "PARTICIPANT CONFIRMED";
  }
  if (unattendedMode) {
    unattendedMode = false;
    unattendedTimeoutMs = int(random(UNATTENDED_TIMEOUT_MIN_MS, UNATTENDED_TIMEOUT_MAX_MS + 1));
    println("Exhibition mode: PARTICIPANT");
  }
}

boolean radarPacketFresh() {
  return millis() - lastRadarPacketTime <= 1200;
}

boolean ultrasonicParticipantDetected() {
  if (!arduinoActive) return false;
  if (millis() - lastUltrasonicPacketTime > PARTICIPANT_SENSOR_HOLD_MS) return false;

  boolean leftTarget = usL >= ULTRASONIC_MIN_CM && usL <= ULTRASONIC_MAX_CM;
  boolean rightTarget = usR >= ULTRASONIC_MIN_CM && usR <= ULTRASONIC_MAX_CM;
  return leftTarget || rightTarget;
}

boolean radarParticipantDetected() {
  if (!radarPacketFresh() || radarTargetState == 0) return false;

  boolean movingTarget = (radarTargetState == 1 || radarTargetState == 3) &&
    radarMovingEnergy >= RADAR_PARTICIPANT_MIN_ENERGY &&
    radarMovingDistance > 0 && radarMovingDistance <= RADAR_PARTICIPANT_MAX_DISTANCE_CM;
  boolean stationaryTarget = (radarTargetState == 2 || radarTargetState == 3) &&
    radarStationaryEnergy >= RADAR_PARTICIPANT_MIN_ENERGY &&
    radarStationaryDistance > 0 && radarStationaryDistance <= RADAR_PARTICIPANT_MAX_DISTANCE_CM;

  return movingTarget || stationaryTarget;
}

float weakRadarEvidence() {
  if (!radarPacketFresh() || radarTargetState == 0) return 0;
  return constrain(max(radarMovingEnergy, radarStationaryEnergy) / 100.0, 0, 1);
}

float unattendedAmbientAudioLevel() {
  // Audio can shape autonomous inference, but it never proves that a visitor is present.
  float voiceResidue = constrain(map(amplifiedVoiceDelta, 0.35, voiceCandidateThreshold, 0, 1), 0, 1);
  float roomNoise = constrain(map(machineRaw, 4, machineLow, 0, 1), 0, 1);
  return constrain(voiceResidue * 0.62 + roomNoise * 0.38, 0, 1);
}

void updateParticipationMode() {
  if (keyboardTestMode && testPresence) {
    markClearParticipantEvidence();
    return;
  }

  // Only close-range ultrasonic evidence confirms an active participant.
  // Radar remains available as weak environmental/inference input, but it
  // must not keep the installation out of unattended mode because of distant
  // visitors or persistent room reflections.
  if (ultrasonicParticipantDetected()) {
    markClearParticipantEvidence();
    return;
  }

  int now = millis();
  if (!unattendedMode && now - lastClearParticipantTime >= unattendedTimeoutMs) {
    unattendedMode = true;
    conflictParticles.clear();
    println("Exhibition mode: LOW-CONFIDENCE UNATTENDED INFERENCE");
  }
}
