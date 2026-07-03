// Data Sedimentation - split tab
// This file is part of WSAA2_06.pde and is compiled by Processing with the main sketch.

// Background line field state.
final int LINE_DEPTH = 6;
Split[] splits;
boolean lineFieldDirty = false;

final int LINE_FIELD_MAJOR_COUNT = 8;
final int LINE_FIELD_MINOR_COUNT = 8;
float[] lineFieldX1 = new float[LINE_FIELD_MAJOR_COUNT + LINE_FIELD_MINOR_COUNT];
float[] lineFieldY1 = new float[LINE_FIELD_MAJOR_COUNT + LINE_FIELD_MINOR_COUNT];
float[] lineFieldX2 = new float[LINE_FIELD_MAJOR_COUNT + LINE_FIELD_MINOR_COUNT];
float[] lineFieldY2 = new float[LINE_FIELD_MAJOR_COUNT + LINE_FIELD_MINOR_COUNT];
float[] lineFieldAlpha = new float[LINE_FIELD_MAJOR_COUNT + LINE_FIELD_MINOR_COUNT];
float[] lineFieldWeight = new float[LINE_FIELD_MAJOR_COUNT + LINE_FIELD_MINOR_COUNT];
float lastLineFieldVoiceDelta = 0;
float lastLineFieldMachineValidation = 0;
float lastLineFieldConfidence = 0;
float lastLineFieldDistance = 0;

// ------------------------------------------------------------
// BACKGROUND LINE FIELD

void updateLineField() {
  markLineFieldDirtyOnSignalChange();
  if (lineFieldDirty) {
    regenerateLineField();
    lineFieldDirty = false;
  }
}

void drawLineField() {
  pushStyle();
  strokeCap(SQUARE);
  noFill();

  for (int i = 0; i < lineFieldX1.length; i++) {
    if (lineFieldAlpha[i] <= 0) continue;
    stroke(18, 18, 18, lineFieldAlpha[i]);
    strokeWeight(lineFieldWeight[i]);
    line(lineFieldX1[i], lineFieldY1[i], lineFieldX2[i], lineFieldY2[i]);
  }

  popStyle();
}

void markLineFieldDirtyOnSignalChange() {
  float confidence = active == null ? input.confidence() : active.confidence;
  float distance = displayDistanceCm();

  if (abs(voiceDelta - lastLineFieldVoiceDelta) > 4.0 ||
      abs(machineValidation - lastLineFieldMachineValidation) > 0.10 ||
      abs(confidence - lastLineFieldConfidence) > 0.12 ||
      abs(distance - lastLineFieldDistance) > 2.2) {
    lineFieldDirty = true;
  }
}

void regenerateLineField() {
  float confidence = active == null ? input.confidence() : active.confidence;
  float distance = displayDistanceCm();

  for (int i = 0; i < lineFieldX1.length; i++) {
    lineFieldAlpha[i] = 0;
  }

  if (active == null || accumulationFull) {
    lastLineFieldVoiceDelta = voiceDelta;
    lastLineFieldMachineValidation = machineValidation;
    lastLineFieldConfidence = confidence;
    lastLineFieldDistance = distance;
    return;
  }

  int[][] cells = active.cells();
  if (cells.length == 0) {
    lastLineFieldVoiceDelta = voiceDelta;
    lastLineFieldMachineValidation = machineValidation;
    lastLineFieldConfidence = confidence;
    lastLineFieldDistance = distance;
    return;
  }

  int minGX = COLS;
  int maxGX = -1;
  int minGY = ROWS;
  int maxGY = -1;
  for (int i = 0; i < cells.length; i++) {
    int gx = active.column + cells[i][0];
    int gy = active.row + cells[i][1];
    if (gx < 0 || gx >= COLS || gy >= ROWS) continue;
    minGX = min(minGX, gx);
    maxGX = max(maxGX, gx);
    minGY = min(minGY, max(0, gy));
    maxGY = max(maxGY, max(0, gy));
  }

  if (maxGX < minGX || maxGY < minGY) {
    minGX = constrain(active.column, 0, COLS - 1);
    maxGX = minGX;
    minGY = 0;
    maxGY = 1;
  }

  float leftEdge = BOARD_X + minGX * CELL;
  float rightEdge = BOARD_X + (maxGX + 1) * CELL;
  float topEdge = BOARD_Y + minGY * CELL;
  float bottomEdge = BOARD_Y + (maxGY + 1) * CELL;
  float centerX = (leftEdge + rightEdge) * 0.5;
  float centerY = (topEdge + bottomEdge) * 0.5;

  float pull = random(CELL * 0.65, CELL * 1.55);
  float outside = random(CELL * 0.18, CELL * 0.48);

  setEdgeLine(0, leftEdge, topEdge - outside, rightEdge, topEdge - outside, pull, true);
  setEdgeLine(1, leftEdge, bottomEdge + outside, rightEdge, bottomEdge + outside, pull, true);
  setEdgeLine(2, leftEdge - outside, topEdge, leftEdge - outside, bottomEdge, pull, false);
  setEdgeLine(3, rightEdge + outside, topEdge, rightEdge + outside, bottomEdge, pull, false);

  int minorIndex = LINE_FIELD_MAJOR_COUNT;
  if (minorIndex < lineFieldX1.length) {
    float topTickX = constrain(centerX + random(-CELL * 0.45, CELL * 0.45), BOARD_X + 4, BOARD_X + BOARD_W - 4);
    setShortEdgeLine(minorIndex++, topTickX, topEdge - outside * 1.9, true, CELL * random(0.7, 1.2));
  }
  if (minorIndex < lineFieldX1.length) {
    float bottomTickX = constrain(centerX + random(-CELL * 0.45, CELL * 0.45), BOARD_X + 4, BOARD_X + BOARD_W - 4);
    setShortEdgeLine(minorIndex++, bottomTickX, bottomEdge + outside * 1.9, true, CELL * random(0.7, 1.2));
  }
  if (minorIndex < lineFieldX1.length) {
    float leftTickY = constrain(centerY + random(-CELL * 0.45, CELL * 0.45), BOARD_Y + 4, BOARD_Y + BOARD_H - 4);
    setShortEdgeLine(minorIndex++, leftEdge - outside * 1.9, leftTickY, false, CELL * random(0.7, 1.2));
  }
  if (minorIndex < lineFieldX1.length) {
    float rightTickY = constrain(centerY + random(-CELL * 0.45, CELL * 0.45), BOARD_Y + 4, BOARD_Y + BOARD_H - 4);
    setShortEdgeLine(minorIndex++, rightEdge + outside * 1.9, rightTickY, false, CELL * random(0.7, 1.2));
  }

  lastLineFieldVoiceDelta = voiceDelta;
  lastLineFieldMachineValidation = machineValidation;
  lastLineFieldConfidence = confidence;
  lastLineFieldDistance = distance;
}

void setEdgeLine(int index, float x1, float y1, float x2, float y2, float pull, boolean horizontal) {
  if (index < 0 || index >= lineFieldX1.length) return;

  if (horizontal) {
    lineFieldX1[index] = constrain(x1 - pull, BOARD_X + 4, BOARD_X + BOARD_W - 4);
    lineFieldY1[index] = constrain(y1, BOARD_Y + 4, BOARD_Y + BOARD_H - 4);
    lineFieldX2[index] = constrain(x2 + pull, BOARD_X + 4, BOARD_X + BOARD_W - 4);
    lineFieldY2[index] = lineFieldY1[index];
  } else {
    lineFieldX1[index] = constrain(x1, BOARD_X + 4, BOARD_X + BOARD_W - 4);
    lineFieldY1[index] = constrain(y1 - pull, BOARD_Y + 4, BOARD_Y + BOARD_H - 4);
    lineFieldX2[index] = lineFieldX1[index];
    lineFieldY2[index] = constrain(y2 + pull, BOARD_Y + 4, BOARD_Y + BOARD_H - 4);
  }

  lineFieldAlpha[index] = random(28, 46);
  lineFieldWeight[index] = random(0.55, 0.95);
}

void setShortEdgeLine(int index, float x, float y, boolean horizontal, float length) {
  if (index < 0 || index >= lineFieldX1.length) return;

  if (horizontal) {
    lineFieldX1[index] = constrain(x - length * 0.5, BOARD_X + 4, BOARD_X + BOARD_W - 4);
    lineFieldY1[index] = constrain(y, BOARD_Y + 4, BOARD_Y + BOARD_H - 4);
    lineFieldX2[index] = constrain(x + length * 0.5, BOARD_X + 4, BOARD_X + BOARD_W - 4);
    lineFieldY2[index] = lineFieldY1[index];
  } else {
    lineFieldX1[index] = constrain(x, BOARD_X + 4, BOARD_X + BOARD_W - 4);
    lineFieldY1[index] = constrain(y - length * 0.5, BOARD_Y + 4, BOARD_Y + BOARD_H - 4);
    lineFieldX2[index] = lineFieldX1[index];
    lineFieldY2[index] = constrain(y + length * 0.5, BOARD_Y + 4, BOARD_Y + BOARD_H - 4);
  }

  lineFieldAlpha[index] = random(14, 26);
  lineFieldWeight[index] = random(0.28, 0.52);
}

void drawSplit(int index, float originX, float originY, float w, float h, boolean verticalLine) {
  if (index >= splits.length || w < 22 || h < 22) return;

  Split s = splits[index];
  int gen = generation(index);

  float pulledValue = blockEdgeTarget(
    index, originX, originY, w, h, verticalLine, s.val
  );

  float drift = s.osc.next() * map(gen, 0, LINE_DEPTH, 0.004, 0.012);
  s.val = constrain(lerp(s.val, pulledValue + drift, 0.14), 0.02, 0.98);

  stroke(18, 18, 18, map(gen, 0, LINE_DEPTH, 54, 7));
  strokeWeight(map(gen, 0, LINE_DEPTH, 0.9, 0.18));

  if (verticalLine) {
    float x = constrain(s.val * w, 1, w - 1);
    line(originX + x, originY, originX + x, originY + h);
    drawSplit(index * 2 + 1, originX, originY, x, h, false);
    drawSplit(index * 2 + 2, originX + x, originY, w - x, h, false);
  } else {
    float y = constrain(s.val * h, 1, h - 1);
    line(originX, originY + y, originX + w, originY + y);
    drawSplit(index * 2 + 1, originX, originY, w, y, true);
    drawSplit(index * 2 + 2, originX, originY + y, w, h - y, true);
  }
}

float blockEdgeTarget(
  int index,
  float originX,
  float originY,
  float regionW,
  float regionH,
  boolean verticalLine,
  float fallback
) {
  float regionStart = verticalLine ? originX : originY;
  float regionSize = verticalLine ? regionW : regionH;
  float regionEnd = regionStart + regionSize;
  float margin = max(3, regionSize * 0.055);
  float currentLine = regionStart + fallback * regionSize;

  float nearestEdge = Float.MAX_VALUE;
  float nearestDistance = Float.MAX_VALUE;
  int edgeCount = 0;

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      if (!sediment[x][y].occupied) continue;
      if (!cellIntersectsRegion(x, y, originX, originY, regionW, regionH)) continue;

      float[] edges = cellEdges(x, y, verticalLine);

      for (int e = 0; e < 2; e++) {
        if (!isContourEdge(x, y, verticalLine, e)) continue;

        if (edges[e] > regionStart + margin && edges[e] < regionEnd - margin) {
          float distance = abs(edges[e] - currentLine);

          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearestEdge = edges[e];
          }

          edgeCount++;
        }
      }
    }
  }

  if (!accumulationFull) {
    int[][] fallingCells = active.cells();

    for (int i = 0; i < fallingCells.length; i++) {
      int x = active.column + fallingCells[i][0];
      int y = active.row + fallingCells[i][1];

      if (y < 0) continue;
      if (!cellIntersectsRegion(x, y, originX, originY, regionW, regionH)) continue;

      float[] edges = cellEdges(x, y, verticalLine);

      for (int e = 0; e < 2; e++) {
        if (!isContourEdge(x, y, verticalLine, e)) continue;

        if (edges[e] > regionStart + margin && edges[e] < regionEnd - margin) {
          float distance = abs(edges[e] - currentLine);

          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearestEdge = edges[e];
          }

          edgeCount++;
        }
      }
    }
  }

  if (edgeCount == 0) return fallback;

  return constrain((nearestEdge - regionStart) / regionSize, 0.02, 0.98);
}

float[] cellEdges(int gridX, int gridY, boolean verticalLine) {
  if (verticalLine) {
    float left = BOARD_X + gridX * CELL;
    return new float[] { left, left + CELL };
  }

  float top = BOARD_Y + gridY * CELL;
  return new float[] { top, top + CELL };
}

boolean isContourEdge(int gridX, int gridY, boolean verticalLine, int edgeIndex) {
  int neighbourX = gridX;
  int neighbourY = gridY;

  if (verticalLine) {
    neighbourX += edgeIndex == 0 ? -1 : 1;
  } else {
    neighbourY += edgeIndex == 0 ? -1 : 1;
  }

  return !dataOccupies(neighbourX, neighbourY);
}

boolean dataOccupies(int gridX, int gridY) {
  if (gridX < 0 || gridX >= COLS || gridY < 0 || gridY >= ROWS) return false;
  if (sediment[gridX][gridY].occupied) return true;

  if (!accumulationFull) {
    int[][] fallingCells = active.cells();

    for (int i = 0; i < fallingCells.length; i++) {
      int x = active.column + fallingCells[i][0];
      int y = active.row + fallingCells[i][1];

      if (x == gridX && y == gridY) return true;
    }
  }

  return false;
}

boolean cellIntersectsRegion(
  int gridX,
  int gridY,
  float originX,
  float originY,
  float regionW,
  float regionH
) {
  float left = BOARD_X + gridX * CELL;
  float top = BOARD_Y + gridY * CELL;
  float right = left + CELL;
  float bottom = top + CELL;

  return right > originX && left < originX + regionW &&
         bottom > originY && top < originY + regionH;
}
