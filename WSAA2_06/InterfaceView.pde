// Data Sedimentation - split tab
// This file is part of WSAA2_06.pde and is compiled by Processing with the main sketch.

// Interface and display state.
int BOARD_X;
int BOARD_Y;
int BOARD_W;
int BOARD_H;
int BOARD_DISPLAY_X;
int BOARD_DISPLAY_W;
float BOARD_RENDER_SCALE_X = 1.0;

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
int RIGHT_COLUMN_W;
float UI_SCALE = 1.0;
float FONT_SCALE = 1.18;
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

float BINARY_DIGIT_EXTRA_SPACING = 6.0;
float BINARY_GROUP_GAP = 18.0;
final int BINARY_STREAM_ROWS = 3;
int BINARY_STREAM_FONT_SIZE = 16;
float BINARY_STREAM_ROW_GAP = 22.0;
int SCREEN_MARGIN = 42;
int BINARY_GAP = 22;
final int LAYOUT_Y_OFFSET = 0;
final int LEFT_LIFE_RESERVED_W = 0;
String liveBinaryStream = "";
int lastBinaryUpdateFrame = 0;
float activityLevel = 0;
float ledBrightness = 0;
float lastIndicatorDistance = 17.2;
int lastIndicatorBinaryFrame = 0;
int lastLeftLRIndicatorFrame = -99999;
int lastRightLRIndicatorFrame = -99999;
float leftScrollbarRatio = 0.5;
float rightScrollbarRatio = 0.5;
float[][] liquidMediumTrace = new float[COLS][ROWS];
float[][] liquidSlowTrace = new float[COLS][ROWS];
float[][] liquidBitTrace = new float[COLS][ROWS];
float[][] liquidVisualTrace = new float[COLS][ROWS];
float[][] liquidCorruptionTrace = new float[COLS][ROWS];
int lastLiquidTraceUpdateFrame = -1;

PFont humanFont;
PFont machineFont;
PFont terminalFont;
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
final int LIQUEFIED_DENSITY_MIN_SAMPLES = 34;
final int LIQUEFIED_DENSITY_MAX_SAMPLES = 58;
final int LIQUEFIED_CONTOUR_MIN_SAMPLES = 30;
final int LIQUEFIED_CONTOUR_MAX_SAMPLES = 52;
final int LIQUEFIED_SAMPLE_MIN_SAMPLES = 24;
final int LIQUEFIED_SAMPLE_MAX_SAMPLES = 42;
final String LIQUEFIED_ASCII_GLYPHS = ".:-=+*#%@01[]{}<>/\\|_";

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
  // 2048 x 1152 is the reference composition. Scaling from the shorter axis
  // keeps the same visual size on 2K and 4K 16:9 monitors without cropping on
  // wider displays.
  UI_SCALE = constrain(min(width / 2048.0, height / 1152.0), 0.70, 2.0);
  FONT_SCALE = constrain(1.18 + max(0, UI_SCALE - 1.0) * 0.10, 1.18, 1.28);

  WIN_BORDER = max(2, round(3 * UI_SCALE));
  TITLE_H = max(16, round(22 * UI_SCALE));
  MENU_H = max(14, round(20 * UI_SCALE));
  SCROLL = max(12, round(17 * UI_SCALE));
  WINDOW_PAD = max(4, round(6 * UI_SCALE));
  SCREEN_MARGIN = max(28, round(42 * UI_SCALE));
  BINARY_GAP = max(15, round(22 * UI_SCALE));
  BINARY_H = max(68, round(96 * UI_SCALE));
  BINARY_DIGIT_EXTRA_SPACING = 6.0 * UI_SCALE;
  BINARY_GROUP_GAP = 18.0 * UI_SCALE;
  BINARY_STREAM_FONT_SIZE = max(12, round(16 * UI_SCALE));
  BINARY_STREAM_ROW_GAP = 22.0 * UI_SCALE;

  // Divide the display into explicit zones. This makes every visual section
  // respond to the monitor instead of inheriting the board's fixed pixel size.
  int sideMarginX = max(round(34 * UI_SCALE), round(width * 0.050));
  int rightEdgeMargin = max(round(4 * UI_SCALE), round(width * 0.002));
  int sideMarginTop = max(round(28 * UI_SCALE), round(height * 0.044));
  int sideMarginBottom = max(round(22 * UI_SCALE), round(height * 0.030));
  int columnGap = max(round(24 * UI_SCALE), round(width * 0.020));

  RIGHT_COLUMN_W = constrain(
    round(width * 0.300),
    round(500 * UI_SCALE),
    round(650 * UI_SCALE)
  );
  RIGHT_HUD_W = round(RIGHT_COLUMN_W * 0.56);

  BINARY_H = max(round(96 * UI_SCALE), round(height * 0.115));
  int availableMainW = width - sideMarginX - rightEdgeMargin - columnGap - RIGHT_COLUMN_W;
  int availableMainH = height - sideMarginTop - sideMarginBottom - BINARY_GAP - BINARY_H;

  WIN_H = max(round(520 * UI_SCALE), availableMainH);
  WIN_W = min(availableMainW, round(WIN_H * 1.45));

  WIN_X = sideMarginX;
  WIN_Y = sideMarginTop + LAYOUT_Y_OFFSET;

  NOTEPAD_X = WIN_X;
  NOTEPAD_Y = WIN_Y;
  NOTEPAD_W = WIN_W;
  NOTEPAD_H = WIN_H;

  CONTENT_X = WIN_X + WIN_BORDER;
  CONTENT_Y = WIN_Y + WIN_BORDER + TITLE_H + MENU_H;
  CONTENT_W = max(1, WIN_W - WIN_BORDER * 2 - SCROLL);
  CONTENT_H = max(1, WIN_H - WIN_BORDER * 2 - TITLE_H - MENU_H - SCROLL);

  BOARD_X = CONTENT_X + WINDOW_PAD;
  BOARD_Y = CONTENT_Y + WINDOW_PAD;
  BOARD_W = max(1, CONTENT_W - WINDOW_PAD * 2);
  BOARD_H = max(1, CONTENT_H - WINDOW_PAD * 2);
  BOARD_DISPLAY_X = BOARD_X;
  BOARD_DISPLAY_W = BOARD_W;
  BOARD_RENDER_SCALE_X = 1.0;

  if (USE_MAIN_WINDOW_SKIN_LAYOUT) {
    applyMainWindowSkinLayout();
  }

  LEFT_INFO_X = round(24 * UI_SCALE);
  LEFT_INFO_Y = BOARD_Y + round(36 * UI_SCALE);
  LEFT_INFO_W = 0;
  LEFT_INFO_H = BOARD_H;

  RIGHT_HUD_X = NOTEPAD_X + NOTEPAD_W + columnGap;
  RIGHT_HUD_Y = BOARD_Y + round(44 * UI_SCALE);
  RIGHT_INFO_X = RIGHT_HUD_X;
  RIGHT_INFO_Y = RIGHT_HUD_Y;
  RIGHT_INFO_W = RIGHT_HUD_W;
  RIGHT_INFO_H = BOARD_H;
  int terminalTop = NOTEPAD_Y + NOTEPAD_H + BINARY_GAP;
  int generatedWinW = min(round(460 * UI_SCALE), RIGHT_COLUMN_W - round(28 * UI_SCALE));
  int generatedWinX = RIGHT_HUD_X + (RIGHT_COLUMN_W - generatedWinW) / 2;
  int generatedWinH = min(
    round(400 * UI_SCALE),
    round(generatedWinW * 228.0 / 247.0)
  );
  GENERATED_WIN_X = generatedWinX;
  GENERATED_WIN_Y = height - sideMarginBottom - generatedWinH;
  GENERATED_WIN_W = generatedWinW;
  GENERATED_WIN_H = generatedWinH;

  OUTER_X = 0;
  OUTER_Y = 0;
  OUTER_W = width;
  OUTER_H = height;

  BINARY_X = WIN_X;
  BINARY_Y = terminalTop;
  BINARY_W = WIN_W;
}

void applyMainWindowSkinLayout() {
  int skinBoardX = WIN_X + round(WIN_W * MAIN_WINDOW_SKIN_BOARD_LEFT);
  int skinBoardY = WIN_Y + round(WIN_H * MAIN_WINDOW_SKIN_BOARD_TOP);
  int skinBoardMaxW = round(WIN_W * (MAIN_WINDOW_SKIN_BOARD_RIGHT - MAIN_WINDOW_SKIN_BOARD_LEFT));
  int skinBoardMaxH = round(WIN_H * (MAIN_WINDOW_SKIN_BOARD_BOTTOM - MAIN_WINDOW_SKIN_BOARD_TOP));

  int skinMinCell = max(14, round(20 * UI_SCALE));
  int skinMaxCell = max(skinMinCell, round(MAIN_WINDOW_SKIN_MAX_CELL * UI_SCALE));
  CELL = constrain(min(skinBoardMaxW / COLS, skinBoardMaxH / ROWS), skinMinCell, skinMaxCell);
  BOARD_W = COLS * CELL;
  BOARD_H = ROWS * CELL;

  BOARD_X = skinBoardX + max(0, (skinBoardMaxW - BOARD_W) / 2);
  BOARD_Y = skinBoardY + max(0, skinBoardMaxH - BOARD_H);
  BOARD_DISPLAY_X = skinBoardX;
  BOARD_DISPLAY_W = skinBoardMaxW;
  BOARD_RENDER_SCALE_X = BOARD_DISPLAY_W / float(max(1, BOARD_W));

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

  float ledSize = ui(7);
  float titleX = WIN_X + WIN_BORDER;
  float titleY = WIN_Y + WIN_BORDER;
  float titleW = WIN_W - WIN_BORDER * 2;
  float buttonSize = ui(16);
  float buttonGap = ui(2);
  float closeX = titleX + titleW - buttonSize - ui(3);
  float minX = closeX - (buttonSize + buttonGap) * 2;
  float ledX = minX - ui(14);
  float ledY = titleY + TITLE_H * 0.5;

  float r = lerp(160, 255, ledBrightness);
  float g = lerp(24, 56, ledBrightness);
  float b = lerp(24, 52, ledBrightness);
  float a = lerp(150, 255, ledBrightness);

  noStroke();
  fill(46, 0, 0, 225);
  rect(ledX - ui(4.5), ledY - ui(4.5), ui(9), ui(9));
  fill(255, 38, 38, 42 * ledBrightness);
  rect(ledX - ui(5.5), ledY - ui(5.5), ui(11), ui(11));
  fill(r, g, b, a);
  rect(ledX - ledSize * 0.5, ledY - ledSize * 0.5, ledSize, ledSize);

  noStroke();
  fill(255, 140, 120, 90 * ledBrightness);
  rect(ledX - ui(2.5), ledY - ui(2.5), ui(2.5), ui(2.5));

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

void notifyLRIndicator(int direction) {
  if (direction < 0) lastLeftLRIndicatorFrame = frameCount;
  if (direction > 0) lastRightLRIndicatorFrame = frameCount;
}

void drawLRInputIndicators() {
  boolean leftActive = ultrasonicDirection.equals("LEFT") || pendingMoveDirection < 0 || frameCount - lastLeftLRIndicatorFrame < 22;
  boolean rightActive = ultrasonicDirection.equals("RIGHT") || pendingMoveDirection > 0 || frameCount - lastRightLRIndicatorFrame < 22;

  float y = BOARD_Y + max(ui(70), CELL * 1.55);
  float leftX = BOARD_X + max(ui(58), CELL * 1.25);
  float rightX = BOARD_X + BOARD_W - max(ui(66), CELL * 1.35);

  drawLRIndicator("L", leftX, y, leftActive);
  drawLRIndicator("R", rightX, y, rightActive);
}

void drawLRIndicator(String label, float x, float y, boolean activeSide) {
  pushStyle();
  textAlign(CENTER, CENTER);
  noStroke();

  float fontSize = max(ui(72), CELL * 1.65);
  useMachineFont(fontSize);

  if (activeSide) {
    float pulse = 0.5 + 0.5 * sin(frameCount * 0.24);
    float ring = fontSize * (1.28 + pulse * 0.10);

    noFill();
    strokeCap(SQUARE);
    strokeJoin(MITER);

    stroke(0, 255, 118, 70 + pulse * 68);
    strokeWeight(ui(6.4));
    ellipse(x, y, ring, ring);

    stroke(150, 255, 190, 180 + pulse * 58);
    strokeWeight(ui(2.3));
    ellipse(x, y, ring * 0.82, ring * 0.82);

    noStroke();
    fill(0, 255, 118, 46 + pulse * 38);
    ellipse(x, y, ring * 0.58, ring * 0.58);
  }

  fill(activeSide ? color(0, 0, 0, 245) : color(0, 0, 0, 230));
  drawHeavyText(label, x, y + fontSize * 0.02);

  popStyle();
}

void drawUnattendedModeNotice() {
  if (!unattendedMode) return;

  pushStyle();
  noStroke();
  useMachineFont(constrain(CELL * 1.55, ui(58), ui(96)));
  drawCenteredMachineStatus(
    "AUTONOMOUS MODE",
    BOARD_X + BOARD_W * 0.5,
    BOARD_Y + BOARD_H * 0.5
  );

  popStyle();
}

void drawSensorSystemReadyNotice() {
  if (!sensorSystemReadyWaiting) return;

  pushStyle();
  rectMode(CENTER);
  textAlign(CENTER, CENTER);

  float centerX = BOARD_DISPLAY_X + BOARD_DISPLAY_W * 0.5;
  float centerY = BOARD_Y + BOARD_H * 0.5;
  float panelW = min(BOARD_DISPLAY_W * 0.82, ui(980));
  float panelH = ui(170);

  stroke(52, 245, 132, 220);
  strokeWeight(ui(2));
  fill(0, 0, 0, 225);
  rect(centerX, centerY, panelW, panelH);

  noStroke();
  useMachineFont(ui(42));
  fill(52, 245, 132, 255);
  drawHeavyText(">>SENSOR SYSTEM READY <<", centerX, centerY - ui(28));

  useMachineFont(ui(23));
  fill(245, 250, 255, 250);
  drawHeavyText("Waiting for heart touch to start...", centerX, centerY + ui(36));

  popStyle();
}

void drawCenteredMachineStatus(String value, float centerX, float centerY) {
  String leftMarker = ">> ";
  String rightMarker = " <<";
  float leftWidth = textWidth(leftMarker);
  float valueWidth = textWidth(value);
  float totalWidth = leftWidth + valueWidth + textWidth(rightMarker);
  float drawX = centerX - totalWidth * 0.5;

  textAlign(LEFT, CENTER);
  fill(206, 56, 48, 245);
  drawHeavyText(leftMarker, drawX, centerY);

  drawX += leftWidth;
  fill(52, 245, 132, 245);
  drawHeavyText(value, drawX, centerY);

  drawX += valueWidth;
  fill(206, 56, 48, 245);
  drawHeavyText(rightMarker, drawX, centerY);
}

void drawUI() {
  drawHUD();
  drawGeneratedShapeWindow();
}

void drawHUD() {
  pushStyle();

  if (!useMachineFont(ui(26))) {
    popStyle();
    return;
  }
  textAlign(LEFT, TOP);
  textLeading(30);
  noStroke();

  float rightX = RIGHT_HUD_X;
  float sideY = projectGroupY() + projectGroupH() + ui(24);
  float binaryY = min(sideY + ui(308), GENERATED_WIN_Y - ui(150));
  float binaryCodeY = binaryY + ui(42);
  float statusY = min(binaryY + ui(104), GENERATED_WIN_Y - ui(42));
  float nextX = min(generatedWindowDrawX() + generatedWindowDrawW() - ui(118), rightX + ui(246));
  float nextY = max(sideY + ui(8), binaryY - ui(54));

  useMachineFont(ui(26));
  String nextLeftMarker = ">> ";
  String nextRightMarker = " <<";
  fill(206, 56, 48, 245);
  drawHeavyText(nextLeftMarker, nextX - textWidth(nextLeftMarker), nextY);
  fill(232, 248, 255, 224);
  drawHeavyText("NEXT", nextX, nextY);
  fill(206, 56, 48, 245);
  drawHeavyText(nextRightMarker, nextX + textWidth("NEXT"), nextY);
  drawNextGlyph(nextX, nextY + ui(28));

  fill(64, 170, 255, 245);
  useMachineFont(ui(34));
  drawHeavyText("BINARY", rightX, binaryY);
  fill(245, 250, 255, 245);
  useMachineFont(ui(34));
  drawHeavyText(currentBinaryCode, rightX, binaryCodeY);

  useMachineFont(ui(26));
  fill(52, 245, 132, 245);
  drawHeavyText(machineStatusText(), rightX, statusY);

  popStyle();
}

float projectTitleX() {
  return projectGroupX() + projectGroupW() * 0.075;
}

float projectTitleY() {
  return projectGroupY() + projectGroupH() * 0.46;
}

float projectGroupX() {
  return RIGHT_HUD_X - ui(18);
}

float projectGroupY() {
  return max(ui(18), WIN_Y - ui(18));
}

float projectGroupW() {
  // The logo begins slightly left of the HUD anchor, so include that overhang
  // in its width and let the artwork finish at the same right edge as the
  // generated window.
  return min(RIGHT_COLUMN_W + ui(18), width - projectGroupX() - ui(4));
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

  float titleSize = ui(86);
  if (!useMachineFont(titleSize)) {
    popStyle();
    return;
  }

  float maxTitleW = groupW * 0.88;
  float measuredTitleW = textWidth("Probiform");
  if (measuredTitleW > maxTitleW) {
    titleSize *= maxTitleW / measuredTitleW;
    useMachineFont(titleSize);
  }

  textAlign(LEFT, TOP);
  textLeading(titleSize);
  noStroke();

  float x = projectTitleX();
  float y = projectTitleY();

  fill(0, 0, 0, 185);
  drawHeavyText("Probiform", x + ui(4), y + ui(4));

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
  drawGeneratedSedimentForm(contentX + 2, contentY + 2, contentW - 4, contentH - 4);
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

  int occupiedCount = sedimentOccupiedCount();

  if (occupiedCount > 0) {
    drawLiquefiedSedimentCells(
      x + w * 0.015,
      y + h * 0.015,
      w * 0.97,
      h * 0.97
    );
  }

  drawGeneratedLiquefactionMetadata(x, y, w, h, occupiedCount);

  popStyle();
}

void drawGeneratedLiquefactionMetadata(
  float x,
  float y,
  float w,
  float h,
  int occupiedCount
) {
  float padX = max(14.0, w * 0.055);
  float rightX = x + w - padX;
  float statusSize = constrain(h * 0.045, 10.0, 17.0);
  float valueSize = constrain(h * 0.065, 14.0, 24.0);
  String status = generatedLiquefactionStatus(occupiedCount);
  int confidencePercent = round(generatedLiquefactionConfidence() * 100.0);
  int iteration = max(0, nextSedimentPieceId - 1);

  pushStyle();
  textAlign(RIGHT, BASELINE);

  noStroke();
  useMachineFont(statusSize);
  fill(22, 24, 26, 238);
  text("> " + status + " <", rightX, y + h * 0.100);

  float rowOneY = y + h * 0.890;
  float rowTwoY = y + h * 0.950;

  useMachineFont(valueSize);
  fill(206, 56, 48, 235);
  text("=>>=>>" + nf(confidencePercent, 2) + "%", rightX, rowOneY);
  text("=>>=>>" + nf(iteration, 4), rightX, rowTwoY);

  popStyle();
}

String generatedLiquefactionStatus(int occupiedCount) {
  if (occupiedCount <= 0) return "AWAITING DATA";
  if (qrArchiveRecentlyGenerated()) return "ARCHIVED";
  if (accumulationFull) return "SATURATED";
  if (unattendedMode) return "INFERRING";
  if (speaking) return "LISTENING";
  if (pendingMoveSteps > 0) return "REPOSITIONING";
  if (machineResponding || machineValidation > 0.58) return "VERIFYING";
  return "RECONSTRUCTING";
}

float generatedLiquefactionConfidence() {
  float total = 0;
  int count = 0;

  for (int gx = 0; gx < COLS; gx++) {
    for (int gy = 0; gy < ROWS; gy++) {
      if (!sediment[gx][gy].occupied) continue;
      DataCell cell = sediment[gx][gy];
      float cellConfidence = cell.confidence * 0.62 + cell.solidity * 0.28 + (cell.machineVerified ? 0.10 : 0);
      cellConfidence *= 1.0 - cell.corruption * 0.52;
      total += constrain(cellConfidence, 0, 1);
      count++;
    }
  }

  if (count <= 0) return 0;
  return constrain(total / count, 0, 1);
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
  updateLiquefiedTemporalTraces();

  int minX = COLS;
  int maxX = -1;
  int minY = ROWS;
  int maxY = -1;

  for (int gx = 0; gx < COLS; gx++) {
    for (int gy = 0; gy < ROWS; gy++) {
      if (!sediment[gx][gy].occupied && liquidMediumTrace[gx][gy] < 0.070) continue;
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
  float visualShapeH = max(shapeH, 2.0);
  float scale = min((w * 0.98) / visualShapeW, (h * 0.96) / visualShapeH);
  float previewW = visualShapeW * scale;
  float previewH = visualShapeH * scale;
  float originX = x + w * 0.5 - previewW * 0.5;
  float originY = y + h * 0.5 - previewH * 0.5;

  // Hybrid reconstruction: the older liquefied body remains underneath,
  // while the Tetris/binary ASCII extraction acts as its data skin.
  // Stronger tonal separation keeps the small liquefaction preview readable
  // without losing the soft, layered density falloff.
  drawLiquefiedDensityBand(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, 198, 0.08, 1.30, 90);
  drawLiquefiedDensityBand(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, 146, 0.18, 1.85, 100);
  drawLiquefiedDensityBand(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, 76, 0.34, 2.55, 108);
  drawLiquefiedDensityBand(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, 24, 0.58, 3.45, 84);
  drawLiquefiedForgettingLayer(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH);
  drawMachineThinkingLayer(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH);
  drawHalftoneXeroxExtractionLayer(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH);
  drawLiquefiedContourEdge(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, 0.18, 1.85, color(92, 92, 88, 126), 1.15);
  drawLiquefiedContourEdge(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, 0.58, 3.45, color(16, 16, 16, 158), 1.05);
  drawLiquefiedAsciiField(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, false);
}

void drawLiquefiedAsciiField(
  float originX,
  float originY,
  float previewW,
  float previewH,
  int minX,
  int minY,
  int shapeW,
  int shapeH,
  boolean darkField
) {
  float glyphSize = constrain(min(previewW, previewH) / 34.0, 5.2, 10.5);
  float charW = glyphSize * 0.68;
  float charH = glyphSize * 0.92;
  int cols = constrain(ceil(previewW / charW), 12, 84);
  int rows = constrain(ceil(previewH / charH), 10, 64);
  float stepX = previewW / cols;
  float stepY = previewH / rows;
  int glyphCount = LIQUEFIED_ASCII_GLYPHS.length();
  float drive = liquefiedDriveAmount();
  float asciiTime = frameCount * (0.018 + drive * 0.040);

  pushStyle();
  textAlign(CENTER, CENTER);
  useMachineFont(glyphSize);
  noStroke();

  for (int ix = 0; ix < cols; ix++) {
    for (int iy = 0; iy < rows; iy++) {
      float px = originX + (ix + 0.5) * stepX;
      float py = originY + (iy + 0.5) * stepY;
      float u = map(px, originX, originX + previewW, -0.5, shapeW - 0.5);
      float v = map(py, originY, originY + previewH, -0.5, shapeH - 0.5);
      float signal = liquefiedPreviewDensity(u, v, minX, minY, shapeW, shapeH, 2.25);
      if (signal < 0.035) continue;

      int dataX = constrain(round(u + minX), 0, COLS - 1);
      int dataY = constrain(round(v + minY), 0, ROWS - 1);
      boolean occupied = sediment[dataX][dataY].occupied;
      // Occupied cells are drawn below as data-rich Tetris subgrids. This
      // first pass only renders the liquefied memory surrounding them.
      if (occupied) continue;
      int bit = occupied ? traceBit[dataX][dataY] : (liquidBitTrace[dataX][dataY] > 0.45 ? 1 : 0);
      float corruption = max(occupied ? sediment[dataX][dataY].corruption : 0, liquidCorruptionTrace[dataX][dataY]);
      int animationStep = frameCount / 12;
      int glyphIndex = (ix * 7 + iy * 11 + animationStep + int(signal * 13)) % glyphCount;
      char glyph = LIQUEFIED_ASCII_GLYPHS.charAt(glyphIndex);
      if (occupied && (ix + iy + animationStep) % 3 == 0) glyph = bit == 1 ? '1' : '0';

      float lifePulse = 0.72 + sin(asciiTime + ix * 0.31 - iy * 0.23) * 0.28;
      float alpha = map(constrain(signal, 0.035, 1.10), 0.035, 1.10, 38, 245) * lifePulse;
      boolean accent = occupied && (bit == 1 || corruption > 0.30);

      if (accent) {
        fill(255, 24, 24, alpha * 0.92);
      } else if (darkField) {
        fill(245, 248, 246, alpha);
      } else {
        fill(16, 22, 26, alpha * 0.82);
      }

      float driftX = sin(asciiTime * 0.83 + iy * 0.37) * stepX * (0.06 + drive * 0.16);
      float driftY = cos(asciiTime * 0.71 + ix * 0.29) * stepY * (0.04 + drive * 0.12);
      text(glyph, px + driftX, py + driftY);
    }
  }

  popStyle();
  drawLiquefiedTetrisBinaryCells(originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, darkField);
}

void drawLiquefiedTetrisBinaryCells(
  float originX,
  float originY,
  float previewW,
  float previewH,
  int minX,
  int minY,
  int shapeW,
  int shapeH,
  boolean darkField
) {
  float cellW = previewW / max(1, shapeW);
  float cellH = previewH / max(1, shapeH);
  int subdivisions = constrain(round(min(cellW, cellH) / 14.0), 3, 18);
  float subW = cellW / subdivisions;
  float subH = cellH / subdivisions;
  float glyphSize = constrain(min(subW, subH) * 0.92, 5.4, 14.0);
  int animationStep = frameCount / 18;
  float drive = liquefiedDriveAmount();
  float motionPhase = frameCount * (0.020 + drive * 0.055);

  pushStyle();
  textAlign(CENTER, CENTER);
  useMachineFont(glyphSize);
  noStroke();

  for (int gx = max(0, minX); gx <= min(COLS - 1, minX + shapeW - 1); gx++) {
    for (int gy = max(0, minY); gy <= min(ROWS - 1, minY + shapeH - 1); gy++) {
      if (!sediment[gx][gy].occupied) continue;

      DataCell cell = sediment[gx][gy];
      int localX = gx - minX;
      int localY = gy - minY;
      int landedBit = traceBit[gx][gy];
      boolean openLeft = !liquefiedSamePiece(gx - 1, gy, cell.pieceId);
      boolean openRight = !liquefiedSamePiece(gx + 1, gy, cell.pieceId);
      boolean openTop = !liquefiedSamePiece(gx, gy - 1, cell.pieceId);
      boolean openBottom = !liquefiedSamePiece(gx, gy + 1, cell.pieceId);

      for (int sx = 0; sx < subdivisions; sx++) {
        for (int sy = 0; sy < subdivisions; sy++) {
          float px = originX + localX * cellW + (sx + 0.5) * subW;
          float py = originY + localY * cellH + (sy + 0.5) * subH;
          int codeShift = (sx + sy + cell.visualRotation + animationStep / 2) % 4;
          int codeBit = (cell.visualCode >> codeShift) & 1;
          char glyph = codeBit == 1 ? '1' : '0';
          float extractionWave = 0.5 + 0.5 * sin(
            motionPhase +
            cell.pieceId * 0.37 +
            localY * 0.62 +
            sy * 0.48 -
            sx * 0.21
          );
          boolean boundaryGlyph = false;

          // Piece boundaries reveal the original Tetris connectivity. Shared
          // edges disappear, so cells from the same landed piece read as one.
          if (openLeft && sx == 0) { glyph = '['; boundaryGlyph = true; }
          if (openRight && sx == subdivisions - 1) { glyph = ']'; boundaryGlyph = true; }
          if (openTop && sy == 0 && sx > 0 && sx < subdivisions - 1) { glyph = '-'; boundaryGlyph = true; }
          if (openBottom && sy == subdivisions - 1 && sx > 0 && sx < subdivisions - 1) { glyph = '_'; boundaryGlyph = true; }

          if (sx == subdivisions / 2 && sy == subdivisions / 2) glyph = landedBit == 1 ? '1' : '0';
          if (cell.machineVerified && (sx + sy) % 5 == 0) glyph = '#';
          if (cell.lowConfidenceInference && (sx + sy + animationStep) % 7 == 0) glyph = '?';
          if (cell.corruption > 0.28 && (sx * 3 + sy + animationStep) % 6 == 0) {
            glyph = LIQUEFIED_ASCII_GLYPHS.charAt((sx * 5 + sy * 7 + animationStep) % LIQUEFIED_ASCII_GLYPHS.length());
          }

          if (!boundaryGlyph && extractionWave > 0.86) {
            glyph = landedBit == 1 ? '1' : ((sx + sy) % 2 == 0 ? ':' : '.');
          }

          float alpha = map(cell.confidence * 0.55 + cell.solidity * 0.45, 0, 1, 105, 255);
          alpha *= 0.72 + extractionWave * 0.28;
          boolean binaryOne = glyph == '1';
          boolean corrupted = cell.corruption > 0.30 && (sx + sy) % 4 == 0;
          float motionAmount = boundaryGlyph ? 0.035 : 0.10 + drive * 0.13;
          float motionX = sin(motionPhase + sy * 0.52 + cell.pieceId * 0.19) * subW * motionAmount;
          float motionY = cos(motionPhase * 0.81 + sx * 0.46 + cell.visualRotation) * subH * motionAmount;
          if (binaryOne || corrupted) {
            fill(255, 24, 24, alpha);
          } else if (darkField) {
            fill(245, 248, 246, alpha);
          } else {
            fill(16, 22, 26, alpha * 0.88);
          }
          if (!boundaryGlyph && extractionWave > 0.80) {
            fill(binaryOne ? color(255, 24, 24, alpha * 0.20) : color(245, 248, 246, alpha * 0.16));
            text(glyph, px - motionX * 2.4, py - motionY * 2.4);
            if (binaryOne || corrupted) fill(255, 24, 24, alpha);
            else if (darkField) fill(245, 248, 246, alpha);
            else fill(16, 22, 26, alpha * 0.88);
          }
          text(glyph, px + motionX, py + motionY);
        }
      }
    }
  }

  popStyle();
}

boolean liquefiedSamePiece(int gx, int gy, int pieceId) {
  if (gx < 0 || gx >= COLS || gy < 0 || gy >= ROWS) return false;
  return sediment[gx][gy].occupied && sediment[gx][gy].pieceId == pieceId;
}

void drawLiquefiedIterationPage(float x, float y, float w, float h) {
  updateLiquefiedTemporalTraces();

  int minX = COLS;
  int maxX = -1;
  int minY = ROWS;
  int maxY = -1;

  for (int gx = 0; gx < COLS; gx++) {
    for (int gy = 0; gy < ROWS; gy++) {
      if (!sediment[gx][gy].occupied && liquidMediumTrace[gx][gy] < 0.070) continue;
      minX = min(minX, gx);
      maxX = max(maxX, gx);
      minY = min(minY, gy);
      maxY = max(maxY, gy);
    }
  }

  if (maxX < minX || maxY < minY) return;

  int shapeW = maxX - minX + 1;
  int shapeH = maxY - minY + 1;
  int cols = 4;
  int rows = 3;
  float gap = max(5.0, min(w, h) * 0.026);
  float tileW = (w - gap * (cols - 1)) / cols;
  float tileH = (h - gap * (rows - 1)) / rows;

  pushStyle();
  rectMode(CORNER);
  noStroke();

  for (int i = 0; i < cols * rows; i++) {
    int cx = i % cols;
    int cy = i / cols;
    float tx = x + cx * (tileW + gap);
    float ty = y + cy * (tileH + gap);
    drawLiquefiedIterationTile(tx, ty, tileW, tileH, i, minX, minY, shapeW, shapeH);
  }

  popStyle();
}

void drawLiquefiedIterationTile(float x, float y, float w, float h, int stage, int minX, int minY, int shapeW, int shapeH) {
  float pad = max(3.0, min(w, h) * 0.060);
  float labelH = 0;
  float gx0 = x + pad;
  float gy0 = y + pad + labelH;
  float gw = w - pad * 2.0;
  float gh = h - pad * 2.0 - labelH;
  int sampleCols = constrain(int(gw / 2.8), 16, 30);
  int sampleRows = constrain(int(gh / 2.8), 12, 24);
  float dotW = gw / sampleCols;
  float dotH = gh / sampleRows;
  float progress = stage / 11.0;

  noStroke();
  fill(232, 232, 228, 30);
  rect(x, y, w, h);

  noStroke();
  for (int sx = 0; sx < sampleCols; sx++) {
    for (int sy = 0; sy < sampleRows; sy++) {
      float px = gx0 + (sx + 0.5) * dotW;
      float py = gy0 + (sy + 0.5) * dotH;
      float u = map(sx + 0.5, 0, sampleCols, -0.75, shapeW - 0.25);
      float v = map(sy + 0.5, 0, sampleRows, -0.95, shapeH - 0.05);
      float stageWarp = map(progress, 0, 1, 0.0, 0.72);
      float flowX = liquefiedDataFlowX(u, v, minX, minY) * stageWarp;
      float flowY = liquefiedDataFlowY(u, v, minX, minY) * stageWarp;
      float density = liquefiedPreviewDensity(u + flowX, v + flowY, minX, minY, shapeW, shapeH, map(progress, 0, 1, 4.8, 1.18));
      int dataX = constrain(round(u + minX), 0, COLS - 1);
      int dataY = constrain(round(v + minY), 0, ROWS - 1);
      boolean occupied = sediment[dataX][dataY].occupied;
      int bit = occupied ? traceBit[dataX][dataY] : (liquidBitTrace[dataX][dataY] > 0.45 ? 1 : 0);
      float trust = occupied ? sediment[dataX][dataY].confidence * 0.58 + sediment[dataX][dataY].solidity * 0.42 : max(liquidMediumTrace[dataX][dataY], liquidSlowTrace[dataX][dataY]);
      float corruption = max(occupied ? sediment[dataX][dataY].corruption : 0, liquidCorruptionTrace[dataX][dataY]);
      float n = noise(sx * 0.23 + stage * 0.41, sy * 0.29, frameCount * 0.004);

      float threshold = map(progress, 0, 1, 0.16, 0.46);
      if (stage < 3) threshold = 0.09 + stage * 0.035;
      if (stage >= 7) threshold -= corruption * 0.16;
      if (density < threshold && n < 0.80 - progress * 0.22) continue;

      float forgetting = constrain((1.0 - trust) * progress * 0.58 + corruption * 0.18, 0, 1);
      if (stage >= 8 && n < forgetting * 0.62) {
        fill(248, 248, 244, 58);
        rect(px - dotW * 0.38, py - dotH * 0.38, dotW * 0.76, dotH * 0.76);
        continue;
      }

      boolean hot = (stage >= 4 && bit == 1) || (stage >= 6 && corruption > 0.24);
      float alpha = map(constrain(density + trust * 0.28, 0.08, 1.15), 0.08, 1.15, 8, 38);
      float s = max(1.0, min(dotW, dotH) * map(density, threshold, 1.2, 0.42, 1.18));

      if (hot && n > 0.28) {
        fill(255, 0, 0, alpha * map(progress, 0, 1, 0.18, 0.42));
      } else {
        float grey = map(progress, 0, 1, 86, 18);
        fill(grey, grey, grey, alpha * map(progress, 0, 1, 0.28, 0.48));
      }

      if (stage < 4) {
        rect(px - s * 0.5, py - s * 0.5, s, s);
      } else {
        ellipse(px, py, s, s);
      }
    }
  }

  if (stage >= 5) {
    drawIterationTileContour(gx0, gy0, gw, gh, stage, minX, minY, shapeW, shapeH);
  }
}

void drawIterationTileContour(float x, float y, float w, float h, int stage, int minX, int minY, int shapeW, int shapeH) {
  int cols = 28;
  int rows = 22;
  float stepX = w / cols;
  float stepY = h / rows;
  float threshold = map(stage, 5, 11, 0.25, 0.48);

  stroke(stage >= 8 ? color(255, 0, 0, 18) : color(18, 18, 18, 18));
  strokeWeight(1.0);
  noFill();

  for (int ix = 1; ix < cols - 1; ix++) {
    for (int iy = 1; iy < rows - 1; iy++) {
      float u = map(ix + 0.5, 0, cols, -0.75, shapeW - 0.25);
      float v = map(iy + 0.5, 0, rows, -0.95, shapeH - 0.05);
      float d = liquefiedPreviewDensity(u, v, minX, minY, shapeW, shapeH, 2.0);
      if (d < threshold) continue;
      float d2 = liquefiedPreviewDensity(u + 0.55, v, minX, minY, shapeW, shapeH, 2.0);
      if (abs(d - d2) < 0.10) continue;
      float px = x + ix * stepX;
      float py = y + iy * stepY;
      line(px - stepX * 0.35, py, px + stepX * 0.35, py);
    }
  }
}

void updateLiquefiedTemporalTraces() {
  if (lastLiquidTraceUpdateFrame == frameCount) return;
  lastLiquidTraceUpdateFrame = frameCount;

  float drive = liquefiedDriveAmount();
  float mediumDecay = map(drive, 0.12, 0.82, 0.948, 0.982);
  float slowDecay = map(drive, 0.12, 0.82, 0.992, 0.998);

  for (int gx = 0; gx < COLS; gx++) {
    for (int gy = 0; gy < ROWS; gy++) {
      float current = 0;
      float currentBit = 0;
      float currentVisual = 0;
      float currentCorruption = 0;

      if (sediment[gx][gy].occupied) {
        int bit = traceBit[gx][gy];
        int visualBit = (sediment[gx][gy].visualCode >> ((gx + gy) % 4)) & 1;
        float trust = sediment[gx][gy].confidence * 0.52 + sediment[gx][gy].solidity * 0.48;
        float corruption = sediment[gx][gy].corruption;
        current = constrain(0.24 + trust * 0.48 + bit * 0.14 + visualBit * 0.08 + corruption * 0.20, 0, 1);
        currentBit = bit;
        currentVisual = visualBit;
        currentCorruption = corruption;
      }

      liquidMediumTrace[gx][gy] = max(liquidMediumTrace[gx][gy] * mediumDecay, current * (0.82 + drive * 0.32));
      liquidSlowTrace[gx][gy] = max(liquidSlowTrace[gx][gy] * slowDecay, current * (0.32 + drive * 0.24));
      liquidBitTrace[gx][gy] = max(liquidBitTrace[gx][gy] * 0.990, currentBit * current);
      liquidVisualTrace[gx][gy] = max(liquidVisualTrace[gx][gy] * 0.992, currentVisual * current);
      liquidCorruptionTrace[gx][gy] = max(liquidCorruptionTrace[gx][gy] * 0.994, currentCorruption);

      if (liquidMediumTrace[gx][gy] < 0.004) liquidMediumTrace[gx][gy] = 0;
      if (liquidSlowTrace[gx][gy] < 0.004) liquidSlowTrace[gx][gy] = 0;
      if (liquidBitTrace[gx][gy] < 0.004) liquidBitTrace[gx][gy] = 0;
      if (liquidVisualTrace[gx][gy] < 0.004) liquidVisualTrace[gx][gy] = 0;
      if (liquidCorruptionTrace[gx][gy] < 0.004) liquidCorruptionTrace[gx][gy] = 0;
    }
  }
}

void drawLiquefiedTemporalTraceLayer(
  float originX,
  float originY,
  float previewW,
  float previewH,
  int minX,
  int minY,
  int shapeW,
  int shapeH,
  boolean mediumLayer
) {
  float cellW = previewW / max(1, shapeW);
  float cellH = previewH / max(1, shapeH);
  float drive = liquefiedDriveAmount();
  float balance = liquefiedSensorBalance();

  pushStyle();
  noStroke();
  rectMode(CENTER);

  for (int gx = max(0, minX); gx <= min(COLS - 1, minX + shapeW - 1); gx++) {
    for (int gy = max(0, minY); gy <= min(ROWS - 1, minY + shapeH - 1); gy++) {
      float memory = mediumLayer ? liquidMediumTrace[gx][gy] : liquidSlowTrace[gx][gy];
      if (memory < (mediumLayer ? 0.035 : 0.022)) continue;

      float localX = gx - minX + 0.5;
      float localY = gy - minY + 0.5;
      float bitMemory = max(traceBit[gx][gy], liquidBitTrace[gx][gy]);
      float visualMemory = max(liquidVisualTrace[gx][gy], sediment[gx][gy].occupied ? ((sediment[gx][gy].visualCode >> ((gx + gy + (mediumLayer ? 1 : 0)) % 4)) & 1) : 0);
      float corruption = max(sediment[gx][gy].corruption, liquidCorruptionTrace[gx][gy]);
      float bitDirection = bitMemory > 0.45 ? 1 : -1;
      float phase = mediumLayer ? frameCount * 0.018 : frameCount * 0.004;
      float driftX = (noise(gx * 0.23, gy * 0.31, phase) - 0.5) * (mediumLayer ? 1.45 : 0.72);
      float driftY = (noise(gx * 0.19 + 12.0, gy * 0.27, phase) - 0.5) * (mediumLayer ? 1.10 : 0.50);
      float flowX = liquefiedDataFlowX(localX, localY, minX, minY);
      float flowY = liquefiedDataFlowY(localX, localY, minX, minY);
      float px = originX + localX * cellW + (flowX + driftX + balance * 0.22) * cellW;
      float py = originY + localY * cellH + (flowY + driftY) * cellH;

      float w = cellW * map(memory, 0, 1, mediumLayer ? 0.68 : 0.92, mediumLayer ? 1.42 : 1.88);
      float h = cellH * map(memory, 0, 1, mediumLayer ? 0.56 : 0.78, mediumLayer ? 1.24 : 1.68);
      float alpha = mediumLayer ? map(memory, 0.035, 1, 38, 150) : map(memory, 0.022, 1, 24, 102);

      if (mediumLayer) {
        fill(70, 70, 70, alpha);
        rect(px, py, w, h);
        if (bitMemory > 0.45 || corruption > 0.34) {
          fill(255, 0, 0, alpha * 0.36);
          rect(px + bitDirection * cellW * 0.16, py, w * 0.34, h * 0.42);
        }
      } else {
        fill(170, 170, 166, alpha);
        ellipse(px, py, w * 1.18, h * 1.02);
        if (visualMemory > 0.45 && noise(gx * 0.41, gy * 0.37, frameCount * 0.003) > 0.52) {
          fill(18, 18, 18, alpha * 0.42);
          rect(px + bitDirection * cellW * 0.20, py + cellH * 0.08, w * 0.46, max(1.0, h * 0.16));
        }
      }
    }
  }

  rectMode(CORNER);
  popStyle();
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
  float softness,
  int alpha
) {
  int samples = constrain(round(min(previewW, previewH) / 3.55), LIQUEFIED_DENSITY_MIN_SAMPLES, LIQUEFIED_DENSITY_MAX_SAMPLES);
  float step = min(previewW, previewH) / samples;
  float sampleW = previewW / ceil(previewW / step);
  float sampleH = previewH / ceil(previewH / step);
  float pulse = sin(frameCount * 0.010) * 0.018;

  noStroke();
  if (grey < 0 || grey > 255) {
    fill(grey, alpha);
  } else {
    fill(grey, grey, grey, alpha);
  }

  for (float px = originX; px < originX + previewW; px += sampleW) {
    for (float py = originY; py < originY + previewH; py += sampleH) {
      float u = map(px + sampleW * 0.5, originX, originX + previewW, -0.75, shapeW - 0.25);
      float v = map(py + sampleH * 0.5, originY, originY + previewH, -0.95, shapeH - 0.05);
      float flowX = liquefiedDataFlowX(u, v, minX, minY);
      float flowY = liquefiedDataFlowY(u, v, minX, minY);
      float density = liquefiedPreviewDensity(u + flowX, v + flowY, minX, minY, shapeW, shapeH, softness);

      if (density > threshold + pulse) {
        float edge = constrain(map(abs(density - threshold), 0, 0.18, 0.58, 1.0), 0.58, 1.0);
        rect(px + flowX * sampleW * 0.86, py + flowY * sampleH * 0.86, sampleW * edge + 1.8, sampleH * edge + 1.8);
      }
    }
  }
}

void drawLiquefiedContourEdge(
  float originX,
  float originY,
  float previewW,
  float previewH,
  int minX,
  int minY,
  int shapeW,
  int shapeH,
  float threshold,
  float softness,
  color edgeColor,
  float edgeWeight
) {
  int samples = constrain(round(min(previewW, previewH) / 3.85), LIQUEFIED_CONTOUR_MIN_SAMPLES, LIQUEFIED_CONTOUR_MAX_SAMPLES);
  float step = min(previewW, previewH) / samples;
  float sampleW = previewW / ceil(previewW / step);
  float sampleH = previewH / ceil(previewH / step);
  int cols = max(1, ceil(previewW / sampleW));
  int rows = max(1, ceil(previewH / sampleH));
  float pulse = sin(frameCount * 0.010) * 0.018;

  stroke(edgeColor);
  strokeWeight(edgeWeight);
  noFill();

  for (int ix = 0; ix < cols; ix++) {
    for (int iy = 0; iy < rows; iy++) {
      float px = originX + ix * sampleW;
      float py = originY + iy * sampleH;
      if (!liquefiedSampleInside(ix, iy, cols, rows, originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, threshold + pulse, softness)) continue;

      if (!liquefiedSampleInside(ix - 1, iy, cols, rows, originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, threshold + pulse, softness)) {
        line(px, py, px, py + sampleH);
      }
      if (!liquefiedSampleInside(ix + 1, iy, cols, rows, originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, threshold + pulse, softness)) {
        line(px + sampleW, py, px + sampleW, py + sampleH);
      }
      if (!liquefiedSampleInside(ix, iy - 1, cols, rows, originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, threshold + pulse, softness)) {
        line(px, py, px + sampleW, py);
      }
      if (!liquefiedSampleInside(ix, iy + 1, cols, rows, originX, originY, previewW, previewH, minX, minY, shapeW, shapeH, threshold + pulse, softness)) {
        line(px, py + sampleH, px + sampleW, py + sampleH);
      }
    }
  }
}

boolean liquefiedSampleInside(
  int ix,
  int iy,
  int cols,
  int rows,
  float originX,
  float originY,
  float previewW,
  float previewH,
  int minX,
  int minY,
  int shapeW,
  int shapeH,
  float threshold,
  float softness
) {
  if (ix < 0 || iy < 0 || ix >= cols || iy >= rows) return false;

  float px = originX + (ix + 0.5) * (previewW / cols);
  float py = originY + (iy + 0.5) * (previewH / rows);
  float u = map(px, originX, originX + previewW, -0.75, shapeW - 0.25);
  float v = map(py, originY, originY + previewH, -0.95, shapeH - 0.05);
  return liquefiedPreviewDensity(
    u + liquefiedDataFlowX(u, v, minX, minY),
    v + liquefiedDataFlowY(u, v, minX, minY),
    minX,
    minY,
    shapeW,
    shapeH,
    softness
  ) > threshold;
}

float liquefiedPreviewDensity(float localX, float localY, int minX, int minY, int shapeW, int shapeH, float softness) {
  float density = 0;

  int maxX = min(COLS - 1, minX + shapeW - 1);
  int maxY = min(ROWS - 1, minY + shapeH - 1);

  for (int gx = max(0, minX); gx <= maxX; gx++) {
    for (int gy = max(0, minY); gy <= maxY; gy++) {
      if (!sediment[gx][gy].occupied) continue;

      float lx = gx - minX;
      float ly = gy - minY;
      float dx = localX - lx;
      float dy = localY - ly;
      float d2 = dx * dx + dy * dy;
      if (d2 > 10.5) continue;
      float weight = 0.55 + sediment[gx][gy].confidence * 0.25 + sediment[gx][gy].solidity * 0.20;
      density += exp(-d2 * softness) * weight;
    }
  }

  float contourNoise = sin((localX + minX) * 2.35 + frameCount * 0.006) * 0.030
    + cos((localY + minY) * 2.85 - frameCount * 0.004) * 0.025;
  return constrain(density + contourNoise, 0, 1.6);
}

float liquefiedDriveAmount() {
  float voiceDrive = constrain(max(soundLevel, voiceEnvelope), 0, 1);
  float verifyDrive = constrain(machineValidation, 0, 1);
  float misreadDrive = active == null ? constrain(input.conflict, 0, 1) : constrain(active.misread, 0, 1);
  float leftActivity = leftValid ? map(smoothUsL, ULTRASONIC_MAX_CM, ULTRASONIC_MIN_CM, 0, 1) : 0;
  float rightActivity = rightValid ? map(smoothUsR, ULTRASONIC_MAX_CM, ULTRASONIC_MIN_CM, 0, 1) : 0;
  float sensorDrive = constrain(max(leftActivity, rightActivity), 0, 1);

  return constrain(
    0.18 +
    voiceDrive * 0.18 +
    sensorDrive * 0.22 +
    verifyDrive * 0.18 +
    misreadDrive * 0.24,
    0.12,
    0.82
  );
}

float liquefiedSensorBalance() {
  if (leftValid && rightValid) {
    return constrain((smoothUsR - smoothUsL) / max(1.0, ULTRASONIC_MAX_CM - ULTRASONIC_MIN_CM), -1, 1);
  }
  if (leftValid) return -0.42;
  if (rightValid) return 0.42;
  return 0;
}

float liquefiedDataFlowX(float localX, float localY, int minX, int minY) {
  int gx = constrain(round(localX + minX), 0, COLS - 1);
  int gy = constrain(round(localY + minY), 0, ROWS - 1);
  boolean occupied = sediment[gx][gy].occupied;
  int bit = occupied ? traceBit[gx][gy] : 0;
  int visualBit = occupied ? ((sediment[gx][gy].visualCode >> ((gx + gy) % 4)) & 1) : 0;
  float corruption = occupied ? sediment[gx][gy].corruption : 0;
  float bitDirection = bit == 1 ? 1 : -1;
  float visualDirection = visualBit == 1 ? 1 : -1;
  float drive = liquefiedDriveAmount();
  float sensor = liquefiedSensorBalance();
  float wave = sin(localY * 2.18 + frameCount * 0.020 + visualDirection * 0.85);
  float drift = noise((localX + minX) * 0.31, (localY + minY) * 0.43, frameCount * 0.014) - 0.5;

  return drive * (
    sensor * 0.34 +
    bitDirection * 0.10 +
    visualDirection * drift * 0.38 +
    wave * (0.12 + corruption * 0.20)
  );
}

float liquefiedDataFlowY(float localX, float localY, int minX, int minY) {
  int gx = constrain(round(localX + minX), 0, COLS - 1);
  int gy = constrain(round(localY + minY), 0, ROWS - 1);
  boolean occupied = sediment[gx][gy].occupied;
  int bit = occupied ? traceBit[gx][gy] : 0;
  int visualBit = occupied ? ((sediment[gx][gy].visualCode >> ((gx + gy + 1) % 4)) & 1) : 0;
  float confidence = occupied ? sediment[gx][gy].confidence : 0.45;
  float corruption = occupied ? sediment[gx][gy].corruption : 0;
  float bitDirection = bit == 1 ? -1 : 1;
  float visualDirection = visualBit == 1 ? 1 : -1;
  float drive = liquefiedDriveAmount();
  float voicePush = constrain(max(soundLevel, voiceEnvelope), 0, 1);
  float wave = cos(localX * 2.44 - frameCount * 0.018 + bitDirection * 0.72);
  float settling = map(confidence, 0, 1, 0.18, -0.10);

  return drive * (
    settling +
    voicePush * -0.16 +
    bitDirection * 0.08 +
    visualDirection * wave * (0.13 + corruption * 0.24)
  );
}

void drawMachineThinkingLayer(
  float originX,
  float originY,
  float previewW,
  float previewH,
  int minX,
  int minY,
  int shapeW,
  int shapeH
) {
  float drive = liquefiedDriveAmount();
  float sensorBalance = liquefiedSensorBalance();
  float decisionPulse = 0.5 + 0.5 * sin(frameCount * map(drive, 0.12, 0.82, 0.035, 0.082));
  float cellW = previewW / max(1, shapeW);
  float cellH = previewH / max(1, shapeH);

  pushStyle();
  rectMode(CORNER);

  strokeWeight(1.0);
  int thoughtBudget = 0;
  int maxX = min(COLS - 1, minX + shapeW - 1);
  int maxY = min(ROWS - 1, minY + shapeH - 1);

  for (int gx = max(0, minX); gx <= maxX; gx++) {
    for (int gy = max(0, minY); gy <= maxY; gy++) {
      if (!sediment[gx][gy].occupied && liquidMediumTrace[gx][gy] < 0.05) continue;

      float trust = sediment[gx][gy].occupied
        ? sediment[gx][gy].confidence * 0.55 + sediment[gx][gy].solidity * 0.45
        : liquidMediumTrace[gx][gy];
      float corruption = max(sediment[gx][gy].corruption, liquidCorruptionTrace[gx][gy]);
      int bit = sediment[gx][gy].occupied ? traceBit[gx][gy] : (liquidBitTrace[gx][gy] > 0.45 ? 1 : 0);
      int visualBit = sediment[gx][gy].occupied
        ? ((sediment[gx][gy].visualCode >> ((gx + gy + frameCount / 18) % 4)) & 1)
        : (liquidVisualTrace[gx][gy] > 0.45 ? 1 : 0);

      boolean candidate = trust > 0.55 || corruption > 0.20 || bit == 1 || visualBit == 1;
      if (!candidate) continue;

      float localX = gx - minX + 0.5;
      float localY = gy - minY + 0.5;
      float flowX = liquefiedDataFlowX(localX, localY, minX, minY);
      float flowY = liquefiedDataFlowY(localX, localY, minX, minY);
      float px = originX + localX * cellW + (flowX + sensorBalance * 0.16) * cellW;
      float py = originY + localY * cellH + flowY * cellH;
      float gate = noise(gx * 0.29, gy * 0.37, frameCount * 0.018);

      if (gate > map(trust, 0, 1, 0.88, 0.58)) {
        float r = max(2.0, min(cellW, cellH) * map(trust + corruption * 0.6, 0, 1.4, 0.10, 0.34));
        if (corruption > 0.28 || bit == 1) {
          stroke(255, 0, 0, 82 + decisionPulse * 86);
          fill(255, 0, 0, 24 + decisionPulse * 34);
        } else {
          stroke(30, 30, 30, 54 + decisionPulse * 74);
          fill(255, 255, 255, 18 + decisionPulse * 24);
        }
        ellipse(px, py, r * 2.0, r * 2.0);

        float tick = min(cellW, cellH) * 0.42;
        line(px - tick, py, px + tick, py);
        line(px, py - tick, px, py + tick);
      }

      if (thoughtBudget < 14 && gate > 0.68 && (bit == 1 || visualBit == 1 || corruption > 0.25)) {
        noStroke();
        fill(corruption > 0.25 ? color(255, 0, 0, 126) : color(18, 18, 18, 118));
        useMachineFont(constrain(min(cellW, cellH) * 0.28, 6.0, 9.0));
        textAlign(CENTER, CENTER);
        text(bit == 1 ? "1" : "0", px + cellW * 0.38, py - cellH * 0.34);
        thoughtBudget++;
      }
    }
  }

  popStyle();
}

void drawLiquefiedForgettingLayer(
  float originX,
  float originY,
  float previewW,
  float previewH,
  int minX,
  int minY,
  int shapeW,
  int shapeH
) {
  float cellW = previewW / max(1, shapeW);
  float cellH = previewH / max(1, shapeH);
  int cols = constrain(round(previewW / max(3.0, min(cellW, cellH) * 0.24)), 26, 72);
  int rows = constrain(round(previewH / max(3.0, min(cellW, cellH) * 0.24)), 18, 58);
  float sampleW = previewW / cols;
  float sampleH = previewH / rows;
  float time = frameCount * 0.012;
  float voiceActivity = constrain(max(soundLevel, voiceEnvelope), 0, 1);

  pushStyle();
  noStroke();
  rectMode(CENTER);

  for (int ix = 0; ix < cols; ix++) {
    for (int iy = 0; iy < rows; iy++) {
      float px = originX + (ix + 0.5) * sampleW;
      float py = originY + (iy + 0.5) * sampleH;
      float u = map(px, originX, originX + previewW, -0.75, shapeW - 0.25);
      float v = map(py, originY, originY + previewH, -0.95, shapeH - 0.05);
      float density = liquefiedPreviewDensity(u, v, minX, minY, shapeW, shapeH, 2.10);
      if (density < 0.10) continue;

      int gx = constrain(round(u + minX), 0, COLS - 1);
      int gy = constrain(round(v + minY), 0, ROWS - 1);
      float trust = sediment[gx][gy].occupied
        ? sediment[gx][gy].confidence * 0.56 + sediment[gx][gy].solidity * 0.44
        : max(liquidMediumTrace[gx][gy], liquidSlowTrace[gx][gy]) * 0.65;
      float corruption = max(sediment[gx][gy].corruption, liquidCorruptionTrace[gx][gy]);
      float ageFade = sediment[gx][gy].occupied ? constrain(map(sediment[gx][gy].age, 1400, 14000, 0, 1), 0, 1) : 0.35;
      float forgetting = constrain((1.0 - trust) * 0.62 + ageFade * 0.30 + corruption * 0.18 - voiceActivity * 0.20, 0, 1);
      float gate = noise(ix * 0.29, iy * 0.37, time);
      if (gate > forgetting * 0.84 + 0.25) continue;

      float tear = map(forgetting, 0, 1, 0.22, 1.0) * map(density, 0.10, 0.95, 0.45, 1.0);
      float w = sampleW * map(gate, 0, 1, 0.64, 1.80) * tear;
      float h = max(1.0, sampleH * map(forgetting, 0, 1, 0.24, 0.92));
      float alpha = map(forgetting, 0, 1, 12, 92) * map(density, 0.10, 1.0, 0.55, 1.0);

      fill(238, 238, 234, alpha);
      rect(px + (noise(ix * 0.7, time) - 0.5) * sampleW * 0.6, py, w, h);

      if (forgetting > 0.54 && gate < 0.20) {
        fill(255, 255, 255, alpha * 0.46);
        rect(px, py + sampleH * 0.42, w * 0.58, max(1.0, h * 0.42));
      }
    }
  }

  rectMode(CORNER);
  popStyle();
}

void drawLiquefiedIterationLayer(
  float originX,
  float originY,
  float previewW,
  float previewH,
  int minX,
  int minY,
  int shapeW,
  int shapeH
) {
  float cellW = previewW / max(1, shapeW);
  float cellH = previewH / max(1, shapeH);
  float scanPhase = (frameCount * (0.018 + max(soundLevel, machineValidation) * 0.054)) % 1.0;
  int maxX = min(COLS - 1, minX + shapeW - 1);
  int maxY = min(ROWS - 1, minY + shapeH - 1);
  int labelBudget = 0;

  pushStyle();
  rectMode(CORNER);
  textAlign(CENTER, CENTER);
  useMachineFont(constrain(min(cellW, cellH) * 0.26, 6.0, 9.5));

  strokeWeight(1.0);
  for (int gx = max(0, minX); gx <= maxX; gx++) {
    for (int gy = max(0, minY); gy <= maxY; gy++) {
      if (!sediment[gx][gy].occupied && liquidMediumTrace[gx][gy] < 0.06) continue;

      float trust = sediment[gx][gy].occupied
        ? sediment[gx][gy].confidence * 0.58 + sediment[gx][gy].solidity * 0.42
        : liquidMediumTrace[gx][gy];
      float corruption = max(sediment[gx][gy].corruption, liquidCorruptionTrace[gx][gy]);
      int bit = sediment[gx][gy].occupied ? traceBit[gx][gy] : (liquidBitTrace[gx][gy] > 0.45 ? 1 : 0);
      float reRead = constrain((1.0 - trust) * 0.38 + corruption * 0.42 + bit * 0.18 + machineValidation * 0.18, 0, 1);
      float gate = noise(gx * 0.51 + 4.0, gy * 0.47, frameCount * 0.022);
      if (gate < 0.52 + (1.0 - reRead) * 0.22) continue;

      float localX = gx - minX + 0.5;
      float localY = gy - minY + 0.5;
      float flowX = liquefiedDataFlowX(localX, localY, minX, minY);
      float flowY = liquefiedDataFlowY(localX, localY, minX, minY);
      float px = originX + localX * cellW + flowX * cellW * 0.58;
      float py = originY + localY * cellH + flowY * cellH * 0.58;
      float boxW = max(5.0, cellW * map(reRead, 0, 1, 0.28, 0.72));
      float boxH = max(5.0, cellH * map(reRead, 0, 1, 0.20, 0.56));
      float alpha = map(reRead, 0, 1, 34, 150);

      if (bit == 1 || corruption > 0.25) {
        stroke(255, 0, 0, alpha);
        fill(255, 0, 0, alpha * 0.12);
      } else {
        stroke(20, 20, 20, alpha * 0.72);
        fill(255, 255, 255, alpha * 0.08);
      }
      rect(px - boxW * 0.5, py - boxH * 0.5, boxW, boxH);

      float tick = min(cellW, cellH) * 0.32;
      line(px - tick, py, px + tick, py);
      line(px, py - tick, px, py + tick);

      if (labelBudget < 16 && (corruption > 0.24 || gate > 0.82)) {
        noStroke();
        fill(bit == 1 || corruption > 0.25 ? color(255, 0, 0, alpha + 40) : color(20, 20, 20, alpha + 30));
        text("i" + str((gx + gy + int(frameCount / 18)) % 4), px + boxW * 0.68, py - boxH * 0.62);
        labelBudget++;
      }
    }
  }

  noStroke();
  fill(255, 0, 0, 26 + machineValidation * 42);
  float sweepY = originY + previewH * scanPhase;
  rect(originX, sweepY, previewW, max(1.0, cellH * 0.035));

  popStyle();
}

void drawHalftoneXeroxExtractionLayer(
  float originX,
  float originY,
  float previewW,
  float previewH,
  int minX,
  int minY,
  int shapeW,
  int shapeH
) {
  float cell = constrain(min(previewW, previewH) / 22.0, 3.4, 7.4);
  float half = cell * 0.5;
  float cx = originX + previewW * 0.5;
  float cy = originY + previewH * 0.5;
  float diag = sqrt(previewW * previewW + previewH * previewH);
  float angle = radians(45.0);
  float ca = cos(angle);
  float sa = sin(angle);

  pushStyle();
  noStroke();

  for (float gy = -diag * 0.5; gy <= diag * 0.5; gy += cell) {
    for (float gx = -diag * 0.5; gx <= diag * 0.5; gx += cell) {
      float px = cx + gx * ca - gy * sa;
      float py = cy + gx * sa + gy * ca;
      if (px < originX - cell || px > originX + previewW + cell || py < originY - cell || py > originY + previewH + cell) continue;

      float u = map(px, originX, originX + previewW, -0.75, shapeW - 0.25);
      float v = map(py, originY, originY + previewH, -0.95, shapeH - 0.05);
      float density = liquefiedPreviewDensity(u, v, minX, minY, shapeW, shapeH, 2.35);
      float edgeDensity = liquefiedPreviewDensity(u, v, minX, minY, shapeW, shapeH, 1.20);
      float copierNoise = noise(px * 0.040, py * 0.040, frameCount * 0.010);

      if (density < 0.14) {
        if (edgeDensity > 0.06 && copierNoise > 0.985) {
          fill(12, 12, 12, 58);
          ellipse(px, py, 1.1, 1.1);
        }
        continue;
      }

      if (copierNoise < 0.13) continue;

      int gxCell = constrain(round(u + minX), 0, COLS - 1);
      int gyCell = constrain(round(v + minY), 0, ROWS - 1);
      boolean occupied = sediment[gxCell][gyCell].occupied;
      int dataBit = occupied ? traceBit[gxCell][gyCell] : 0;
      int visualBit = occupied ? ((sediment[gxCell][gyCell].visualCode >> ((gxCell + gyCell) % 4)) & 1) : 0;
      float corruption = occupied ? sediment[gxCell][gyCell].corruption : 0;

      // Red extraction points carry the actual weight of the sampled data.
      // Confidence and accumulated solidity dominate; binary state and machine
      // verification reinforce the signal, while uncertain/corrupt cells shrink.
      float signalWeight = 0;
      if (occupied) {
        DataCell sourceCell = sediment[gxCell][gyCell];
        signalWeight = sourceCell.confidence * 0.38
          + sourceCell.solidity * 0.24
          + (dataBit == 1 ? 0.16 : 0)
          + (visualBit == 1 ? 0.08 : 0)
          + (sourceCell.machineVerified ? 0.14 : 0);
        signalWeight *= 1.0 - corruption * 0.42;
        if (sourceCell.lowConfidenceInference) signalWeight *= 0.62;

        // Corruption is still an observable signal, but never reads as strong
        // as a verified, high-confidence binary sample.
        signalWeight = max(signalWeight, corruption * 0.42);
        signalWeight = constrain(signalWeight, 0.05, 1.0);
      }

      float radius = half * sqrt(constrain(map(density, 0.14, 1.15, 0.0, 1.0), 0, 1));
      radius *= map(copierNoise, 0.13, 1.0, 0.62, 1.10);
      if (radius < 0.45) continue;

      boolean redSample = occupied && (dataBit == 1 || visualBit == 1 || corruption > 0.30);
      if (redSample && copierNoise > 0.46) {
        float pulse = 0.94 + sin(frameCount * 0.042 + gxCell * 0.71 + gyCell * 0.43) * 0.06;
        float weightedRadius = radius * map(signalWeight, 0.05, 1.0, 0.42, 1.82) * pulse;
        float weightedAlpha = map(signalWeight, 0.05, 1.0, 58, 224);

        // A restrained halo makes only the strongest samples stand forward.
        if (signalWeight > 0.72) {
          fill(255, 0, 0, map(signalWeight, 0.72, 1.0, 18, 48));
          ellipse(px, py, weightedRadius * 2.9, weightedRadius * 2.9);
        }
        fill(255, 0, 0, weightedAlpha);
        ellipse(px, py, weightedRadius * 2.0, weightedRadius * 2.0);
      } else {
        fill(4, 4, 4, map(density, 0.14, 1.15, 42, 116));
        ellipse(px, py, radius * 2.0, radius * 2.0);
      }
    }
  }

  popStyle();
}

void drawBinaryExtractedSedimentCores(
  float originX,
  float originY,
  float previewW,
  float previewH,
  int minX,
  int minY,
  int shapeW,
  int shapeH
) {
  float cellW = previewW / max(1, shapeW);
  float cellH = previewH / max(1, shapeH);

  noStroke();
  rectMode(CENTER);

  for (int gx = max(0, minX); gx <= min(COLS - 1, minX + shapeW - 1); gx++) {
    for (int gy = max(0, minY); gy <= min(ROWS - 1, minY + shapeH - 1); gy++) {
      if (!sediment[gx][gy].occupied) continue;

      float localX = gx - minX + 0.5;
      float localY = gy - minY + 0.5;
      float px = originX + localX * cellW;
      float py = originY + localY * cellH;
      float trust = sediment[gx][gy].confidence * 0.55 + sediment[gx][gy].solidity * 0.45;
      float corruption = sediment[gx][gy].corruption;
      int bit = traceBit[gx][gy];

      float coreW = cellW * map(trust, 0, 1, 0.34, 0.66);
      float coreH = cellH * map(trust, 0, 1, 0.34, 0.66);
      float offset = (bit == 1 ? 1 : -1) * min(cellW, cellH) * 0.05;

      fill(18, 18, 18, map(trust, 0, 1, 58, 138));
      rect(px + offset, py, coreW, coreH);

      if (bit == 1 || corruption > 0.18) {
        fill(52, 52, 52, 82);
        rect(px - offset * 0.7, py + offset * 0.5, coreW * 0.45, coreH * 0.45);
      }
    }
  }

  rectMode(CORNER);
}

void drawBinaryExtractedSamplingTrace(
  float originX,
  float originY,
  float previewW,
  float previewH,
  int minX,
  int minY,
  int shapeW,
  int shapeH
) {
  int samples = constrain(round(min(previewW, previewH) / 5.0), LIQUEFIED_SAMPLE_MIN_SAMPLES, LIQUEFIED_SAMPLE_MAX_SAMPLES);
  float step = min(previewW, previewH) / samples;
  float sampleW = previewW / ceil(previewW / step);
  float sampleH = previewH / ceil(previewH / step);
  float pulse = 0.55 + 0.45 * sin(frameCount * 0.032);

  noStroke();

  for (float px = originX; px < originX + previewW; px += sampleW) {
    for (float py = originY; py < originY + previewH; py += sampleH) {
      float u = map(px + sampleW * 0.5, originX, originX + previewW, -0.75, shapeW - 0.25);
      float v = map(py + sampleH * 0.5, originY, originY + previewH, -0.95, shapeH - 0.05);
      float outerDensity = liquefiedPreviewDensity(u, v, minX, minY, shapeW, shapeH, 1.35);
      float coreDensity = liquefiedPreviewDensity(u, v, minX, minY, shapeW, shapeH, 3.35);

      boolean edgeSample = outerDensity > 0.16 && coreDensity < 0.74;
      boolean binarySample = extractedBinarySampleAt(u, v, minX, minY);
      if (!edgeSample && !binarySample) continue;

      float noiseGate = noise(px * 0.034, py * 0.034, frameCount * 0.012);
      if (noiseGate < (binarySample ? 0.46 : 0.68)) continue;

      float alpha = binarySample ? 118 : 58;
      alpha *= map(constrain(outerDensity, 0.16, 0.95), 0.16, 0.95, 0.45, 0.82);
      float s = max(1.2, min(sampleW, sampleH) * (binarySample ? 0.42 : 0.30));

      if (binarySample) {
        fill(255, 0, 0, alpha * (0.72 + pulse * 0.18));
      } else {
        fill(220, 220, 220, alpha * 0.42);
      }
      rect(px + sampleW * 0.5 - s * 0.5, py + sampleH * 0.5 - s * 0.5, s, s);
    }
  }
}

void drawBinaryExtractionLabels(
  float originX,
  float originY,
  float previewW,
  float previewH,
  int minX,
  int minY,
  int shapeW,
  int shapeH
) {
  float cellW = previewW / max(1, shapeW);
  float cellH = previewH / max(1, shapeH);
  float labelSize = constrain(min(cellW, cellH) * 0.34, 7.0, 12.0);
  int labelBudget = 0;

  pushStyle();
  rectMode(CORNER);
  textAlign(CENTER, CENTER);
  useMachineFont(labelSize);

  for (int gx = max(0, minX); gx <= min(COLS - 1, minX + shapeW - 1); gx++) {
    for (int gy = max(0, minY); gy <= min(ROWS - 1, minY + shapeH - 1); gy++) {
      if (!sediment[gx][gy].occupied && liquidBitTrace[gx][gy] < 0.04 && liquidVisualTrace[gx][gy] < 0.04) continue;

      float localX = gx - minX + 0.5;
      float localY = gy - minY + 0.5;
      float px = originX + localX * cellW;
      float py = originY + localY * cellH;
      float flowX = liquefiedDataFlowX(localX, localY, minX, minY);
      float flowY = liquefiedDataFlowY(localX, localY, minX, minY);
      px += flowX * cellW * 0.62;
      py += flowY * cellH * 0.62;

      int bit = sediment[gx][gy].occupied ? traceBit[gx][gy] : (liquidBitTrace[gx][gy] > 0.45 ? 1 : 0);
      int visualBit = sediment[gx][gy].occupied ? ((sediment[gx][gy].visualCode >> ((gx + gy) % 4)) & 1) : (liquidVisualTrace[gx][gy] > 0.45 ? 1 : 0);
      float trust = sediment[gx][gy].occupied ? sediment[gx][gy].confidence * 0.55 + sediment[gx][gy].solidity * 0.45 : max(liquidMediumTrace[gx][gy], liquidSlowTrace[gx][gy]);
      float corruption = max(sediment[gx][gy].corruption, liquidCorruptionTrace[gx][gy]);
      boolean extractionSite = bit == 1 || visualBit == 1 || corruption > 0.28 || trust > 0.62;
      if (!extractionSite) continue;

      float boxW = max(7.0, cellW * 0.42);
      float boxH = max(7.0, cellH * 0.36);
      float alpha = map(constrain(trust + corruption * 0.55, 0.18, 1.15), 0.18, 1.15, 64, 168);
      boolean hotBit = bit == 1 || corruption > 0.30;

      noFill();
      if (hotBit) {
        stroke(255, 0, 0, alpha);
      } else {
        stroke(18, 18, 18, alpha * 0.76);
      }
      strokeWeight(1.0);
      rect(px - boxW * 0.5, py - boxH * 0.5, boxW, boxH);

      if (labelBudget < 18 && ((gx + gy + frameCount / 24) % 3 != 0 || corruption > 0.32)) {
        if (hotBit) {
          fill(255, 0, 0, alpha + 45);
        } else {
          fill(20, 20, 20, alpha + 50);
        }
        noStroke();
        text(str(bit), px + boxW * 0.62, py - boxH * 0.62);
        labelBudget++;
      }
    }
  }

  popStyle();
}

boolean extractedBinarySampleAt(float localX, float localY, int minX, int minY) {
  int gx = constrain(round(localX + minX), 0, COLS - 1);
  int gy = constrain(round(localY + minY), 0, ROWS - 1);
  if (!sediment[gx][gy].occupied) return false;

  int bit = traceBit[gx][gy];
  int visualBit = ((sediment[gx][gy].visualCode >> ((gx + gy) % 4)) & 1);
  float trust = sediment[gx][gy].confidence * 0.62 + sediment[gx][gy].solidity * 0.38;
  float unstable = sediment[gx][gy].corruption;
  return bit == 1 || (visualBit == 1 && trust > 0.44) || trust > 0.74 || unstable > 0.34;
}

String machineStatusText() {
  if (unattendedMode) return "INFERENCE";
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
    drawFittedBinaryBlockAsset(previewCode, x - ui(4), y + ui(4), ui(96), ui(88));
    popStyle();
    return;
  }

  float unit = ui(20);
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
  float offsetX = x + ui(32) - previewW * 0.5 - minCellX * unit;
  float offsetY = y + ui(42) - previewH * 0.5 - minCellY * unit;

  for (int i = 0; i < preview.length; i++) {
    float px = offsetX + preview[i][0] * unit;
    float py = offsetY + preview[i][1] * unit;
    fill(232, 248, 255, 215);
    rect(px, py, unit - ui(3), unit - ui(3));
  }
  popStyle();
}
