// Main board liquefaction field.
// Uses the original blue density-band renderer.

void drawLiquefiedBoardField() {
  int minX = COLS;
  int maxX = -1;
  int minY = ROWS;
  int maxY = -1;

  for (int gx = 0; gx < COLS; gx++) {
    for (int gy = 0; gy < ROWS; gy++) {
      if (!sediment[gx][gy].occupied) continue;
      minX = min(minX, gx);
      maxX = max(maxX, gx);
      minY = min(minY, gy);
      maxY = max(maxY, gy);
    }
  }

  if (maxX < minX || maxY < minY) return;

  int shapeW = maxX - minX + 1;
  int shapeH = maxY - minY + 1;
  float visualShapeW = max(shapeW, 2.0);
  float visualShapeH = max(shapeH, 2.25);
  float previewW = visualShapeW * CELL * 2.35;
  float previewH = visualShapeH * CELL * 2.20;

  float sedimentCenterX = BOARD_X + (minX + shapeW * 0.5) * CELL;
  float sedimentCenterY = BOARD_Y + (minY + shapeH * 0.5) * CELL;
  float originX = sedimentCenterX - previewW * 0.5;
  float originY = sedimentCenterY - previewH * 0.5 - CELL * 0.55;

  pushStyle();
  rectMode(CORNER);
  noStroke();

  drawLiquefiedDensityBand(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, color(232, 240, 255), 0.22, 1.95, 78);
  drawLiquefiedDensityBand(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, color(218, 231, 252), 0.35, 2.55, 92);
  drawLiquefiedDensityBand(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, color(194, 215, 245), 0.50, 3.15, 80);
  drawLiquefiedDensityBand(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, color(162, 190, 232), 0.68, 3.85, 56);
  drawLiquefiedContourEdge(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, 0.50, 3.15, color(158, 190, 236, 58), 1.2);

  popStyle();
}
