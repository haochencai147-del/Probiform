// Data Sedimentation - split tab
// This file is part of WSAA2_06.pde and is compiled by Processing with the main sketch.

// Sediment system state.
int lastGravityCollapseTime = 0;
final int gravityCollapseInterval = 90;
int lastGravityGapCheckTime = 0;
boolean gravityDirty = false;
int nextSedimentPieceId = 1;
int corruptedCellsThisFrame = 0;

// ------------------------------------------------------------
// SEDIMENT

class DataCell {
  boolean occupied = false;
  int pieceId = 0;
  float confidence = 0;
  float solidity = 0.12;
  float age = 0;
  float distortion = 0;
  int visualCode = 0;

  float corruption = 0;
  boolean rejected = false;
  boolean machineVerified = false;

  void store(float confidence, float distortion, float solidity, int pieceId, boolean machineVerified, int visualCode) {
    occupied = true;
    this.pieceId = pieceId;
    this.confidence = confidence;
    this.distortion = distortion;
    this.solidity = constrain(solidity, 0, 1);
    this.machineVerified = machineVerified;
    this.visualCode = visualCode;
    corruption = 0;
    rejected = false;
    age = 0;
  }

  void update(float dt) {
    if (!occupied) return;
    age += dt;

    if (age < 1200) return;
    if (!isSedimentPieceRepresentative(pieceId, this)) return;
    if (isConfirmedSedimentPiece(pieceId)) {
      resetSedimentPieceCorruption(pieceId);
      return;
    }

    if (solidity < LANDED_CONFIRMED_SOLIDITY && age > 2200) {
      float lowSolidityPressure = constrain(
        map(solidity, 0.10, LANDED_CONFIRMED_SOLIDITY, 1.0, 0.0),
        0,
        1
      );
      float agePressure = constrain(map(age, 2200, 12000, 0.20, 1.0), 0.20, 1.0);
      float decayRate = solidity < 0.35 ? 0.00020 : 0.000075;

      if (machineVerified) decayRate *= 0.30;
      if (confidence > 0.55) decayRate *= 0.55;

      increaseSedimentPieceCorruption(
        pieceId,
        dt * decayRate * max(0.18, lowSolidityPressure) * agePressure
      );
    }

    float greyInstability = 1.0 - solidity;
    float instability =
      greyInstability * 0.50 +
      (1.0 - confidence) * 0.25 +
      distortion * 0.15 +
      corruption * 0.10;
    instability = constrain(instability, 0, 1);

    if (solidity > 0.72) {
      instability *= 0.35;
    } else if (solidity > 0.55 && confidence > 0.55) {
      instability *= 0.60;
    }

    float phasePressure = 0.18;
    if (systemAge01 < 0.20) {
      phasePressure = 0.12;
    } else if (systemAge01 < 0.65) {
      phasePressure = map(systemAge01, 0.20, 0.65, 0.38, 1.05);
    } else {
      phasePressure = map(systemAge01, 0.65, 1.00, 1.25, 2.05);
    }

    float fillPressure = sedimentFillRatio();
    if (fillPressure > 0.55) {
      phasePressure *= map(fillPressure, 0.55, 0.85, 1.2, 2.2);
    }

    float noisePressure = 0;
    if (machineNoiseLevel > machineNoiseThreshold) {
      noisePressure = map(machineNoiseLevel, machineNoiseThreshold, 1, 0, 1);
    }

    float latePressure = 0;
    if (systemAge01 > 0.55) {
      latePressure = map(systemAge01, 0.55, 1.0, 0, 1);
    }

    float decayChance =
      0.00075 +
      noisePressure * instability * phasePressure * 0.040 +
      latePressure * instability * phasePressure * 0.018;

    if (solidity >= LANDED_CONFIRMED_SOLIDITY) {
      decayChance *= 0.20;
    }
    if (machineVerified) {
      decayChance *= 0.15;
    }

    if (random(1) < decayChance) {
      float activePressure = max(noisePressure, latePressure * 0.70);
      float amount = random(0.035, 0.095) * max(0.30, activePressure) * phasePressure;
      increaseSedimentPieceCorruption(pieceId, amount);
      corruptedCellsThisFrame++;
    }

    if (systemAge01 < 0.65) {
      reduceSedimentPieceCorruption(pieceId, dt * 0.00001);
    }

    if (pieceCorruption(pieceId) >= 0.98) {
      rejectSedimentPiece(pieceId);
    }
  }
}

void updateSediment(float dt) {
  corruptedCellsThisFrame = 0;

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      boolean wasOccupied = sediment[x][y].occupied;
      sediment[x][y].update(dt);

      if (wasOccupied && !sediment[x][y].occupied) {
        trace[x][y] = 0;
        traceBit[x][y] = 0;
        blockTrail[x][y] = 0;
        clearCell(sediment[x][y]);
        gravityDirty = true;
        lineFieldDirty = true;
      }
    }
  }

  if (!gravityDirty && millis() - lastGravityGapCheckTime > 320) {
    lastGravityGapCheckTime = millis();
    gravityDirty = sedimentHasGravityGap();
  }
}

float sedimentFillRatio() {
  int total = COLS * ROWS;
  int occupiedCount = 0;

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      if (sediment[x][y].occupied) occupiedCount++;
    }
  }

  return occupiedCount / float(total);
}

void applySedimentGravity() {
  if (!gravityDirty) return;
  if (millis() - lastGravityCollapseTime < gravityCollapseInterval) return;

  boolean movedAny = false;
  boolean[] checkedPiece = new boolean[max(nextSedimentPieceId + 1, 2)];

  for (int x = 0; x < COLS; x++) {
    for (int y = ROWS - 2; y >= 0; y--) {
      int pieceId = sediment[x][y].pieceId;

      if (sediment[x][y].occupied &&
          pieceId > 0 &&
          pieceId < checkedPiece.length &&
          !checkedPiece[pieceId]) {
        checkedPiece[pieceId] = true;

        if (canMoveSedimentPieceDown(pieceId)) {
          moveSedimentPieceDown(pieceId);
          movedAny = true;
        }
      }
    }
  }

  lastGravityCollapseTime = millis();
  lineFieldDirty = true;

  if (!movedAny) {
    gravityDirty = false;
  }
}

boolean canMoveSedimentPieceDown(int pieceId) {
  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      if (!sediment[x][y].occupied || sediment[x][y].pieceId != pieceId) continue;

      if (y + 1 >= ROWS) return false;
      if (sediment[x][y + 1].occupied && sediment[x][y + 1].pieceId != pieceId) {
        return false;
      }
    }
  }

  return true;
}

void moveSedimentPieceDown(int pieceId) {
  for (int y = ROWS - 2; y >= 0; y--) {
    for (int x = 0; x < COLS; x++) {
      if (sediment[x][y].occupied && sediment[x][y].pieceId == pieceId) {
        copyCell(sediment[x][y], sediment[x][y + 1]);
        clearCell(sediment[x][y]);

        trace[x][y + 1] = max(trace[x][y + 1], trace[x][y]);
        traceBit[x][y + 1] = traceBit[x][y];
        trace[x][y] = 0;
        traceBit[x][y] = 0;
        blockTrail[x][y] = 0;
      }
    }
  }
}

void rejectSedimentPiece(int pieceId) {
  if (pieceId <= 0) return;

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      if (sediment[x][y].occupied && sediment[x][y].pieceId == pieceId) {
        clearCell(sediment[x][y]);
        trace[x][y] = 0;
        traceBit[x][y] = 0;
        blockTrail[x][y] = 0;
      }
    }
  }

  gravityDirty = true;
  lineFieldDirty = true;
}

boolean isSedimentPieceRepresentative(int pieceId, DataCell cell) {
  if (pieceId <= 0) return false;

  for (int y = 0; y < ROWS; y++) {
    for (int x = 0; x < COLS; x++) {
      if (sediment[x][y].occupied && sediment[x][y].pieceId == pieceId) {
        return sediment[x][y] == cell;
      }
    }
  }

  return false;
}

boolean isConfirmedSedimentPiece(int pieceId) {
  if (pieceId <= 0) return false;

  float strongestSolidity = 0;
  float strongestConfidence = 0;

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      if (!sediment[x][y].occupied || sediment[x][y].pieceId != pieceId) continue;
      strongestSolidity = max(strongestSolidity, sediment[x][y].solidity);
      strongestConfidence = max(strongestConfidence, sediment[x][y].confidence);
    }
  }

  return strongestSolidity >= LANDED_CONFIRMED_SOLIDITY ||
         (strongestSolidity >= 0.56 && strongestConfidence >= 0.70);
}

float pieceCorruption(int pieceId) {
  float amount = 0;

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      if (sediment[x][y].occupied && sediment[x][y].pieceId == pieceId) {
        amount = max(amount, sediment[x][y].corruption);
      }
    }
  }

  return amount;
}

void increaseSedimentPieceCorruption(int pieceId, float amount) {
  float nextCorruption = constrain(pieceCorruption(pieceId) + amount, 0, 1);

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      if (sediment[x][y].occupied && sediment[x][y].pieceId == pieceId) {
        sediment[x][y].corruption = nextCorruption;
      }
    }
  }
}

void reduceSedimentPieceCorruption(int pieceId, float amount) {
  float nextCorruption = max(0, pieceCorruption(pieceId) - amount);

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      if (sediment[x][y].occupied && sediment[x][y].pieceId == pieceId) {
        sediment[x][y].corruption = nextCorruption;
      }
    }
  }
}

void resetSedimentPieceCorruption(int pieceId) {
  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      if (sediment[x][y].occupied && sediment[x][y].pieceId == pieceId) {
        sediment[x][y].corruption = 0;
      }
    }
  }
}

boolean sedimentHasGravityGap() {
  for (int x = 0; x < COLS; x++) {
    for (int y = ROWS - 2; y >= 0; y--) {
      if (sediment[x][y].occupied && canMoveSedimentPieceDown(sediment[x][y].pieceId)) {
        return true;
      }
    }
  }

  return false;
}

void copyCell(DataCell sourceCell, DataCell targetCell) {
  targetCell.occupied = sourceCell.occupied;
  targetCell.pieceId = sourceCell.pieceId;
  targetCell.confidence = sourceCell.confidence;
  targetCell.solidity = sourceCell.solidity;
  targetCell.age = sourceCell.age;
  targetCell.distortion = sourceCell.distortion;
  targetCell.visualCode = sourceCell.visualCode;
  targetCell.corruption = sourceCell.corruption;
  targetCell.rejected = sourceCell.rejected;
  targetCell.machineVerified = sourceCell.machineVerified;
}

void clearCell(DataCell cell) {
  cell.occupied = false;
  cell.pieceId = 0;
  cell.confidence = 0;
  cell.solidity = 0.12;
  cell.age = 0;
  cell.distortion = 0;
  cell.visualCode = 0;
  cell.corruption = 0;
  cell.rejected = false;
  cell.machineVerified = false;
}

void clearSediment() {
  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      clearCell(sediment[x][y]);
      blockTrail[x][y] = 0;
      trace[x][y] = 0;
      traceBit[x][y] = 0;
    }
  }

  accumulationFull = false;
  gravityDirty = false;
  dataTraceParticles.clear();
  conflictParticles.clear();
  if (perceptionBoundary != null) perceptionBoundary.reset();
  nextSedimentPieceId = 1;
  lineFieldDirty = true;
  spawnData();
}

// Custom typed sediment state lives after DataCell for Processing's preprocessor.
DataCell[][] sediment = new DataCell[COLS][ROWS];
