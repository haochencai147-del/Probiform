// Data Sedimentation - split tab
// This file is part of WSAA2_06.pde and is compiled by Processing with the main sketch.

// Interface and display state.
int BOARD_X;
int BOARD_Y;
int BOARD_W;
int BOARD_H;

int LEFT_INFO_X;
int LEFT_INFO_Y;
int LEFT_INFO_W;
int LEFT_INFO_H;
int RIGHT_INFO_X;
int RIGHT_INFO_Y;
int RIGHT_INFO_W;
int RIGHT_INFO_H;
int OUTER_X;
int OUTER_Y;
int OUTER_W;
int OUTER_H;
int BINARY_X;
int BINARY_Y;
int BINARY_W;
int BINARY_H;

int WIN_X;
int WIN_Y;
int WIN_W;
int WIN_H;
int NOTEPAD_X;
int NOTEPAD_Y;
int NOTEPAD_W;
int NOTEPAD_H;
int RIGHT_HUD_X;
int RIGHT_HUD_Y;
int RIGHT_HUD_W;
int GENERATED_WIN_X;
int GENERATED_WIN_Y;
int GENERATED_WIN_W;
int GENERATED_WIN_H;
int WIN_BORDER = 3;
int TITLE_H = 22;
int MENU_H = 20;
int SCROLL = 17;
int WINDOW_PAD = 6;
int CONTENT_X;
int CONTENT_Y;
int CONTENT_W;
int CONTENT_H;

final float BINARY_DIGIT_EXTRA_SPACING = 6.0;
final float BINARY_GROUP_GAP = 18.0;
final int BINARY_STREAM_ROWS = 3;
final int BINARY_STREAM_FONT_SIZE = 16;
final float BINARY_STREAM_ROW_GAP = 22.0;
final int SCREEN_MARGIN = 42;
final int BINARY_GAP = 22;
final int LAYOUT_Y_OFFSET = 56;
final int LEFT_LIFE_RESERVED_W = 150;
String liveBinaryStream = "";
int lastBinaryUpdateFrame = 0;
float activityLevel = 0;
float ledBrightness = 0;
float lastIndicatorDistance = 17.2;
int lastIndicatorBinaryFrame = 0;
float leftScrollbarRatio = 0.5;
float rightScrollbarRatio = 0.5;

PFont humanFont;
PFont machineFont;
PFont terminalFont;
PShape rightLowerArrowsShape;
PImage pageBackgroundImage;
PShape pageBackgroundShape;
PImage mainWindowImage;
PImage groupLogoImage;
PImage generatedWindowImage;

final String PAGE_BACKGROUND_FILE = "file (1) 1.svg";
final String MAIN_WINDOW_IMAGE_FILE = "file 2.png";
final String GROUP_LOGO_IMAGE_FILE = "Group.png";
final String GENERATED_WINDOW_IMAGE_FILE = "file (2) 1.png";
final float PAGE_BACKGROUND_ALIGN_X = 0.5;
final float PAGE_BACKGROUND_ALIGN_Y = 0.0;
final boolean USE_MAIN_WINDOW_SKIN_LAYOUT = true;
final float MAIN_WINDOW_SKIN_BOARD_LEFT = 79.0 / 2137.0;
final float MAIN_WINDOW_SKIN_BOARD_TOP = 166.0 / 1569.0;
final float MAIN_WINDOW_SKIN_BOARD_RIGHT = 2040.0 / 2137.0;
final float MAIN_WINDOW_SKIN_BOARD_BOTTOM = 1468.0 / 1569.0;
final int MAIN_WINDOW_SKIN_MAX_CELL = 64;
final float GENERATED_WINDOW_CONTENT_LEFT = 16.0 / 247.0;
final float GENERATED_WINDOW_CONTENT_TOP = 31.0 / 228.0;
final float GENERATED_WINDOW_CONTENT_RIGHT = 231.0 / 247.0;
final float GENERATED_WINDOW_CONTENT_BOTTOM = 199.0 / 228.0;

// ------------------------------------------------------------
// MINIMAL EXPERIMENTAL MACHINE INTERFACE

void loadPageBackground() {
  if (PAGE_BACKGROUND_FILE.toLowerCase().endsWith(".svg")) {
    pageBackgroundShape = loadShape(sketchPath("../" + PAGE_BACKGROUND_FILE));

    if (pageBackgroundShape == null) {
      pageBackgroundShape = loadShape(PAGE_BACKGROUND_FILE);
    }
  } else {
    pageBackgroundImage = loadImage(sketchPath("../" + PAGE_BACKGROUND_FILE));

    if (pageBackgroundImage == null) {
      pageBackgroundImage = loadImage(PAGE_BACKGROUND_FILE);
    }
  }

  if (pageBackgroundImage == null && pageBackgroundShape == null) {
    println("Page background image not found: " + PAGE_BACKGROUND_FILE);
  }
}

void loadMainWindowShape() {
  mainWindowImage = loadImage(sketchPath("../" + MAIN_WINDOW_IMAGE_FILE));

  if (mainWindowImage == null) {
    mainWindowImage = loadImage(MAIN_WINDOW_IMAGE_FILE);
  }

  if (mainWindowImage == null) {
    println("Main window image not found: " + MAIN_WINDOW_IMAGE_FILE);
  }
}

void loadGroupLogoShape() {
  groupLogoImage = loadImage(sketchPath("../" + GROUP_LOGO_IMAGE_FILE));

  if (groupLogoImage == null) {
    groupLogoImage = loadImage(GROUP_LOGO_IMAGE_FILE);
  }

  if (groupLogoImage == null) {
    println("Group logo image not found: " + GROUP_LOGO_IMAGE_FILE);
  }
}

void loadGeneratedWindowImage() {
  generatedWindowImage = loadImage(sketchPath("../" + GENERATED_WINDOW_IMAGE_FILE));

  if (generatedWindowImage == null) {
    generatedWindowImage = loadImage(GENERATED_WINDOW_IMAGE_FILE);
  }

  if (generatedWindowImage == null) {
    println("Generated window image not found: " + GENERATED_WINDOW_IMAGE_FILE);
  }
}

void drawPageBackground() {
  if (pageBackgroundImage == null && pageBackgroundShape == null) {
    background(128);
    return;
  }

  background(0);

  float sourceW = pageBackgroundImage != null ? pageBackgroundImage.width : pageBackgroundShape.width;
  float sourceH = pageBackgroundImage != null ? pageBackgroundImage.height : pageBackgroundShape.height;

  if (sourceW <= 0 || sourceH <= 0) {
    sourceW = 720;
    sourceH = 726;
  }

  float scale = max(width / sourceW, height / sourceH);
  float drawW = sourceW * scale;
  float drawH = sourceH * scale;
  float drawX = (width - drawW) * PAGE_BACKGROUND_ALIGN_X;
  float drawY = (height - drawH) * PAGE_BACKGROUND_ALIGN_Y;

  if (pageBackgroundImage != null) {
    image(pageBackgroundImage, drawX, drawY, drawW, drawH);
  } else {
    shape(pageBackgroundShape, drawX, drawY, drawW, drawH);
  }
}

void computeWin95Layout() {
  RIGHT_HUD_W = 230;
  BINARY_H = 96;

  int windowChromeH = WINDOW_PAD * 2 + WIN_BORDER * 2 + TITLE_H + MENU_H + SCROLL;
  int windowChromeW = WINDOW_PAD * 2 + WIN_BORDER * 2 + SCROLL;
  int maxBoardW = width - SCREEN_MARGIN * 2 - LEFT_LIFE_RESERVED_W - RIGHT_HUD_W - 24 - windowChromeW;
  int maxBoardH = height - SCREEN_MARGIN * 2 - BINARY_GAP - BINARY_H - windowChromeH;
  CELL = constrain(min(MAX_CELL, maxBoardW / COLS, maxBoardH / ROWS), 24, MAX_CELL);

  BOARD_W = COLS * CELL;
  BOARD_H = ROWS * CELL;

  CONTENT_W = BOARD_W + WINDOW_PAD * 2;
  CONTENT_H = BOARD_H + WINDOW_PAD * 2;
  WIN_W = CONTENT_W + WIN_BORDER * 2 + SCROLL;
  WIN_H = CONTENT_H + WIN_BORDER * 2 + TITLE_H + MENU_H + SCROLL;

  int compositionH = WIN_H + BINARY_GAP + BINARY_H;
  int compositionW = WIN_W + 24 + RIGHT_HUD_W;
  WIN_X = constrain(LEFT_LIFE_RESERVED_W + 18, 24, width - SCREEN_MARGIN - compositionW);
  WIN_Y = constrain((height - compositionH) / 2 + LAYOUT_Y_OFFSET, 20, height - SCREEN_MARGIN - compositionH);

  NOTEPAD_X = WIN_X;
  NOTEPAD_Y = WIN_Y;
  NOTEPAD_W = WIN_W;
  NOTEPAD_H = WIN_H;

  CONTENT_X = WIN_X + WIN_BORDER;
  CONTENT_Y = WIN_Y + WIN_BORDER + TITLE_H + MENU_H;

  BOARD_X = CONTENT_X + WINDOW_PAD;
  BOARD_Y = CONTENT_Y + WINDOW_PAD;

  if (USE_MAIN_WINDOW_SKIN_LAYOUT) {
    applyMainWindowSkinLayout();
  }

  LEFT_INFO_X = 24;
  LEFT_INFO_Y = BOARD_Y + 36;
  LEFT_INFO_W = 0;
  LEFT_INFO_H = BOARD_H;

  RIGHT_HUD_X = NOTEPAD_X + NOTEPAD_W + 24;
  RIGHT_HUD_Y = BOARD_Y + 44;
  RIGHT_INFO_X = RIGHT_HUD_X;
  RIGHT_INFO_Y = RIGHT_HUD_Y;
  RIGHT_INFO_W = RIGHT_HUD_W;
  RIGHT_INFO_H = BOARD_H;
  int terminalTop = min(NOTEPAD_Y + NOTEPAD_H + BINARY_GAP, height - SCREEN_MARGIN - BINARY_H);
  int generatedWinX = RIGHT_HUD_X - 8;
  int generatedWinW = min(390, max(RIGHT_HUD_W + 35, width - generatedWinX - SCREEN_MARGIN));
  int generatedWinH = min(290, max(238, terminalTop - (BOARD_Y + 410)));
  GENERATED_WIN_X = generatedWinX;
  GENERATED_WIN_Y = min(BOARD_Y + BOARD_H - generatedWinH + 34, terminalTop - generatedWinH - 12);
  GENERATED_WIN_W = generatedWinW;
  GENERATED_WIN_H = generatedWinH;

  OUTER_X = 0;
  OUTER_Y = 0;
  OUTER_W = width;
  OUTER_H = height;

  BINARY_X = max(24, WIN_X - 2);
  BINARY_Y = terminalTop;
  BINARY_W = OUTER_W - BINARY_X - 24;
}

void applyMainWindowSkinLayout() {
  int skinBoardX = WIN_X + round(WIN_W * MAIN_WINDOW_SKIN_BOARD_LEFT);
  int skinBoardY = WIN_Y + round(WIN_H * MAIN_WINDOW_SKIN_BOARD_TOP);
  int skinBoardMaxW = round(WIN_W * (MAIN_WINDOW_SKIN_BOARD_RIGHT - MAIN_WINDOW_SKIN_BOARD_LEFT));
  int skinBoardMaxH = round(WIN_H * (MAIN_WINDOW_SKIN_BOARD_BOTTOM - MAIN_WINDOW_SKIN_BOARD_TOP));

  CELL = constrain(min(skinBoardMaxW / COLS, skinBoardMaxH / ROWS), 20, MAIN_WINDOW_SKIN_MAX_CELL);
  BOARD_W = COLS * CELL;
  BOARD_H = ROWS * CELL;

  BOARD_X = skinBoardX + max(0, (skinBoardMaxW - BOARD_W) / 2);
  BOARD_Y = skinBoardY + max(0, skinBoardMaxH - BOARD_H);

  CONTENT_X = BOARD_X - WINDOW_PAD;
  CONTENT_Y = BOARD_Y - WINDOW_PAD;
  CONTENT_W = BOARD_W + WINDOW_PAD * 2;
  CONTENT_H = BOARD_H + WINDOW_PAD * 2;
}

void drawWin95Frame() {
  if (mainWindowImage != null) {
    pushStyle();
    rectMode(CORNER);

    image(mainWindowImage, WIN_X, WIN_Y, WIN_W, WIN_H);

    popStyle();
    return;
  }

  pushStyle();
  rectMode(CORNER);
  strokeCap(SQUARE);
  useHumanFont(16);
  textAlign(LEFT, CENTER);

  drawMainWindowStack();

  noStroke();
  fill(0);
  rect(WIN_X - 3, WIN_Y - 3, WIN_W + 6, WIN_H + 6);
  fill(88);
  rect(WIN_X - 2, WIN_Y - 2, WIN_W + 4, WIN_H + 4);
  fill(204);
  rect(WIN_X, WIN_Y, WIN_W, WIN_H);

  drawWin95RaisedRect(WIN_X, WIN_Y, WIN_W, WIN_H);
  stroke(0);
  strokeWeight(1);
  noFill();
  rect(WIN_X + 2, WIN_Y + 2, WIN_W - 5, WIN_H - 5);

  int titleX = WIN_X + WIN_BORDER;
  int titleY = WIN_Y + WIN_BORDER;
  int titleW = WIN_W - WIN_BORDER * 2;

  noStroke();
  fill(0, 0, 128);
  rect(titleX, titleY, titleW, TITLE_H);
  fill(0, 0, 96);
  rect(titleX, titleY + TITLE_H - 5, titleW, 5);
  stroke(255);
  strokeWeight(1);
  line(titleX, titleY, titleX + titleW - 1, titleY);
  line(titleX, titleY, titleX, titleY + TITLE_H - 1);
  stroke(0);
  line(titleX, titleY + TITLE_H - 1, titleX + titleW - 1, titleY + TITLE_H - 1);
  line(titleX + titleW - 1, titleY, titleX + titleW - 1, titleY + TITLE_H - 1);

  noStroke();
  fill(255);
  drawHeavyText("DATA_BUFFER.LOG - Notepad", titleX + 7, titleY + TITLE_H * 0.5 - 1);

  int buttonSize = 16;
  int buttonGap = 2;
  int closeX = titleX + titleW - buttonSize - 3;
  int maxX = closeX - buttonSize - buttonGap;
  int minX = maxX - buttonSize - buttonGap;
  int buttonY = titleY + 3;

  drawTitleButton(minX, buttonY, buttonSize, "_");
  drawTitleButton(maxX, buttonY, buttonSize, "[]");
  drawTitleButton(closeX, buttonY, buttonSize, "X");

  int menuY = titleY + TITLE_H;
  textAlign(LEFT, CENTER);
  useHumanFont(15);
  noStroke();
  fill(204);
  rect(titleX, menuY, titleW, MENU_H);
  stroke(160);
  for (int mx = titleX + 3; mx < titleX + titleW; mx += 8) {
    point(mx, menuY + MENU_H - 3);
  }
  fill(0);
  float menuX = titleX + 8;
  drawHeavyText("File", menuX, menuY + MENU_H * 0.5 - 1);
  menuX += textWidth("File") + 20;
  drawHeavyText("Edit", menuX, menuY + MENU_H * 0.5 - 1);
  menuX += textWidth("Edit") + 20;
  drawHeavyText("Search", menuX, menuY + MENU_H * 0.5 - 1);
  menuX += textWidth("Search") + 20;
  drawHeavyText("Help", menuX, menuY + MENU_H * 0.5 - 1);

  stroke(128);
  strokeWeight(1);
  line(titleX, menuY + MENU_H - 1, titleX + titleW, menuY + MENU_H - 1);
  stroke(255);
  line(titleX, menuY + MENU_H, titleX + titleW, menuY + MENU_H);

  noStroke();
  fill(255);
  rect(CONTENT_X, CONTENT_Y, CONTENT_W, CONTENT_H);
  drawWin95SunkenRect(CONTENT_X, CONTENT_Y, CONTENT_W, CONTENT_H);

  popStyle();
}

void drawMainWindowStack() {
  int[][] offsets = {
    { -18, 18 },
    { 22, 28 },
    { -34, 40 }
  };

  for (int i = offsets.length - 1; i >= 0; i--) {
    int sx = WIN_X + offsets[i][0];
    int sy = WIN_Y + offsets[i][1];
    int sw = WIN_W - 36 - i * 14;
    int sh = WIN_H - 22 - i * 10;

    noStroke();
    fill(0, 34);
    rect(sx - 3, sy - 3, sw + 6, sh + 6);
    fill(176, 176, 176, 58);
    rect(sx, sy, sw, sh);
    drawWin95RaisedRect(sx, sy, sw, sh);

    int titleX = sx + WIN_BORDER;
    int titleY = sy + WIN_BORDER;
    int titleW = sw - WIN_BORDER * 2;

    noStroke();
    fill(0, 0, 128, 58);
    rect(titleX, titleY, titleW, TITLE_H);
    fill(208, 208, 208, 28);
    rect(
      sx + WIN_BORDER,
      sy + WIN_BORDER + TITLE_H + MENU_H,
      sw - WIN_BORDER * 2 - SCROLL,
      sh - WIN_BORDER * 2 - TITLE_H - MENU_H - SCROLL
    );
  }
}

void drawWin95Scrollbars() {
  if (mainWindowImage != null) return;

  pushStyle();
  rectMode(CORNER);
  strokeCap(SQUARE);

  drawFakeVerticalScrollbar(CONTENT_X + CONTENT_W, CONTENT_Y, SCROLL, CONTENT_H);
  drawFakeHorizontalScrollbar(CONTENT_X, CONTENT_Y + CONTENT_H, CONTENT_W, SCROLL);
  drawWin95RaisedRect(CONTENT_X + CONTENT_W, CONTENT_Y + CONTENT_H, SCROLL, SCROLL);

  popStyle();
}

void updateMachineIndicator() {
  float distance = displayDistanceCm();
  float distanceChange = abs(distance - lastIndicatorDistance);
  float voiceActivity = constrain(map(voiceDelta, 0, max(1, strongVoiceThreshold), 0, 1), 0, 1);
  float distanceActivity = constrain(map(distanceChange, 0.15, 2.6, 0, 1), 0, 1);
  float verifyActivity = constrain(machineValidation, 0, 1);
  float binaryActivity = lastBinaryUpdateFrame != lastIndicatorBinaryFrame ? 0.55 : 0;

  activityLevel = constrain(
    voiceActivity * 0.42 +
    distanceActivity * 0.24 +
    verifyActivity * 0.20 +
    binaryActivity * 0.14,
    0,
    1
  );

  float pulseSpeed = lerp(0.055, 0.34, activityLevel);
  float unevenPulse = 0.5 + 0.5 * sin(frameCount * pulseSpeed + noise(frameCount * 0.037) * TWO_PI);
  float targetBrightness;
  if (activityLevel > 0.82) {
    targetBrightness = 1.00;
  } else if (activityLevel > 0.48) {
    targetBrightness = 0.48 + unevenPulse * 0.50;
  } else if (activityLevel > 0.14) {
    targetBrightness = 0.38 + unevenPulse * 0.42;
  } else {
    targetBrightness = 0.30 + unevenPulse * 0.24;
  }
  if (!arduinoActive && !speaking && activityLevel < 0.08) {
    targetBrightness = 0.28 + unevenPulse * 0.18;
  }

  ledBrightness = lerp(ledBrightness, constrain(targetBrightness, 0.26, 1), 0.24);
  lastIndicatorDistance = distance;
  lastIndicatorBinaryFrame = lastBinaryUpdateFrame;
}

void drawMachineIndicator() {
  pushStyle();

  float ledSize = 7;
  float titleX = WIN_X + WIN_BORDER;
  float titleY = WIN_Y + WIN_BORDER;
  float titleW = WIN_W - WIN_BORDER * 2;
  float buttonSize = 16;
  float buttonGap = 2;
  float closeX = titleX + titleW - buttonSize - 3;
  float minX = closeX - (buttonSize + buttonGap) * 2;
  float ledX = minX - 14;
  float ledY = titleY + TITLE_H * 0.5;

  float r = lerp(160, 255, ledBrightness);
  float g = lerp(24, 56, ledBrightness);
  float b = lerp(24, 52, ledBrightness);
  float a = lerp(150, 255, ledBrightness);

  noStroke();
  fill(46, 0, 0, 225);
  rect(ledX - 4.5, ledY - 4.5, 9, 9);
  fill(255, 38, 38, 42 * ledBrightness);
  rect(ledX - 5.5, ledY - 5.5, 11, 11);
  fill(r, g, b, a);
  rect(ledX - ledSize * 0.5, ledY - ledSize * 0.5, ledSize, ledSize);

  noStroke();
  fill(255, 140, 120, 90 * ledBrightness);
  rect(ledX - 2.5, ledY - 2.5, 2.5, 2.5);

  popStyle();
}

void drawWin95RaisedRect(float x, float y, float w, float h) {
  strokeWeight(1);
  stroke(255);
  line(x, y, x + w - 1, y);
  line(x, y, x, y + h - 1);
  stroke(224);
  line(x + 1, y + 1, x + w - 3, y + 1);
  line(x + 1, y + 1, x + 1, y + h - 3);
  stroke(96);
  line(x + 1, y + h - 2, x + w - 2, y + h - 2);
  line(x + w - 2, y + 1, x + w - 2, y + h - 2);
  stroke(0);
  line(x, y + h - 1, x + w - 1, y + h - 1);
  line(x + w - 1, y, x + w - 1, y + h - 1);
}

void drawWin95SunkenRect(float x, float y, float w, float h) {
  noFill();
  strokeWeight(1);
  stroke(0);
  line(x, y, x + w - 1, y);
  line(x, y, x, y + h - 1);
  stroke(96);
  line(x + 1, y + 1, x + w - 2, y + 1);
  line(x + 1, y + 1, x + 1, y + h - 2);
  stroke(224);
  line(x + 1, y + h - 2, x + w - 2, y + h - 2);
  line(x + w - 2, y + 1, x + w - 2, y + h - 2);
  stroke(255);
  line(x, y + h - 1, x + w - 1, y + h - 1);
  line(x + w - 1, y, x + w - 1, y + h - 1);
}

void drawTitleButton(int x, int y, int size, String symbol) {
  noStroke();
  fill(188);
  rect(x, y, size, size);
  fill(146);
  rect(x + 2, y + 2, size - 4, size - 4);
  fill(204);
  rect(x + 2, y + 2, size - 6, size - 6);
  strokeWeight(1);
  stroke(255);
  line(x, y, x + size - 1, y);
  line(x, y, x, y + size - 1);
  stroke(96);
  line(x + 1, y + size - 2, x + size - 2, y + size - 2);
  line(x + size - 2, y + 1, x + size - 2, y + size - 2);
  stroke(0);
  line(x, y + size - 1, x + size - 1, y + size - 1);
  line(x + size - 1, y, x + size - 1, y + size - 1);
  noStroke();
  fill(0);
  if (symbol.equals("_")) {
    rect(x + 4, y + size - 5, size - 8, 3);
  } else if (symbol.equals("[]")) {
    noFill();
    stroke(0);
    strokeWeight(2);
    rect(x + 4, y + 4, size - 9, size - 9);
    strokeWeight(1);
    line(x + 4, y + 7, x + size - 6, y + 7);
  } else {
    stroke(0);
    strokeWeight(2);
    line(x + 4, y + 4, x + size - 5, y + size - 5);
    line(x + size - 5, y + 4, x + 4, y + size - 5);
  }
}

void drawFakeVerticalScrollbar(int x, int y, int w, int h) {
  rightScrollbarRatio = lerp(rightScrollbarRatio, sensorScrollbarRatio(false), 0.18);
  int thumbH = 52;
  int trackTop = y + w + 3;
  int trackBottom = y + h - w - 3;
  int thumbY = round(lerp(trackTop, trackBottom - thumbH, rightScrollbarRatio));

  noStroke();
  fill(156);
  rect(x, y, w, h);
  fill(188);
  rect(x + 3, y + w + 2, w - 6, h - w * 2 - 4);
  stroke(130);
  strokeWeight(1);
  for (int ty = y + w + 7; ty < y + h - w - 4; ty += 8) {
    line(x + 4, ty, x + w - 5, ty);
  }
  drawWin95RaisedRect(x, y, w, w);
  drawWin95RaisedRect(x, y + h - w, w, w);
  drawPixelArrow(x + 4, y + 4, "up");
  drawPixelArrow(x + 4, y + h - w + 4, "down");
  drawWin95RaisedRect(x + 3, thumbY, w - 6, thumbH);
  stroke(88);
  line(x + w - 5, thumbY + 4, x + w - 5, thumbY + thumbH - 6);
}

void drawFakeHorizontalScrollbar(int x, int y, int w, int h) {
  leftScrollbarRatio = lerp(leftScrollbarRatio, sensorScrollbarRatio(true), 0.18);
  int thumbW = 88;
  int trackLeft = x + h + 3;
  int trackRight = x + w - h - 3;
  int thumbX = round(lerp(trackLeft, trackRight - thumbW, leftScrollbarRatio));

  noStroke();
  fill(156);
  rect(x, y, w, h);
  fill(188);
  rect(x + h + 2, y + 3, w - h * 2 - 4, h - 6);
  stroke(130);
  strokeWeight(1);
  for (int tx = x + h + 7; tx < x + w - h - 4; tx += 8) {
    line(tx, y + 4, tx, y + h - 5);
  }
  drawWin95RaisedRect(x, y, h, h);
  drawWin95RaisedRect(x + w - h, y, h, h);
  drawPixelArrow(x + 4, y + 4, "left");
  drawPixelArrow(x + w - h + 4, y + 4, "right");
  drawWin95RaisedRect(thumbX, y + 3, thumbW, h - 6);
  stroke(88);
  line(thumbX + 4, y + h - 5, thumbX + thumbW - 6, y + h - 5);
}

float sensorScrollbarRatio(boolean useLeftSensor) {
  boolean valid = useLeftSensor ? leftValid : rightValid;
  float smoothedDistance = useLeftSensor ? smoothUsL : smoothUsR;
  float rawDistance = useLeftSensor ? usL : usR;
  float distance = valid && smoothedDistance >= 0 ? smoothedDistance : rawDistance;

  if (!arduinoActive || distance < ULTRASONIC_MIN_CM || distance > ULTRASONIC_MAX_CM) {
    return 0.5;
  }

  return constrain(map(distance, ULTRASONIC_MIN_CM, ULTRASONIC_MAX_CM, 0, 1), 0, 1);
}

void drawPixelArrow(int x, int y, String direction) {
  noStroke();
  fill(0);
  if (direction.equals("up")) {
    rect(x + 4, y + 1, 3, 2);
    rect(x + 3, y + 3, 5, 2);
    rect(x + 2, y + 5, 7, 2);
  } else if (direction.equals("down")) {
    rect(x + 2, y + 3, 7, 2);
    rect(x + 3, y + 5, 5, 2);
    rect(x + 4, y + 7, 3, 2);
  } else if (direction.equals("left")) {
    rect(x + 1, y + 4, 2, 3);
    rect(x + 3, y + 3, 2, 5);
    rect(x + 5, y + 2, 2, 7);
  } else if (direction.equals("right")) {
    rect(x + 5, y + 2, 2, 7);
    rect(x + 7, y + 3, 2, 5);
    rect(x + 9, y + 4, 2, 3);
  }
}

void drawBoardGrid() {
  // The Notepad content plane stays intentionally quiet; event lines are drawn by drawLineField().
}

void drawUI() {
  drawHUD();
  drawGeneratedShapeWindow();
}

void drawHUD() {
  pushStyle();

  if (!useMachineFont(26)) {
    popStyle();
    return;
  }
  textAlign(LEFT, TOP);
  textLeading(30);
  noStroke();

  float rightX = RIGHT_HUD_X;
  float sideY = projectGroupY() + projectGroupH() + 34;
  float binaryY = min(sideY + 314, GENERATED_WIN_Y - 86);

  useMachineFont(26);
  fill(232, 248, 255, 224);
  drawHeavyText("NEXT", rightX, sideY);
  drawNextGlyph(rightX, sideY + 42);

  fill(64, 170, 255, 245);
  useMachineFont(34);
  drawHeavyText("BINARY", rightX, binaryY);
  fill(245, 250, 255, 245);
  useMachineFont(34);
  drawHeavyText(currentBinaryCode, rightX, binaryY + 18);

  useMachineFont(26);
  fill(52, 245, 132, 245);
  drawHeavyText(machineStatusText(), rightX, binaryY + 70);

  popStyle();
}

float projectTitleX() {
  return projectGroupX() + projectGroupW() * 0.06;
}

float projectTitleY() {
  return projectGroupY() + projectGroupH() * 0.40;
}

float projectGroupX() {
  return RIGHT_HUD_X - 40;
}

float projectGroupY() {
  return max(18, WIN_Y - 18);
}

float projectGroupW() {
  return constrain(width - projectGroupX() - 14, RIGHT_HUD_W, 640);
}

float projectGroupH() {
  return projectGroupW() * 230.0 / 292.0;
}

void drawProjectTitleOverlay() {
  pushStyle();

  float groupX = projectGroupX();
  float groupY = projectGroupY();
  float groupW = projectGroupW();
  float groupH = projectGroupH();

  if (groupLogoImage != null) {
    image(groupLogoImage, groupX, groupY, groupW, groupH);
  }

  if (!useMachineFont(66)) {
    popStyle();
    return;
  }

  textAlign(LEFT, TOP);
  textLeading(66);
  noStroke();

  float x = projectTitleX();
  float y = projectTitleY();

  fill(0, 0, 0, 185);
  drawHeavyText("Probiform", x + 4, y + 4);

  fill(245, 250, 255, 250);
  drawHeavyText("Probiform", x, y);

  popStyle();
}

void drawGeneratedShapeWindow() {
  pushStyle();
  rectMode(CORNER);

  int x = GENERATED_WIN_X;
  int y = GENERATED_WIN_Y;
  int w = GENERATED_WIN_W;
  int h = GENERATED_WIN_H;
  if (w <= 0 || h <= 0 || generatedWindowImage == null) {
    popStyle();
    return;
  }

  float drawX = generatedWindowDrawX();
  float drawY = generatedWindowDrawY();
  float drawW = generatedWindowDrawW();
  float drawH = generatedWindowDrawH();

  image(generatedWindowImage, drawX, drawY, drawW, drawH);

  float contentX = drawX + drawW * GENERATED_WINDOW_CONTENT_LEFT;
  float contentY = drawY + drawH * GENERATED_WINDOW_CONTENT_TOP;
  float contentW = drawW * (GENERATED_WINDOW_CONTENT_RIGHT - GENERATED_WINDOW_CONTENT_LEFT);
  float contentH = drawH * (GENERATED_WINDOW_CONTENT_BOTTOM - GENERATED_WINDOW_CONTENT_TOP);

  clip(contentX, contentY, contentW, contentH);
  drawGeneratedSedimentForm(contentX + 4, contentY + 4, contentW - 8, contentH - 8);
  noClip();

  popStyle();
}

float generatedWindowDrawScale() {
  if (generatedWindowImage == null) return 1;
  return min(GENERATED_WIN_W / float(generatedWindowImage.width), GENERATED_WIN_H / float(generatedWindowImage.height));
}

float generatedWindowDrawW() {
  if (generatedWindowImage == null) return GENERATED_WIN_W;
  return generatedWindowImage.width * generatedWindowDrawScale();
}

float generatedWindowDrawH() {
  if (generatedWindowImage == null) return GENERATED_WIN_H;
  return generatedWindowImage.height * generatedWindowDrawScale();
}

float generatedWindowDrawX() {
  return GENERATED_WIN_X + GENERATED_WIN_W * 0.5 - generatedWindowDrawW() * 0.5;
}

float generatedWindowDrawY() {
  return GENERATED_WIN_Y + GENERATED_WIN_H * 0.5 - generatedWindowDrawH() * 0.5;
}

void drawGeneratedSedimentForm(float x, float y, float w, float h) {
  pushStyle();
  rectMode(CORNER);
  noStroke();

  noStroke();
  int occupiedCount = sedimentOccupiedCount();
  if (occupiedCount <= 0) {
    popStyle();
    return;
  }

  drawLiquefiedSedimentCells(x, y, w, h);

  popStyle();
}

void drawRightLowerDrawnRegion() {
  pushStyle();
  rectMode(CORNER);

  float x = GENERATED_WIN_X;
  float y = GENERATED_WIN_Y;
  float w = GENERATED_WIN_W;
  float h = GENERATED_WIN_H;
  if (w <= 0 || h <= 0) {
    popStyle();
    return;
  }

  if (rightLowerArrowsShape == null) {
    rightLowerArrowsShape = loadShape("right-lower-arrows.svg");
    if (rightLowerArrowsShape == null) println("Missing SVG: right-lower-arrows.svg");
  }

  if (rightLowerArrowsShape != null) {
    float windowX = generatedWindowDrawX();
    float windowY = generatedWindowDrawY();
    float windowW = generatedWindowDrawW();
    float windowH = generatedWindowDrawH();
    float arrowsW = windowW * 1.10;
    float arrowsH = arrowsW * rightLowerArrowsShape.height / rightLowerArrowsShape.width;
    float arrowsX = windowX + windowW * 0.50 - arrowsW * 0.50;
    float arrowsY = windowY + windowH - 1;
    shape(rightLowerArrowsShape, arrowsX, arrowsY, arrowsW, arrowsH);
  }

  popStyle();
}

int sedimentOccupiedCount() {
  int count = 0;

  for (int gx = 0; gx < COLS; gx++) {
    for (int gy = 0; gy < ROWS; gy++) {
      if (sediment[gx][gy].occupied) count++;
    }
  }

  return count;
}

void drawLiquefiedSedimentCells(float x, float y, float w, float h) {
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
  float previewW = min(w * 0.78, shapeW * 24);
  float previewH = min(h * 0.78, shapeH * 24);
  float scale = min(previewW / max(1, shapeW), previewH / max(1, shapeH));
  previewW = shapeW * scale;
  previewH = shapeH * scale;
  float originX = x + w * 0.5 - previewW * 0.5;
  float originY = y + h * 0.5 - previewH * 0.5;

  drawLiquefiedDensityBand(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, 230, 0.18, 3.4);
  drawLiquefiedDensityBand(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, 142, 0.36, 2.7);
  drawLiquefiedDensityBand(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, 54, 0.58, 2.1);
}

void drawLiquefiedDensityBand(
  float originX,
  float originY,
  float previewW,
  float previewH,
  int minX,
  int minY,
  int shapeW,
  int shapeH,
  int grey,
  float threshold,
  float softness
) {
  int samples = 54;
  float step = min(previewW, previewH) / samples;
  float sampleW = previewW / ceil(previewW / step);
  float sampleH = previewH / ceil(previewH / step);
  float pulse = sin(frameCount * 0.010) * 0.018;

  noStroke();
  fill(grey, grey, grey, grey > 210 ? 205 : 225);

  for (float px = originX; px < originX + previewW; px += sampleW) {
    for (float py = originY; py < originY + previewH; py += sampleH) {
      float u = map(px + sampleW * 0.5, originX, originX + previewW, -0.45, shapeW - 0.55);
      float v = map(py + sampleH * 0.5, originY, originY + previewH, -0.45, shapeH - 0.55);
      float density = liquefiedPreviewDensity(u, v, minX, minY, softness);

      if (density > threshold + pulse) {
        float edge = constrain(map(abs(density - threshold), 0, 0.22, 0.45, 1.0), 0.45, 1.0);
        rect(px, py, sampleW * edge + 0.8, sampleH * edge + 0.8);
      }
    }
  }
}

float liquefiedPreviewDensity(float localX, float localY, int minX, int minY, float softness) {
  float density = 0;

  for (int gx = 0; gx < COLS; gx++) {
    for (int gy = 0; gy < ROWS; gy++) {
      if (!sediment[gx][gy].occupied) continue;

      float lx = gx - minX;
      float ly = gy - minY;
      float dx = localX - lx;
      float dy = localY - ly;
      float d2 = dx * dx + dy * dy;
      float weight = 0.55 + sediment[gx][gy].confidence * 0.25 + sediment[gx][gy].solidity * 0.20;
      density += exp(-d2 * softness) * weight;
    }
  }

  return constrain(density, 0, 1.6);
}

String machineStatusText() {
  if (!arduinoActive) return "WAITING";
  if (machineValidation > 0.42 || machineResponding) return "VERIFYING";
  if (pendingMoveSteps > 0 || motionDetected || ultrasonicDataPending) return "SCANNING";
  if (speaking || externalVoiceCandidate) return "LISTENING";
  return "ACTIVE";
}

float displayDistanceCm() {
  if (leftValid && rightValid) return min(smoothUsL, smoothUsR);
  if (leftValid) return smoothUsL;
  if (rightValid) return smoothUsR;
  if (usL >= ULTRASONIC_MIN_CM && usL <= ULTRASONIC_MAX_CM) return usL;
  if (usR >= ULTRASONIC_MIN_CM && usR <= ULTRASONIC_MAX_CM) return usR;
  return 17.2;
}

boolean voiceCalibrationActive() {
  return voiceBaselineReady && millis() - voiceCalibrationStartTime < VOICE_CALIBRATION_MS;
}

void drawNextGlyph(float x, float y) {
  pushStyle();
  rectMode(CORNER);
  noStroke();

  int previewCode = computePMSDCode();
  if (previewCode == 0 && currentPMSD != 0) previewCode = currentPMSD;
  if (previewCode == 0 && active != null) previewCode = active.interpretedShapeCode;
  if (previewCode == 0 && keyboardTestMode) previewCode = 9;

  int[][] preview = shapeFromPMSD(previewCode);
  if (preview.length == 0 && active != null) preview = active.cells();
  if (preview.length == 0) {
    popStyle();
    return;
  }

  if (hasBinaryBlockAsset(previewCode)) {
    drawFittedBinaryBlockAsset(previewCode, x - 4, y + 4, 96, 88);
    popStyle();
    return;
  }

  float unit = 20;
  float minCellX = 999;
  float minCellY = 999;
  float maxCellX = -999;
  float maxCellY = -999;
  for (int i = 0; i < preview.length; i++) {
    minCellX = min(minCellX, preview[i][0]);
    minCellY = min(minCellY, preview[i][1]);
    maxCellX = max(maxCellX, preview[i][0]);
    maxCellY = max(maxCellY, preview[i][1]);
  }
  float previewW = max(1, maxCellX - minCellX + 1) * unit;
  float previewH = max(1, maxCellY - minCellY + 1) * unit;
  float offsetX = x + 32 - previewW * 0.5 - minCellX * unit;
  float offsetY = y + 42 - previewH * 0.5 - minCellY * unit;

  for (int i = 0; i < preview.length; i++) {
    float px = offsetX + preview[i][0] * unit;
    float py = offsetY + preview[i][1] * unit;
    fill(232, 248, 255, 215);
    rect(px, py, unit - 3, unit - 3);
  }
  popStyle();
}

void drawMemoryTrace(float x, float y) {
  pushStyle();
  rectMode(CORNER);
  noStroke();

  int count = 0;
  for (int gy = ROWS - 1; gy >= 0 && count < 36; gy--) {
    for (int gx = 0; gx < COLS && count < 36; gx++) {
      if (!sediment[gx][gy].occupied) continue;
      float alpha = map(sediment[gx][gy].confidence, 0, 1, 48, 190);
      if (sediment[gx][gy].corruption > 0.35) {
        fill(210, 30, 36, alpha);
      } else {
        fill(38, 92, 190, alpha);
      }
      rect(x + (count % 12) * 8, y + floor(count / 12) * 8, 5, 5);
      count++;
    }
  }

  stroke(38, 92, 190, 74);
  strokeWeight(0.7);
  line(x, y + 42, x + 92, y + 42);
  popStyle();
}

void drawCRTOverlay() {
  // Keep the machine window plane quiet; event traces are handled by drawLineField().
}
