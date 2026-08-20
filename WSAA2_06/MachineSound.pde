// Internal machine sound system.
// It reads existing sensor/game state and does not own gameplay, Arduino or visual logic.

SinOsc machineCarrier;
SinOsc machinePulse;
SinOsc machineBody;
SinOsc machineScanTone;
SinOsc machineErrorTone;
SinOsc machineVerifyTone;
SinOsc machineClickTone;
WhiteNoise machineNoise;
WhiteNoise machineScanNoise;
WhiteNoise machineErrorNoise;
WhiteNoise machineClickNoise;
SinOsc backroomsMainsHum;
SinOsc backroomsBallastHum;
SinOsc backroomsVentHum;
BrownNoise backroomsAirNoise;
LowPass backroomsAirLowPass;
SinOsc experimentalResonanceA;
SinOsc experimentalResonanceB;
SinOsc experimentalDataClock;
PinkNoise experimentalDustNoise;
BandPass experimentalDustBand;
Env machineScanEnv;
Env machineErrorEnv;
Env machineVerifyEnv;
Env machineClickEnv;

boolean machineSoundReady = false;
int lastMachineErrorBurstTime = -99999;
int lastMachineScanTickTime = -99999;
int lastMachineVerifyPingTime = -99999;
float lastMachineMisread = 0;
float machineCarrierFreqSmoothed = 120;
float machinePulseFreqSmoothed = 60;
float machinePanSmoothed = 0;
float machinePresenceSmoothed = 0;
float backroomsAmbientSmoothed = 0;
float experimentalResonanceMemory = 0.35;
float experimentalClockAmpSmoothed = 0;
// The synthesis was mixed for headphones at very conservative amplitudes.
// Raise every audible voice together while keeping ample digital headroom.
final float MACHINE_MASTER_GAIN = 3.0;
final int MUSICAL_BEAT_MS = 560;
final int MUSICAL_BEATS_PER_CHORD = 8;
final int[] MUSICAL_MINOR_PHRASE = {0, 3, 7, 10, 12, 10, 7, 3};

float semitoneRatio(float semitones) {
  return pow(2.0, semitones / 12.0);
}

float musicalChordRoot() {
  // D minor progression: i - VI - III - VII. It changes only once every
  // eight beats, giving the installation a slow classical harmonic breath.
  int chord = (millis() / (MUSICAL_BEAT_MS * MUSICAL_BEATS_PER_CHORD)) % 4;
  if (chord == 0) return 146.83; // D3
  if (chord == 1) return 116.54; // Bb2
  if (chord == 2) return 174.61; // F3
  return 130.81;                 // C3
}

float musicalArpeggioPitch(int step, float octaveMultiplier) {
  return musicalChordRoot() * semitoneRatio(MUSICAL_MINOR_PHRASE[step % MUSICAL_MINOR_PHRASE.length]) * octaveMultiplier;
}

void initMachineSound() {
  machineCarrier = new SinOsc(this);
  machinePulse = new SinOsc(this);
  machineBody = new SinOsc(this);
  machineScanTone = new SinOsc(this);
  machineNoise = new WhiteNoise(this);
  machineScanNoise = new WhiteNoise(this);
  machineErrorTone = new SinOsc(this);
  machineVerifyTone = new SinOsc(this);
  machineErrorNoise = new WhiteNoise(this);
  machineClickTone = new SinOsc(this);
  machineClickNoise = new WhiteNoise(this);
  backroomsMainsHum = new SinOsc(this);
  backroomsBallastHum = new SinOsc(this);
  backroomsVentHum = new SinOsc(this);
  backroomsAirNoise = new BrownNoise(this);
  backroomsAirLowPass = new LowPass(this);
  experimentalResonanceA = new SinOsc(this);
  experimentalResonanceB = new SinOsc(this);
  experimentalDataClock = new SinOsc(this);
  experimentalDustNoise = new PinkNoise(this);
  experimentalDustBand = new BandPass(this);
  machineScanEnv = new Env(this);
  machineErrorEnv = new Env(this);
  machineVerifyEnv = new Env(this);
  machineClickEnv = new Env(this);

  machineCarrier.play();
  machinePulse.play();
  machineBody.play();
  machineScanTone.play();
  machineNoise.play();
  machineScanNoise.play();
  machineErrorTone.play();
  machineVerifyTone.play();
  machineErrorNoise.play();
  machineClickTone.play();
  machineClickNoise.play();
  backroomsMainsHum.play();
  backroomsBallastHum.play();
  backroomsVentHum.play();
  backroomsAirNoise.play();
  backroomsAirLowPass.process(backroomsAirNoise);
  backroomsAirLowPass.freq(520);
  backroomsAirLowPass.res(0.18);
  experimentalResonanceA.play();
  experimentalResonanceB.play();
  experimentalDataClock.play();
  experimentalDustNoise.play();
  experimentalDustBand.process(experimentalDustNoise);
  experimentalDustBand.freq(1100);
  experimentalDustBand.res(0.72);

  machineCarrier.amp(0);
  machinePulse.amp(0);
  machineBody.amp(0);
  machineScanTone.amp(0);
  machineNoise.amp(0);
  machineScanNoise.amp(0);
  machineErrorTone.amp(0);
  machineVerifyTone.amp(0);
  machineErrorNoise.amp(0);
  machineClickTone.amp(0);
  machineClickNoise.amp(0);
  backroomsMainsHum.amp(0);
  backroomsBallastHum.amp(0);
  backroomsVentHum.amp(0);
  backroomsAirNoise.amp(0);
  experimentalResonanceA.amp(0);
  experimentalResonanceB.amp(0);
  experimentalDataClock.amp(0);
  experimentalDustNoise.amp(0);

  machineSoundReady = true;
}

void updateMachineSound(float dt) {
  if (!machineSoundReady) return;

  if (!machineAudioEnabled || !arduinoActive) {
    muteMachineSound();
    return;
  }

  float voiceAmount = constrain(max(soundLevel, voiceEnvelope * 0.85), 0, 1);
  float confidence = active == null ? input.confidence() : active.confidence;
  float misread = active == null ? input.conflict : active.misread;
  float validation = constrain(machineValidation, 0, 1);
  float machineResponse = constrain(machineNoiseLevel, 0, 1);

  float distanceL = smoothUsL >= 0 ? smoothUsL : usL;
  float distanceR = smoothUsR >= 0 ? smoothUsR : usR;
  boolean validL = distanceL >= ULTRASONIC_MIN_CM && distanceL <= ULTRASONIC_MAX_CM;
  boolean validR = distanceR >= ULTRASONIC_MIN_CM && distanceR <= ULTRASONIC_MAX_CM;

  float distance = displayDistanceCm();
  if (!validL && validR) distance = distanceR;
  if (validL && !validR) distance = distanceL;

  float distance01 = constrain(map(distance, ULTRASONIC_MIN_CM, ULTRASONIC_MAX_CM, 1, 0), 0, 1);

  float panValue = 0;
  if (validL && validR) {
    panValue = constrain((distanceR - distanceL) / max(1, ULTRASONIC_DIRECTION_GAP_CM * 2.0), -1, 1);
  } else if (validL) {
    panValue = -0.72;
  } else if (validR) {
    panValue = 0.72;
  }

  float archivePresence = qrArchiveRecentlyGenerated() ? 0.34 : 0;
  float targetPresence = constrain(0.035 + voiceAmount * 0.55 + machineResponse * 0.30 + validation * 0.20 + archivePresence, 0, 1);
  machinePresenceSmoothed = lerp(machinePresenceSmoothed, targetPresence, 0.08);

  float stability = constrain(confidence, 0, 1);
  float errorAmount = constrain(misread, 0, 1);
  float root = musicalChordRoot();
  float carrierOctave = distance01 > 0.68 ? 2.0 : 1.0;
  float targetCarrierFreq = root * carrierOctave;
  float targetPulseFreq = root * 1.4983; // consonant perfect fifth

  machineCarrierFreqSmoothed = lerp(machineCarrierFreqSmoothed, targetCarrierFreq, 0.035);
  machinePulseFreqSmoothed = lerp(machinePulseFreqSmoothed, targetPulseFreq, 0.030);
  machinePanSmoothed = lerp(machinePanSmoothed, panValue, 0.12);

  float sineAmp = machinePresenceSmoothed * map(stability, 0, 1, 0.006, 0.022) * MACHINE_MASTER_GAIN;
  float pulseAmp = machinePresenceSmoothed * map(machineResponse, 0, 1, 0.0005, 0.0024) * MACHINE_MASTER_GAIN;
  float bodyAmp = machinePresenceSmoothed * map(validation, 0, 1, 0.0005, 0.0022) * MACHINE_MASTER_GAIN;
  // Continuous broadband noise reads as wind on headphones, so the ambient
  // bed is now built from tones and discrete pulses only.
  float noiseAmp = 0;

  machineCarrier.freq(max(34, machineCarrierFreqSmoothed));
  machinePulse.freq(max(28, machinePulseFreqSmoothed));
  machineBody.freq(root * 0.5);
  machineCarrier.pan(machinePanSmoothed);
  machinePulse.pan(machinePanSmoothed * 0.7);
  machineBody.pan(machinePanSmoothed * 0.25);
  machineNoise.pan(-machinePanSmoothed * 0.55);

  machineCarrier.amp(sineAmp);
  machinePulse.amp(pulseAmp);
  machineBody.amp(bodyAmp);
  machineNoise.amp(noiseAmp);

  updateBackroomsAmbience(errorAmount, machineResponse, archivePresence);
  updateExperimentalSound(confidence, errorAmount, machineResponse, voiceAmount, distance01);

  maybeTriggerMachineScanTick(distance01, confidence, misread, machinePanSmoothed);
  maybeTriggerMachineVerifyPing(validation, confidence, machinePanSmoothed);
  maybeTriggerMachineErrorBurst(misread, confidence, machinePanSmoothed);
  lastMachineMisread = misread;
}

void updateExperimentalSound(
  float confidence,
  float errorAmount,
  float machineResponse,
  float voiceAmount,
  float distance01
) {
  // Sensor activity changes orchestration and rhythm, while pitch stays inside
  // one shared harmonic score. This keeps the electronic detail intelligible.
  float evidence = constrain(
    confidence * 0.34 + distance01 * 0.24 + voiceAmount * 0.22 + machineResponse * 0.20,
    0,
    1
  );
  experimentalResonanceMemory = lerp(experimentalResonanceMemory, evidence, 0.0025);

  float root = musicalChordRoot();
  float resonanceBase = root * 2.0;
  float upperInterval = ((millis() / (MUSICAL_BEAT_MS * MUSICAL_BEATS_PER_CHORD)) % 2 == 0)
    ? semitoneRatio(3)  // minor third
    : semitoneRatio(7); // perfect fifth
  float resonanceAmp = (0.0009 + experimentalResonanceMemory * 0.0018) * MACHINE_MASTER_GAIN;

  experimentalResonanceA.freq(resonanceBase);
  experimentalResonanceB.freq(resonanceBase * upperInterval);
  experimentalResonanceA.pan(-0.24);
  experimentalResonanceB.pan(0.24);
  experimentalResonanceA.amp(resonanceAmp);
  experimentalResonanceB.amp(resonanceAmp * 0.68);

  // Eight-step minor arpeggio. PMSD bits decide which notes are articulated,
  // but a downbeat remains so the listener always hears a coherent phrase.
  int clockInterval = int(map(confidence, 0, 1, 680, 480));
  int clockStep = (millis() / clockInterval) % 8;
  int phaseInStep = millis() % clockInterval;
  int bitIndex = clockStep % 4;
  int dataBit = (currentPMSD >> bitIndex) & 1;
  boolean phraseAnchor = clockStep == 0 || clockStep == 4;
  boolean shortGate = phaseInStep < int(clockInterval * 0.16);
  float targetClockAmp = shortGate && (dataBit == 1 || phraseAnchor)
    ? (0.0010 + machineResponse * 0.0014 + voiceAmount * 0.0008) * MACHINE_MASTER_GAIN
    : 0;
  experimentalClockAmpSmoothed = lerp(experimentalClockAmpSmoothed, targetClockAmp, targetClockAmp > 0 ? 0.28 : 0.18);

  float clockPitch = musicalArpeggioPitch(clockStep, distance01 > 0.62 ? 4.0 : 2.0);
  experimentalDataClock.freq(clockPitch);
  experimentalDataClock.pan(map(clockStep, 0, 7, -0.42, 0.42));
  experimentalDataClock.amp(experimentalClockAmpSmoothed);

  experimentalDustBand.freq(root * 4.0);
  experimentalDustBand.res(0.72);
  experimentalDustNoise.pan(0);
  experimentalDustNoise.amp(0);
}

void updateBackroomsAmbience(float errorAmount, float machineResponse, float archivePresence) {
  // A restrained fluorescent/ventilation bed: 50 Hz mains, its imperfect
  // ballast harmonic, low HVAC resonance and filtered brown room noise.
  float targetAmbient = 0.72 + machineResponse * 0.10 + archivePresence * 0.12;
  backroomsAmbientSmoothed = lerp(backroomsAmbientSmoothed, targetAmbient, 0.018);

  float slowDrift = noise(frameCount * 0.0027 + 41.0);
  float ballastDrift = noise(frameCount * 0.0071 + 83.0);
  float flickerNoise = noise(frameCount * 0.035 + 126.0);
  float flicker = map(flickerNoise, 0, 1, 0.76, 1.06);
  if (flickerNoise < 0.22) flicker *= map(flickerNoise, 0.22, 0, 0.58, 0.12);

  backroomsMainsHum.freq(49.7 + (slowDrift - 0.5) * 0.55);
  backroomsBallastHum.freq(100.3 + (ballastDrift - 0.5) * 2.8 + errorAmount * 1.6);
  backroomsVentHum.freq(37.2 + (slowDrift - 0.5) * 2.4 + machineResponse * 3.0);
  backroomsAirLowPass.freq(430 + ballastDrift * 230 + machineResponse * 110);

  backroomsMainsHum.pan(-0.18);
  backroomsBallastHum.pan(0.28);
  backroomsVentHum.pan(-0.05);
  backroomsAirNoise.pan(0.08);

  // Continuous electrical/vent tones are muted because stacked sub-bass and
  // mains hum become physically tiring during a long installation.
  backroomsMainsHum.amp(0);
  backroomsBallastHum.amp(0);
  backroomsVentHum.amp(0);
  backroomsAirNoise.amp(0);
}

void maybeTriggerMachineScanTick(float distance01, float confidence, float misread, float panValue) {
  float drive = max(machinePresenceSmoothed, soundLevel);
  if (drive < 0.16) return;

  int interval = int(map(distance01, 0, 1, 1250, 720));
  interval = int(interval * map(constrain(confidence, 0, 1), 0, 1, 1.10, 0.92));
  if (millis() - lastMachineScanTickTime < interval) return;

  int phraseStep = (millis() / MUSICAL_BEAT_MS) % 8;
  float tickAmp = constrain(map(drive, 0.16, 1.0, 0.003, 0.011) * MACHINE_MASTER_GAIN, 0, 0.036);
  float freq = musicalArpeggioPitch(phraseStep, 2.0);
  machineScanTone.freq(max(140, freq));
  machineScanTone.pan(panValue * 0.55);
  machineScanNoise.pan(-panValue * 0.45);
  machineScanTone.amp(tickAmp);
  machineScanNoise.amp(0);
  machineScanEnv.play(machineScanTone, 0.004, 0.030, tickAmp * 0.34, 0.110);
  lastMachineScanTickTime = millis();
}

void maybeTriggerMachineVerifyPing(float validation, float confidence, float panValue) {
  if (validation < 0.46 || confidence < 0.42) return;
  int interval = int(map(validation, 0.46, 1.0, 2100, 1200));
  if (millis() - lastMachineVerifyPingTime < interval) return;

  float pingAmp = map(validation, 0.46, 1.0, 0.004, 0.012) * MACHINE_MASTER_GAIN;
  machineVerifyTone.freq(musicalChordRoot() * semitoneRatio(7) * 4.0);
  machineVerifyTone.pan(panValue * 0.38);
  machineVerifyTone.amp(pingAmp);
  machineVerifyEnv.play(machineVerifyTone, 0.006, 0.050, pingAmp * 0.30, 0.180);
  lastMachineVerifyPingTime = millis();
}

void maybeTriggerMachineErrorBurst(float misread, float confidence, float panValue) {
  if (millis() - lastMachineErrorBurstTime < 1400) return;

  boolean risingMisread = misread > 0.42 && misread - lastMachineMisread > 0.055;
  if (!risingMisread) return;

  float burstAmp = map(constrain(misread, 0.42, 1.0), 0.42, 1.0, 0.004, 0.014) * MACHINE_MASTER_GAIN;
  machineErrorTone.freq(musicalChordRoot() * semitoneRatio(6) * 4.0);
  machineErrorTone.pan(panValue * 0.50);
  machineErrorNoise.pan(-panValue);
  machineErrorTone.amp(burstAmp);
  machineErrorNoise.amp(0);
  machineErrorEnv.play(machineErrorTone, 0.003, 0.022, burstAmp * 0.24, 0.090);
  lastMachineErrorBurstTime = millis();
}

void triggerMachineDropClick() {
  if (!machineSoundReady || !machineAudioEnabled) return;

  float confidence = active == null ? input.confidence() : active.confidence;
  int phraseStep = (millis() / MUSICAL_BEAT_MS) % 8;
  float clickAmp = map(constrain(confidence, 0, 1), 0, 1, 0.006, 0.018) * MACHINE_MASTER_GAIN;
  machineClickTone.freq(musicalArpeggioPitch(phraseStep, 0.5));
  machineClickTone.amp(clickAmp);
  machineClickNoise.amp(0);
  machineClickEnv.play(machineClickTone, 0.003, 0.028, clickAmp * 0.36, 0.120);
}

void muteMachineSound() {
  if (!machineSoundReady) return;
  machinePresenceSmoothed = lerp(machinePresenceSmoothed, 0, 0.18);
  backroomsAmbientSmoothed = lerp(backroomsAmbientSmoothed, 0, 0.12);
  machineCarrier.amp(0);
  machinePulse.amp(0);
  machineBody.amp(0);
  machineScanTone.amp(0);
  machineNoise.amp(0);
  machineScanNoise.amp(0);
  machineErrorTone.amp(0);
  machineErrorNoise.amp(0);
  machineVerifyTone.amp(0);
  machineClickTone.amp(0);
  machineClickNoise.amp(0);
  backroomsMainsHum.amp(0);
  backroomsBallastHum.amp(0);
  backroomsVentHum.amp(0);
  backroomsAirNoise.amp(0);
  experimentalResonanceA.amp(0);
  experimentalResonanceB.amp(0);
  experimentalDataClock.amp(0);
  experimentalDustNoise.amp(0);
}
