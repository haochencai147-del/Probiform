// Data Sedimentation - split tab
// This file is part of WSAA2_06.pde and is compiled by Processing with the main sketch.

// ------------------------------------------------------------
// BLOCK DRAWING

PImage[] binaryBlockImages = new PImage[16];
PImage[] binaryBlockLightMasks = new PImage[16];
boolean[] binaryBlockAssetLoaded = new boolean[16];
int[] binaryBlockTrimLeft = new int[16];
int[] binaryBlockTrimTop = new int[16];
int[] binaryBlockTrimRight = new int[16];
int[] binaryBlockTrimBottom = new int[16];
final boolean USE_BINARY_BLOCK_ASSETS = true;
final float BINARY_BLOCK_PIXELS_PER_CELL = 64.0;

void loadBinaryBlockAssets() {
  for (int code = 8; code <= 15; code++) {
    loadBinaryBlockAsset(code);
  }
}

void loadBinaryBlockAsset(int code) {
  if (code < 0 || code >= binaryBlockAssetLoaded.length) return;
  if (binaryBlockAssetLoaded[code]) return;

  String name = binary(code, 4);
  binaryBlockImages[code] = loadImage(sketchPath("../" + name + ".png"));
  if (binaryBlockImages[code] == null) {
    binaryBlockImages[code] = loadImage(name + ".png");
  }
  buildBinaryBlockLightMask(code);
  computeBinaryBlockTrim(code);

  binaryBlockAssetLoaded[code] = true;
}

void buildBinaryBlockLightMask(int code) {
  PImage img = binaryBlockImages[code];
  if (img == null) return;

  img.loadPixels();
  PImage mask = createImage(img.width, img.height, ARGB);
  mask.loadPixels();

  for (int i = 0; i < img.pixels.length; i++) {
    float a = alpha(img.pixels[i]);
    mask.pixels[i] = a <= 4 ? color(255, 255, 255, 0) : color(255, 255, 255, a);
  }

  mask.updatePixels();
  binaryBlockLightMasks[code] = mask;
}

void computeBinaryBlockTrim(int code) {
  PImage img = binaryBlockImages[code];
  if (img == null) return;

  img.loadPixels();
  int left = img.width;
  int top = img.height;
  int right = -1;
  int bottom = -1;

  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      if (alpha(img.pixels[y * img.width + x]) <= 4) continue;
      left = min(left, x);
      top = min(top, y);
      right = max(right, x);
      bottom = max(bottom, y);
    }
  }

  if (right < left || bottom < top) {
    left = 0;
    top = 0;
    right = img.width - 1;
    bottom = img.height - 1;
  }

  binaryBlockTrimLeft[code] = left;
  binaryBlockTrimTop[code] = top;
  binaryBlockTrimRight[code] = right;
  binaryBlockTrimBottom[code] = bottom;
}

boolean hasBinaryBlockAsset(int code) {
  if (!USE_BINARY_BLOCK_ASSETS) return false;
  if (code < 0 || code >= binaryBlockAssetLoaded.length) return false;
  loadBinaryBlockAsset(code);
  return binaryBlockImages[code] != null;
}

void drawBinaryBlockAsset(int code, float x, float y, float w, float h) {
  drawBinaryBlockAsset(code, x, y, w, h, 1.0);
}

void drawBinaryBlockAsset(int code, float x, float y, float w, float h, float solidityAmount) {
  if (!hasBinaryBlockAsset(code)) return;

  pushStyle();
  imageMode(CORNER);
  noTint();

  image(
    binaryBlockImages[code],
    x, y, w, h,
    binaryBlockTrimLeft[code],
    binaryBlockTrimTop[code],
    binaryBlockTrimRight[code] + 1,
    binaryBlockTrimBottom[code] + 1
  );

  float s = constrain(solidityAmount, 0, 1);
  float lightenAlpha = map(s, 0, 1, 145, 0);
  if (lightenAlpha > 1 && binaryBlockLightMasks[code] != null) {
    tint(255, lightenAlpha);
    image(
      binaryBlockLightMasks[code],
      x, y, w, h,
      binaryBlockTrimLeft[code],
      binaryBlockTrimTop[code],
      binaryBlockTrimRight[code] + 1,
      binaryBlockTrimBottom[code] + 1
    );
  }
  noTint();

  popStyle();
}

float binaryBlockAssetAspect(int code) {
  if (!hasBinaryBlockAsset(code)) return 1;
  int trimW = binaryBlockTrimRight[code] - binaryBlockTrimLeft[code] + 1;
  int trimH = binaryBlockTrimBottom[code] - binaryBlockTrimTop[code] + 1;
  if (trimW > 0 && trimH > 0) {
    return trimW / float(trimH);
  }
  return 1;
}

void drawFittedBinaryBlockAsset(int code, float x, float y, float maxW, float maxH) {
  if (!hasBinaryBlockAsset(code)) return;

  float sourceW = binaryBlockTrimRight[code] - binaryBlockTrimLeft[code] + 1;
  float sourceH = binaryBlockTrimBottom[code] - binaryBlockTrimTop[code] + 1;
  if (sourceW <= 0 || sourceH <= 0) return;

  float scale = min(maxW / sourceW, maxH / sourceH);
  float drawW = sourceW * scale;
  float drawH = sourceH * scale;

  drawBinaryBlockAsset(code, x + (maxW - drawW) * 0.5, y + (maxH - drawH) * 0.5, drawW, drawH);
}

void drawBinaryBlockAssetFitCellBox(int code, float x, float y, float boxW, float boxH) {
  drawBinaryBlockAssetFitCellBox(code, x, y, boxW, boxH, 1.0);
}

void drawBinaryBlockAssetFitCellBox(int code, float x, float y, float boxW, float boxH, float solidityAmount) {
  if (!hasBinaryBlockAsset(code)) return;

  float sourceW = binaryBlockTrimRight[code] - binaryBlockTrimLeft[code] + 1;
  float sourceH = binaryBlockTrimBottom[code] - binaryBlockTrimTop[code] + 1;
  if (sourceW <= 0 || sourceH <= 0) return;

  float scale = CELL / BINARY_BLOCK_PIXELS_PER_CELL;
  float drawW = sourceW * scale;
  float drawH = sourceH * scale;

  drawBinaryBlockAsset(code, x + (boxW - drawW) * 0.5, y + (boxH - drawH) * 0.5, drawW, drawH, solidityAmount);
}

void drawSediment() {
  noStroke();

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      if (!sediment[x][y].occupied) continue;
      if (hasBinaryBlockAsset(sediment[x][y].visualCode)) {
        if (isFirstSedimentCellForPiece(sediment[x][y].pieceId, x, y)) {
          drawLandedBinaryBlockPiece(sediment[x][y].pieceId, sediment[x][y].visualCode);
        }
        continue;
      }
      drawLandedDataBlockCell(x, y, sediment[x][y]);
    }
  }
}

void drawFallingData() {
  if (accumulationFull) return;
  if (drawActiveBinaryBlockAsset()) return;

  int[][] cells = active.cells();

  for (int i = 0; i < cells.length; i++) {
    int x = active.column + cells[i][0];
    int y = active.row + cells[i][1];

    if (y >= 0) {
      drawActiveDataBlockCell(x, y, active.voiceSolidity, pmsdBitForCell(active, i, x, y));
    }
  }

  drawActiveConfidenceTag();
}

void drawRecognizedLandingOutline() {
  if (accumulationFull || active == null) return;
  int[][] cells = active.cells();
  if (cells.length == 0) return;

  int landingRow = active.row;
  while (isValid(active.column, landingRow + 1, active.rotation)) {
    landingRow++;
  }

  int minLocalX = 999;
  int maxLocalX = -999;
  int maxLocalY = -999;
  for (int i = 0; i < cells.length; i++) {
    minLocalX = min(minLocalX, cells[i][0]);
    maxLocalX = max(maxLocalX, cells[i][0]);
    maxLocalY = max(maxLocalY, cells[i][1]);
  }

  int bottomY = landingRow + maxLocalY;
  int fieldTop = max(active.row + maxLocalY + 1, bottomY - 3);
  int leftX = active.column + minLocalX - 2;
  int rightX = active.column + maxLocalX + 2;

  pushStyle();
  noFill();
  strokeCap(SQUARE);
  strokeJoin(MITER);

  boolean strongRecognition = active.machineVerified || activeWillContactNextStep();
  float outerAlpha = strongRecognition ? 110 : 68;
  float innerAlpha = strongRecognition ? 255 : 188;

  stroke(0, 255, 80, outerAlpha);
  strokeWeight(5.0);
  drawRecognitionFieldOutline(leftX, rightX, fieldTop, bottomY);

  stroke(0, 255, 96, innerAlpha);
  strokeWeight(2.25);
  drawRecognitionFieldOutline(leftX, rightX, fieldTop, bottomY);

  popStyle();
}

void drawActiveRecognitionFrame() {
  if (accumulationFull || active == null) return;
  int[][] cells = active.cells();
  if (cells.length == 0) return;

  int minX = 999;
  int minY = 999;
  int maxX = -999;
  int maxY = -999;

  for (int i = 0; i < cells.length; i++) {
    int x = active.column + cells[i][0];
    int y = active.row + cells[i][1];
    if (x < 0 || x >= COLS || y < 0 || y >= ROWS) continue;
    minX = min(minX, x);
    minY = min(minY, y);
    maxX = max(maxX, x);
    maxY = max(maxY, y);
  }

  if (maxX < minX || maxY < minY) return;

  float x = BOARD_X + minX * CELL;
  float y = BOARD_Y + max(0, minY - 3) * CELL;
  float w = (maxX - minX + 1) * CELL;
  float h = (minY - max(0, minY - 3)) * CELL;
  if (h <= 0) return;
  boolean strongRecognition = active.machineVerified || activeWillContactNextStep();

  pushStyle();
  rectMode(CORNER);
  noFill();
  strokeCap(SQUARE);
  strokeJoin(MITER);

  stroke(0, 255, 80, strongRecognition ? 96 : 64);
  strokeWeight(5.0);
  rect(x, y, w, h);

  stroke(0, 255, 96, strongRecognition ? 255 : 210);
  strokeWeight(2.1);
  rect(x, y, w, h);

  popStyle();
}

void drawRecognitionFieldOutline(int leftX, int rightX, int topY, int bottomY) {
  leftX = constrain(leftX, 0, COLS - 1);
  rightX = constrain(rightX, 0, COLS - 1);
  topY = constrain(topY, 0, ROWS - 1);
  bottomY = constrain(bottomY, 0, ROWS - 1);
  if (rightX < leftX || bottomY < topY) return;

  for (int y = topY; y <= bottomY; y++) {
    float t = bottomY == topY ? 1 : (y - topY) / float(bottomY - topY);
    int inset = round(lerp(2, 0, t));
    int rowLeft = constrain(leftX + inset, 0, COLS - 1);
    int rowRight = constrain(rightX - inset, 0, COLS - 1);
    if (rowRight < rowLeft) continue;

    float px = BOARD_X + rowLeft * CELL;
    float py = BOARD_Y + y * CELL;
    float pw = (rowRight - rowLeft + 1) * CELL;

    if (y == topY) line(px, py, px + pw, py);
    if (y == bottomY) line(px, py + CELL, px + pw, py + CELL);

    int prevInset = y > topY ? round(lerp(2, 0, (y - 1 - topY) / float(max(1, bottomY - topY)))) : inset;
    int nextInset = y < bottomY ? round(lerp(2, 0, (y + 1 - topY) / float(max(1, bottomY - topY)))) : inset;
    if (y == topY || inset != prevInset) line(px, py, px, py + CELL);
    else line(px, py, px, py + CELL);

    float right = px + pw;
    if (y == topY || inset != prevInset) line(right, py, right, py + CELL);
    else line(right, py, right, py + CELL);

    if (y < bottomY && nextInset != inset) {
      float nextLeft = BOARD_X + constrain(leftX + nextInset, 0, COLS - 1) * CELL;
      float nextRight = BOARD_X + (constrain(rightX - nextInset, 0, COLS - 1) + 1) * CELL;
      line(min(px, nextLeft), py + CELL, max(px, nextLeft), py + CELL);
      line(min(right, nextRight), py + CELL, max(right, nextRight), py + CELL);
    }
  }
}

void drawLandingOutlineEdges(int[][] cells, int landingRow) {
  for (int i = 0; i < cells.length; i++) {
    int x = active.column + cells[i][0];
    int y = landingRow + cells[i][1];
    if (x < 0 || x >= COLS || y < 0 || y >= ROWS) continue;

    float left = BOARD_X + x * CELL;
    float right = left + CELL;
    float top = BOARD_Y + y * CELL;
    float bottom = top + CELL;

    if (!landingShapeOccupies(cells, x - active.column - 1, y - landingRow)) line(left, top, left, bottom);
    if (!landingShapeOccupies(cells, x - active.column + 1, y - landingRow)) line(right, top, right, bottom);
    if (!landingShapeOccupies(cells, x - active.column, y - landingRow - 1)) line(left, top, right, top);
    if (!landingShapeOccupies(cells, x - active.column, y - landingRow + 1)) line(left, bottom, right, bottom);
  }
}

boolean landingShapeOccupies(int[][] cells, int localX, int localY) {
  for (int i = 0; i < cells.length; i++) {
    if (cells[i][0] == localX && cells[i][1] == localY) return true;
  }
  return false;
}

boolean drawActiveBinaryBlockAsset() {
  if (active == null) return false;
  int visualCode = active.interpretedShapeCode;
  if (!hasBinaryBlockAsset(visualCode)) return false;

  int[][] cells = active.cells();
  if (cells.length == 0) return false;

  int minX = 999;
  int minY = 999;
  int maxX = -999;
  int maxY = -999;

  for (int i = 0; i < cells.length; i++) {
    int gx = active.column + cells[i][0];
    int gy = active.row + cells[i][1];
    minX = min(minX, gx);
    minY = min(minY, gy);
    maxX = max(maxX, gx);
    maxY = max(maxY, gy);
  }

  float x = BOARD_X + minX * CELL;
  float y = BOARD_Y + minY * CELL;
  float w = max(1, maxX - minX + 1) * CELL;
  float h = max(1, maxY - minY + 1) * CELL;
  float solidityAmount = activeBinaryBlockSolidity();
  drawBinaryBlockAssetFitCellBox(visualCode, x, y, w, h, solidityAmount);
  drawActiveConfidenceTag(x, y, w, h);
  return true;
}

void drawActiveConfidenceTag() {
  if (active == null || !active.machineVerified) return;

  int[][] cells = active.cells();
  if (cells.length == 0) return;

  int minX = 999;
  int minY = 999;
  int maxX = -999;
  int maxY = -999;

  for (int i = 0; i < cells.length; i++) {
    int gx = active.column + cells[i][0];
    int gy = active.row + cells[i][1];
    minX = min(minX, gx);
    minY = min(minY, gy);
    maxX = max(maxX, gx);
    maxY = max(maxY, gy);
  }

  float x = BOARD_X + minX * CELL;
  float y = BOARD_Y + minY * CELL;
  float w = max(1, maxX - minX + 1) * CELL;
  float h = max(1, maxY - minY + 1) * CELL;
  drawActiveConfidenceTag(x, y, w, h);
}

void drawActiveConfidenceTag(float x, float y, float w, float h) {
  if (active == null || !active.machineVerified) return;
  if (!useMachineFont(20)) return;

  String label = "confidence";
  float padX = 9;
  float padY = 5;
  float tagW = textWidth(label) + padX * 2;
  float tagH = 26;
  float tagX = constrain(x + w + 7, BOARD_X + 2, BOARD_X + BOARD_W - tagW - 2);
  float tagY = constrain(y - 4, BOARD_Y + 2, BOARD_Y + BOARD_H - tagH - 2);

  pushStyle();
  rectMode(CORNER);
  noStroke();
  fill(0, 235);
  rect(tagX, tagY, tagW, tagH);
  fill(0, 255, 96, 245);
  textAlign(LEFT, TOP);
  drawHeavyText(label, tagX + padX, tagY + padY);
  popStyle();
}

float activeBinaryBlockSolidity() {
  if (active == null) return 1;

  float s = constrain(active.voiceSolidity, 0, 1);
  float solidityAmount = map(s, 0.10, LANDED_CONFIRMED_SOLIDITY, 0.18, 1.0);

  if (speaking) {
    solidityAmount = max(solidityAmount, map(constrain(soundLevel, 0, 1), 0, 1, 0.45, 1.0));
  } else if (voiceEnvelope > 0.18) {
    solidityAmount = max(solidityAmount, map(constrain(voiceEnvelope, 0.18, 1), 0.18, 1, 0.35, 0.85));
  }

  if (active.misread > 0.48) {
    solidityAmount = map(active.misread, 0.48, 1, 0.55, 0.95);
  }

  return constrain(solidityAmount, 0.12, 1);
}

boolean isFirstSedimentCellForPiece(int pieceId, int gridX, int gridY) {
  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      if (x == gridX && y == gridY) return true;
      if (sediment[x][y].occupied && sediment[x][y].pieceId == pieceId) return false;
    }
  }
  return true;
}

void drawLandedBinaryBlockPiece(int pieceId, int visualCode) {
  int minX = COLS;
  int minY = ROWS;
  int maxX = -1;
  int maxY = -1;
  float strongestSolidity = 0.10;
  float strongestCorruption = 0;

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      if (!sediment[x][y].occupied || sediment[x][y].pieceId != pieceId) continue;
      minX = min(minX, x);
      minY = min(minY, y);
      maxX = max(maxX, x);
      maxY = max(maxY, y);
      strongestSolidity = max(strongestSolidity, sediment[x][y].solidity);
      strongestCorruption = max(strongestCorruption, sediment[x][y].corruption);
    }
  }

  if (maxX < minX || maxY < minY) return;

  float x = BOARD_X + minX * CELL;
  float y = BOARD_Y + minY * CELL;
  float w = max(1, maxX - minX + 1) * CELL;
  float h = max(1, maxY - minY + 1) * CELL;
  float solidityAmount = map(constrain(strongestSolidity, 0.10, 0.88), 0.10, 0.88, 0.18, 0.96);
  solidityAmount *= map(constrain(strongestCorruption, 0, 1), 0, 1, 1.0, 0.18);
  drawBinaryBlockAssetFitCellBox(visualCode, x, y, w, h, solidityAmount);
}

void drawActiveDataBlockCell(int gridX, int gridY, float solidity, int bitValue) {
  float px = BOARD_X + gridX * CELL;
  float py = BOARD_Y + gridY * CELL;

  float s = constrain(solidity, 0, 1);
  float falseGrey = 235;
  float trueGrey = 42;
  float grey = map(s, 0, 1, falseGrey, trueGrey);
  float margin = 0.75;
  float outlineAmount = speaking ? constrain(soundLevel, 0, 1) : 0;

  rectMode(CORNER);
  noStroke();
  if (active != null && active.misread > 0.48) {
    fill(210, 30, 36, map(active.misread, 0.48, 1, 120, 230));
  } else {
    fill(grey, grey, grey, 238);
  }
  rect(px + margin, py + margin, CELL - margin * 2, CELL - margin * 2);

  if (speaking && (active == null || active.misread <= 0.48)) {
    noFill();
    stroke(18, 18, 18, map(outlineAmount, 0, 1, 90, 230));
    strokeWeight(1.2);
    rect(px + 1, py + 1, CELL - 2, CELL - 2);
    noStroke();
  } else if (voiceEnvelope > 0.18 && (active == null || active.misread <= 0.48)) {
    fill(18, 18, 18, map(voiceEnvelope, 0.18, 1, 0, 42));
    rect(px + 7, py + 7, CELL - 14, CELL - 14);
  }

  drawBlockBinaryBit(bitValue, px, py, active != null && active.misread > 0.48 ? 46 : grey, 235);
}

void drawLandedDataBlockCell(int gridX, int gridY, DataCell cell) {
  float px = BOARD_X + gridX * CELL;
  float py = BOARD_Y + gridY * CELL;

  float s = constrain(cell.solidity, 0, 1);
  float grey = 32;
  float fadeAlpha = map(constrain(cell.corruption, 0, 1), 0, 1, 1.0, 0.08);
  float alpha = 220 * fadeAlpha;
  float margin = 0.75;

  rectMode(CORNER);
  noStroke();

  if (s >= 0.88) {
    fill(32, 32, 32, alpha);
  } else if (s >= LANDED_LOCKED_SOLIDITY) {
    grey = map(s, LANDED_LOCKED_SOLIDITY, 0.88, 88, 42);
    fill(grey, grey, grey, alpha);
  } else if (s >= LANDED_CONFIRMED_SOLIDITY) {
    grey = map(s, LANDED_CONFIRMED_SOLIDITY, LANDED_LOCKED_SOLIDITY, 118, 88);
    fill(grey, grey, grey, alpha);
  } else if (s >= 0.35) {
    grey = map(s, 0.35, LANDED_CONFIRMED_SOLIDITY, 150, 78);
    fill(grey, grey, grey, 205 * fadeAlpha);
  } else {
    grey = map(s, 0.10, 0.35, 232, 170);
    fill(grey, grey, grey, 185 * fadeAlpha);
  }

  rect(px + margin, py + margin, CELL - margin * 2, CELL - margin * 2);
  drawBlockBinaryBit(traceBit[gridX][gridY], px, py, s >= 0.35 ? 72 : grey, alpha);
}

void drawBlockBinaryBit(int bitValue, float px, float py, float baseGrey, float alpha) {
  pushStyle();
  textAlign(CENTER, CENTER);
  if (!useMachineFont(CELL * 0.48)) {
    popStyle();
    return;
  }

  if (baseGrey < 120) {
    fill(245, 245, 245, min(220, alpha * 0.82));
  } else {
    fill(18, 18, 18, min(210, alpha * 0.78));
  }

  String bitText = bitValue == 1 ? "1" : "0";
  text(bitText, px + CELL * 0.5, py + CELL * 0.53);
  text(bitText, px + CELL * 0.5 + 0.6, py + CELL * 0.53);
  popStyle();
}

// ------------------------------------------------------------
// ACTIVE OUTLINE

boolean activeOccupies(int gridX, int gridY) {
  if (accumulationFull) return false;

  int[][] cells = active.cells();

  for (int i = 0; i < cells.length; i++) {
    int x = active.column + cells[i][0];
    int y = active.row + cells[i][1];

    if (x == gridX && y == gridY) return true;
  }

  return false;
}

void drawActiveOuterOutline() {
  if (accumulationFull) return;
  if (active != null && hasBinaryBlockAsset(active.interpretedShapeCode)) return;

  float alpha = speaking ? 220 : 128;

  if (active != null && active.misread > 0.40) {
    stroke(210, 30, 36, alpha);
  } else {
    stroke(18, 18, 18, alpha);
  }
  strokeWeight(0.9);
  strokeCap(SQUARE);
  strokeJoin(MITER);
  noFill();

  int[][] cells = active.cells();

  for (int i = 0; i < cells.length; i++) {
    int x = active.column + cells[i][0];
    int y = active.row + cells[i][1];

    if (y < 0) continue;

    float left = BOARD_X + x * CELL;
    float right = left + CELL;
    float top = BOARD_Y + y * CELL;
    float bottom = top + CELL;

    if (!activeOccupies(x - 1, y)) line(left, top, left, bottom);
    if (!activeOccupies(x + 1, y)) line(right, top, right, bottom);
    if (!activeOccupies(x, y - 1)) line(left, top, right, top);
    if (!activeOccupies(x, y + 1)) line(left, bottom, right, bottom);
  }
}

// ------------------------------------------------------------
// INFERRED FAKE BLOCKS

void drawInferredFakeBlocks() {
  if (accumulationFull) return;

  int[][] movingCells = active.cells();
  boolean recognitionActive = active != null && (active.machineVerified || activeWillContactNextStep());

  for (int i = 0; i < movingCells.length; i++) {
    int mx = active.column + movingCells[i][0];
    int my = active.row + movingCells[i][1];

    if (my < 0) continue;

    int bestX = -1;
    int bestY = -1;
    float bestD = 999;

    for (int ax = 0; ax < COLS; ax++) {
      for (int ay = 0; ay < ROWS; ay++) {
        if (!sediment[ax][ay].occupied) continue;

        float d = dist(mx, my, ax, ay);

        if (d > 1.4 && d < 5.2 && d < bestD) {
          bestD = d;
          bestX = ax;
          bestY = ay;
        }
      }
    }

    if (bestX >= 0) {
      drawFakeBlockPath(mx, my, bestX, bestY, bestD, recognitionActive);
    }
  }
}

boolean activeWillContactNextStep() {
  if (active == null) return false;
  int[][] cells = active.cells();

  for (int i = 0; i < cells.length; i++) {
    int x = active.column + cells[i][0];
    int y = active.row + cells[i][1] + 1;
    if (y >= ROWS) return true;
    if (y >= 0 && x >= 0 && x < COLS && sediment[x][y].occupied) return true;
  }

  return false;
}

void drawFakeBlockPath(int x1, int y1, int x2, int y2, float d, boolean recognitionActive) {
  int dx = x2 - x1;
  int dy = y2 - y1;

  int steps = max(abs(dx), abs(dy));
  if (steps <= 1) return;

  float strength = constrain(map(d, 5.2, 1.4, 0.15, 1.0), 0, 1);
  float confidence = active.confidence;

  for (int i = 1; i < steps; i++) {
    float t = i / float(steps);

    int gx = round(lerp(x1, x2, t));
    int gy = round(lerp(y1, y2, t));

    if (gx < 0 || gx >= COLS || gy < 0 || gy >= ROWS) continue;
    if (dataOccupies(gx, gy)) continue;

    float wave = sin(frameCount * 0.05 + gx * 0.8 + gy * 0.6);
    float flicker = map(wave, -1, 1, 0.72, 1.0);

    float alpha = map(confidence * strength, 0, 1, 20, 105) * flicker;

    drawFakeCell(gx, gy, alpha, strength, recognitionActive);
  }

  // Keep the inferred binary cells, but do not draw connector lines.
}

void drawFakeCell(int gridX, int gridY, float alpha, float strength, boolean recognitionActive) {
  float px = BOARD_X + gridX * CELL;
  float py = BOARD_Y + gridY * CELL;

  float margin = map(strength, 0, 1, 8, 3);

  rectMode(CORNER);
  noStroke();

  if (recognitionActive) fill(0, 255, 80, alpha * 0.62);
  else fill(38, 92, 190, alpha * 0.30);
  rect(px + margin, py + margin, CELL - margin * 2, CELL - margin * 2);

  int bit = (gridX * 17 + gridY * 31 + floor(frameCount / 24)) % 2;

  textAlign(CENTER, CENTER);
  if (!useMachineFont(CELL * 0.42)) return;

  noStroke();
  float bitAlpha = max(70, alpha * 1.7);

  if (recognitionActive) {
    if (bit == 1) fill(0, 255, 80, bitAlpha * 0.96);
    else fill(0, 160, 54, bitAlpha * 0.66);
  } else if (bit == 1) {
    fill(38, 92, 190, bitAlpha * 0.52);
  } else {
    fill(18, 18, 18, bitAlpha * 0.28);
  }

  text(bit, px + CELL * 0.5, py + CELL * 0.52);
}

void drawInferenceContour(int x1, int y1, int x2, int y2, float strength) {
  float px1 = BOARD_X + (x1 + 0.5) * CELL;
  float py1 = BOARD_Y + (y1 + 0.5) * CELL;
  float px2 = BOARD_X + (x2 + 0.5) * CELL;
  float py2 = BOARD_Y + (y2 + 0.5) * CELL;

  noFill();
  stroke(38, 92, 190, map(strength, 0, 1, 8, 42));
  strokeWeight(map(strength, 0, 1, 0.25, 0.55));
  strokeCap(SQUARE);

  line(px1, py1, px2, py2);
}
