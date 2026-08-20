#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include "MAX30105.h"
#include "Adafruit_Thermal.h"

// ============================================================
// PROBIFORM SENSOR + DUAL LCD + THERMAL PRINTER SYSTEM
// Arduino Mega 2560
// ============================================================

// ================= LCD Settings =================

// LCD 1: Sensor / inference data
// LCD 2: Printer process
//
// Important:
// The two displays must use different I2C addresses.
const byte DATA_LCD_ADDRESS = 0x27;
const byte PRINT_LCD_ADDRESS = 0x26;

const int LCD_COLS = 20;
const int LCD_ROWS = 4;

LiquidCrystal_I2C dataLCD(
  DATA_LCD_ADDRESS,
  LCD_COLS,
  LCD_ROWS
);

LiquidCrystal_I2C printLCD(
  PRINT_LCD_ADDRESS,
  LCD_COLS,
  LCD_ROWS
);

unsigned long lastDataLCDUpdate = 0;
unsigned long lastPrintLCDUpdate = 0;

const unsigned long DATA_LCD_INTERVAL = 350;
const unsigned long PRINT_LCD_INTERVAL = 250;

// ================= Pins =================

const int TRIG_L = 2;
const int ECHO_L = 3;

const int TRIG_R = 4;
const int ECHO_R = 5;

const int MIC_FL = A0; // MAX9814 front left
const int MIC_FR = A1; // MAX9814 front right
const int MIC_BL = A2; // KY038 back left
const int MIC_BR = A3; // KY038 back right

const int RELAY_PIN = 22; // LD2410 power relay
// Swap these two levels if your relay board is active LOW.
const byte LD2410_POWER_ON_LEVEL = HIGH;
const byte LD2410_POWER_OFF_LEVEL = LOW;

// Arduino Mega serial ports:
//
// Serial  = USB to Processing
// Serial1 = thermal printer TTL serial
// Serial2 = LD2410
const long USB_BAUD = 115200;
const long PRINTER_BAUD = 9600;
const long LD2410_BAUD = 256000;

// ================= Thermal Printer =================

Adafruit_Thermal printer(&Serial1);

String usbCommand = "";

unsigned long lastPrinterActionTime = 0;
const unsigned long PRINTER_MIN_GAP_MS = 3500;

const int PRINT_BITMAP_MAX_W = 192;
const int PRINT_BITMAP_MAX_H = 128;

const int PRINT_BITMAP_MAX_BYTES =
  (PRINT_BITMAP_MAX_W / 8) * PRINT_BITMAP_MAX_H;

byte printBitmapBuffer[PRINT_BITMAP_MAX_BYTES];

bool receivingBitmap = false;

int bitmapW = 0;
int bitmapH = 0;
int bitmapRowBytes = 0;
int bitmapCurrentRow = 0;

bool bitmapPrintActive = false;

const unsigned long BITMAP_BAND_COOLDOWN_MS = 180;
const unsigned long BITMAP_FINAL_SETTLE_MS = 3000;

// Thermal printer heat configuration
const byte THERMAL_HEAT_DOTS = 11;
const byte THERMAL_HEAT_TIME = 160;
const byte THERMAL_HEAT_INTERVAL = 60;

// ================= Printer Display State =================

enum PrinterState {
  PRINTER_IDLE,
  PRINTER_READY,
  PRINTER_RECEIVING,
  PRINTER_PRINTING,
  PRINTER_COMPLETE,
  PRINTER_BUSY_STATE,
  PRINTER_ERROR
};

PrinterState printerDisplayState = PRINTER_IDLE;

int printerProgressCurrent = 0;
int printerProgressTotal = 0;

String printerMessage = "WAITING";
unsigned long printerStateChangedTime = 0;

// ================= Heart Sensor =================

MAX30105 heartSensor;

bool heartFound = false;

const long HEART_THRESHOLD = 25000;

// ================= System State =================

bool systemActive = false;
bool systemHasStartedOnce = false;

unsigned long startTime = 0;
unsigned long lastPrintTime = 0;
unsigned long lastHumanActivityTime = 0;
unsigned long ldPowerOnTime = 0;
unsigned long lastIdleUltrasonicReadTime = 0;
byte idleUltrasonicConfirmations = 0;

const unsigned long PRINT_INTERVAL = 500;
const unsigned long AUTO_SLEEP_TIMEOUT_MS = 3UL * 60UL * 1000UL;
const unsigned long LD2410_WARMUP_MS = 2500;
const unsigned long IDLE_ULTRASONIC_INTERVAL_MS = 350;
const byte IDLE_ULTRASONIC_CONFIRMATION_SAMPLES = 3;
const bool AUTO_SLEEP_ENABLED = true;

// ================= Cached Sensor Values =================

// These variables store the latest sensor readings.
// The LCD reads these values instead of reading sensors again.

long latestIR = 0;

long latestUsL = -1;
long latestUsR = -1;

int latestMicFL = 0;
int latestMicFR = 0;
int latestMicBL = 0;
int latestMicBR = 0;

byte latestLDTargetState = 0;

int latestLDMovingDistance = 0;
byte latestLDMovingEnergy = 0;

int latestLDStationaryDistance = 0;
byte latestLDStationaryEnergy = 0;

// ================= PMSD State =================
//
// P = Presence
// M = Motion
// S = Sound
// D = Distance

bool pmsdPresence = false;
bool pmsdMotion = false;
bool pmsdSound = false;
bool pmsdDistance = false;

// Adjust these after testing your sensors.
const int SOUND_DISPLAY_THRESHOLD = 5;
const int LD_MOTION_THRESHOLD = 5;

const int DISTANCE_MIN_CM = 5;
const int DISTANCE_MAX_CM = 30;

// ================= Mic Settings =================

const int MIC_SAMPLE_COUNT = 80;
const int MIC_SAMPLE_DELAY_US = 300;

// ================= LD2410 Frame State =================

byte ldFrame[48];

int ldFramePos = 0;
int ldExpectedLength = 0;

byte ldTargetState = 0;

int ldMovingDistance = 0;
byte ldMovingEnergy = 0;

int ldStationaryDistance = 0;
byte ldStationaryEnergy = 0;

unsigned long ldLastValidFrameTime = 0;

// ============================================================
// LCD UTILITIES
// ============================================================

void lcdPrintLine(
  LiquidCrystal_I2C &lcd,
  byte row,
  String text
) {
  if (text.length() > LCD_COLS) {
    text = text.substring(0, LCD_COLS);
  }

  while (text.length() < LCD_COLS) {
    text += " ";
  }

  lcd.setCursor(0, row);
  lcd.print(text);
}

String formatDistance(long distanceValue) {
  if (distanceValue < 0) {
    return "--";
  }

  return String(distanceValue);
}

String makeProgressBar(
  int current,
  int total,
  int width
) {
  String result = "[";

  if (total <= 0) {
    for (int i = 0; i < width; i++) {
      result += "-";
    }

    result += "]";
    return result;
  }

  int filled = map(
    constrain(current, 0, total),
    0,
    total,
    0,
    width
  );

  for (int i = 0; i < width; i++) {
    if (i < filled) {
      result += "#";
    } else {
      result += "-";
    }
  }

  result += "]";
  return result;
}

void setPrinterDisplayState(
  PrinterState newState,
  String message
) {
  printerDisplayState = newState;
  printerMessage = message;
  printerStateChangedTime = millis();

  // Force immediate LCD update.
  lastPrintLCDUpdate = 0;
}

// ============================================================
// PMSD CALCULATION
// ============================================================

void updatePMSDState() {
  pmsdPresence =
    systemActive &&
    (
      latestIR > HEART_THRESHOLD ||
      latestLDTargetState > 0
    );

  pmsdMotion =
    latestLDMovingEnergy >= LD_MOTION_THRESHOLD ||
    latestLDTargetState == 1 ||
    latestLDTargetState == 3;

  int strongestVoiceMic = max(
    latestMicBL,
    latestMicBR
  );

  pmsdSound =
    strongestVoiceMic >= SOUND_DISPLAY_THRESHOLD;

  bool leftValid =
    latestUsL >= DISTANCE_MIN_CM &&
    latestUsL <= DISTANCE_MAX_CM;

  bool rightValid =
    latestUsR >= DISTANCE_MIN_CM &&
    latestUsR <= DISTANCE_MAX_CM;

  pmsdDistance = leftValid || rightValid;
}

String getPMSDCode() {
  String code = "";

  code += pmsdPresence ? "1" : "0";
  code += pmsdMotion ? "1" : "0";
  code += pmsdSound ? "1" : "0";
  code += pmsdDistance ? "1" : "0";

  return code;
}

// ============================================================
// DATA LCD
// ============================================================

void updateDataLCD() {
  if (
    millis() - lastDataLCDUpdate <
    DATA_LCD_INTERVAL
  ) {
    return;
  }

  lastDataLCDUpdate = millis();

  updatePMSDState();

  if (!heartFound) {
    lcdPrintLine(
      dataLCD,
      0,
      "PROBIFORM / ERROR"
    );

    lcdPrintLine(
      dataLCD,
      1,
      "MAX30102 MISSING"
    );

    lcdPrintLine(
      dataLCD,
      2,
      "CHECK SDA / SCL"
    );

    lcdPrintLine(
      dataLCD,
      3,
      "SYSTEM INCOMPLETE"
    );

    return;
  }

  if (!systemActive) {
    lcdPrintLine(
      dataLCD,
      0,
      "PROBIFORM / IDLE"
    );

    lcdPrintLine(
      dataLCD,
      1,
      "WAITING FOR BODY"
    );

    lcdPrintLine(
      dataLCD,
      2,
      systemHasStartedOnce
        ? "L:" + formatDistance(latestUsL) +
          " R:" + formatDistance(latestUsR) + "cm"
        : "IR: " + String(latestIR)
    );

    lcdPrintLine(
      dataLCD,
      3,
      systemHasStartedOnce
        ? "APPROACH 5-30CM"
        : "TOUCH HEART SENSOR"
    );

    return;
  }

  String pmsdLine =
    "PMSD " +
    getPMSDCode() +
    "  BODY:ACTIVE";

  lcdPrintLine(
    dataLCD,
    0,
    pmsdLine
  );

  String distanceLine =
    "L:" +
    formatDistance(latestUsL) +
    "cm R:" +
    formatDistance(latestUsR) +
    "cm";

  lcdPrintLine(
    dataLCD,
    1,
    distanceLine
  );

  String soundLine =
    "SND " +
    String(latestMicBL) +
    "/" +
    String(latestMicBR) +
    " M:" +
    String(latestLDMovingEnergy);

  lcdPrintLine(
    dataLCD,
    2,
    soundLine
  );

  unsigned long elapsedSeconds =
    (millis() - startTime) / 1000;

  String runtimeLine =
    "TRACE TIME " +
    String(elapsedSeconds) +
    "s";

  lcdPrintLine(
    dataLCD,
    3,
    runtimeLine
  );
}

// ============================================================
// PRINTER LCD
// ============================================================

void updatePrintLCD(bool forceUpdate = false) {
  if (
    !forceUpdate &&
    millis() - lastPrintLCDUpdate <
    PRINT_LCD_INTERVAL
  ) {
    return;
  }

  lastPrintLCDUpdate = millis();

  switch (printerDisplayState) {
    case PRINTER_IDLE:
      lcdPrintLine(
        printLCD,
        0,
        "PROBIFORM ARCHIVE"
      );

      lcdPrintLine(
        printLCD,
        1,
        "OUTPUT DEVICE READY"
      );

      lcdPrintLine(
        printLCD,
        2,
        "NO ACTIVE TRACE"
      );

      lcdPrintLine(
        printLCD,
        3,
        "STATUS: IDLE"
      );
      break;

    case PRINTER_READY:
      lcdPrintLine(
        printLCD,
        0,
        "ARCHIVE TERMINAL"
      );

      lcdPrintLine(
        printLCD,
        1,
        "PRINTER CONNECTED"
      );

      lcdPrintLine(
        printLCD,
        2,
        "WAITING FOR DATA"
      );

      lcdPrintLine(
        printLCD,
        3,
        "STATUS: READY"
      );
      break;

    case PRINTER_RECEIVING: {
      lcdPrintLine(
        printLCD,
        0,
        "RECEIVING TRACE"
      );

      String rowLine =
        "ROW " +
        String(printerProgressCurrent) +
        "/" +
        String(printerProgressTotal);

      lcdPrintLine(
        printLCD,
        1,
        rowLine
      );

      String bar = makeProgressBar(
        printerProgressCurrent,
        printerProgressTotal,
        16
      );

      lcdPrintLine(
        printLCD,
        2,
        bar
      );

      lcdPrintLine(
        printLCD,
        3,
        "DATA MATERIALISING"
      );
      break;
    }

    case PRINTER_PRINTING: {
      lcdPrintLine(
        printLCD,
        0,
        "PRINTING TRACE"
      );

      String bandLine =
        "BAND " +
        String(printerProgressCurrent) +
        "/" +
        String(printerProgressTotal);

      lcdPrintLine(
        printLCD,
        1,
        bandLine
      );

      String bar = makeProgressBar(
        printerProgressCurrent,
        printerProgressTotal,
        16
      );

      lcdPrintLine(
        printLCD,
        2,
        bar
      );

      lcdPrintLine(
        printLCD,
        3,
        "ARCHIVING BODY..."
      );
      break;
    }

    case PRINTER_COMPLETE:
      lcdPrintLine(
        printLCD,
        0,
        "TRACE ARCHIVED"
      );

      lcdPrintLine(
        printLCD,
        1,
        "OUTPUT COMPLETE"
      );

      lcdPrintLine(
        printLCD,
        2,
        "PHYSICAL MEMORY"
      );

      lcdPrintLine(
        printLCD,
        3,
        "STATUS: COMPLETE"
      );
      break;

    case PRINTER_BUSY_STATE:
      lcdPrintLine(
        printLCD,
        0,
        "ARCHIVE OCCUPIED"
      );

      lcdPrintLine(
        printLCD,
        1,
        "PRINTER IS BUSY"
      );

      lcdPrintLine(
        printLCD,
        2,
        "REQUEST REJECTED"
      );

      lcdPrintLine(
        printLCD,
        3,
        "PLEASE WAIT"
      );
      break;

    case PRINTER_ERROR:
      lcdPrintLine(
        printLCD,
        0,
        "ARCHIVE ERROR"
      );

      lcdPrintLine(
        printLCD,
        1,
        printerMessage
      );

      lcdPrintLine(
        printLCD,
        2,
        "TRACE INCOMPLETE"
      );

      lcdPrintLine(
        printLCD,
        3,
        "CHECK DATA STREAM"
      );
      break;
  }
}

void updatePrinterStateTimeout() {
  if (
    printerDisplayState == PRINTER_COMPLETE &&
    millis() - printerStateChangedTime > 6000
  ) {
    setPrinterDisplayState(
      PRINTER_READY,
      "READY"
    );
  }

  if (
    printerDisplayState == PRINTER_BUSY_STATE &&
    millis() - printerStateChangedTime > 3000
  ) {
    setPrinterDisplayState(
      PRINTER_READY,
      "READY"
    );
  }

  if (
    printerDisplayState == PRINTER_ERROR &&
    millis() - printerStateChangedTime > 6000
  ) {
    setPrinterDisplayState(
      PRINTER_READY,
      "READY"
    );
  }
}

// ============================================================
// THERMAL PRINTER
// ============================================================

void applyThermalPrintQuality() {
  printer.setHeatConfig(
    THERMAL_HEAT_DOTS,
    THERMAL_HEAT_TIME,
    THERMAL_HEAT_INTERVAL
  );
}

void setupThermalPrinter() {
  Serial1.begin(PRINTER_BAUD);

  printer.begin();
  printer.setDefault();
  printer.wake();

  applyThermalPrintQuality();

  setPrinterDisplayState(
    PRINTER_READY,
    "READY"
  );
}

bool printerReadyForNewJob() {
  return
    lastPrinterActionTime == 0 ||
    millis() - lastPrinterActionTime >=
      PRINTER_MIN_GAP_MS;
}

void printThermalTestShape() {
  if (!printerReadyForNewJob()) {
    Serial.println(F("PRINTER BUSY"));

    setPrinterDisplayState(
      PRINTER_BUSY_STATE,
      "PRINTER BUSY"
    );

    return;
  }

  lastPrinterActionTime = millis();

  setPrinterDisplayState(
    PRINTER_PRINTING,
    "TEST PRINT"
  );

  printerProgressCurrent = 0;
  printerProgressTotal = 1;

  updatePrintLCD(true);

  Serial.println(F("PRINT_TEST RECEIVED"));

  printer.wake();
  printer.setDefault();
  applyThermalPrintQuality();

  printer.justify('C');

  printer.boldOn();
  printer.println(F("PROBIFORM"));
  printer.boldOff();

  printer.println(F("LIQUEFIED FORM TEST"));
  printer.println();

  printer.justify('L');

  printer.println(F("      ..............      "));
  printer.println(F("   ....##########....     "));
  printer.println(F("  ...##############...    "));
  printer.println(F(" ....####......####....   "));
  printer.println(F(" ...###..........###...   "));
  printer.println(F(" ....####......####....   "));
  printer.println(F("  ...##############...    "));
  printer.println(F("   ....##########....     "));
  printer.println(F("      ..............      "));

  printer.feed(3);
  printer.sleep();

  printerProgressCurrent = 1;

  setPrinterDisplayState(
    PRINTER_COMPLETE,
    "TEST COMPLETE"
  );

  updatePrintLCD(true);

  Serial.println(F("PRINT_TEST DONE"));
}

void resetBitmapReceive() {
  receivingBitmap = false;

  bitmapW = 0;
  bitmapH = 0;

  bitmapRowBytes = 0;
  bitmapCurrentRow = 0;
}

int hexNibble(char c) {
  if (c >= '0' && c <= '9') {
    return c - '0';
  }

  if (c >= 'A' && c <= 'F') {
    return c - 'A' + 10;
  }

  if (c >= 'a' && c <= 'f') {
    return c - 'a' + 10;
  }

  return -1;
}

bool bitmapPixelIsBlack(
  int x,
  int y
) {
  if (
    x < 0 ||
    x >= bitmapW ||
    y < 0 ||
    y >= bitmapH
  ) {
    return false;
  }

  int rowOffset =
    y * bitmapRowBytes;

  int byteIndex =
    rowOffset + x / 8;

  int mask =
    0x80 >> (x % 8);

  return
    (printBitmapBuffer[byteIndex] & mask) != 0;
}

void startEscStarBitmapMode() {
  Serial1.write(27);
  Serial1.write('@');

  Serial1.write(27);
  Serial1.write('3');

  // One line feed equals one 8-dot image band.
  Serial1.write((byte)8);

  Serial1.flush();
}

void printEscStarBitmapBand(int yBand) {
  Serial1.write(27);
  Serial1.write('*');

  // 8-dot single-density mode
  Serial1.write((byte)0);

  Serial1.write(
    (byte)(bitmapW & 0xFF)
  );

  Serial1.write(
    (byte)((bitmapW >> 8) & 0xFF)
  );

  // ESC-* expects vertical columns.
  for (int x = 0; x < bitmapW; x++) {
    byte columnBits = 0;

    for (int bit = 0; bit < 8; bit++) {
      if (
        bitmapPixelIsBlack(
          x,
          yBand + bit
        )
      ) {
        columnBits |=
          1 << (7 - bit);
      }
    }

    Serial1.write(columnBits);
  }

  Serial1.write('\n');
  Serial1.flush();
}

void printReceivedBitmap() {
  if (bitmapPrintActive) {
    Serial.println(F("PRINTER BUSY"));

    setPrinterDisplayState(
      PRINTER_BUSY_STATE,
      "PRINTER BUSY"
    );

    return;
  }

  if (!printerReadyForNewJob()) {
    Serial.println(F("PRINTER BUSY"));

    setPrinterDisplayState(
      PRINTER_BUSY_STATE,
      "PRINTER BUSY"
    );

    return;
  }

  lastPrinterActionTime = millis();

  Serial.println(F("PRINT_BITMAP RECEIVED"));

  printer.wake();
  printer.setDefault();

  applyThermalPrintQuality();

  printer.justify('L');

  bitmapPrintActive = true;

  int totalBands =
    (bitmapH + 7) / 8;

  printerProgressCurrent = 0;
  printerProgressTotal = totalBands;

  setPrinterDisplayState(
    PRINTER_PRINTING,
    "PRINTING"
  );

  updatePrintLCD(true);

  startEscStarBitmapMode();

  int currentBand = 0;

  for (
    int yBand = 0;
    yBand < bitmapH;
    yBand += 8
  ) {
    printEscStarBitmapBand(yBand);

    currentBand++;

    printerProgressCurrent =
      currentBand;

    // Update the printer LCD during printing.
    updatePrintLCD(true);

    delay(BITMAP_BAND_COOLDOWN_MS);
  }

  Serial1.write(27);
  Serial1.write('2');

  // Restore default line spacing.
  Serial1.flush();

  printer.feed(3);

  setPrinterDisplayState(
    PRINTER_COMPLETE,
    "OUTPUT COMPLETE"
  );

  updatePrintLCD(true);

  delay(BITMAP_FINAL_SETTLE_MS);

  printer.sleep();

  Serial.println(F("PRINT_BITMAP DONE"));

  bitmapPrintActive = false;
}

void beginBitmapReceive(String cmd) {
  if (bitmapPrintActive) {
    Serial.println(F("PRINTER BUSY"));

    setPrinterDisplayState(
      PRINTER_BUSY_STATE,
      "PRINTER BUSY"
    );

    return;
  }

  int firstSpace =
    cmd.indexOf(' ');

  int secondSpace =
    cmd.indexOf(
      ' ',
      firstSpace + 1
    );

  if (
    firstSpace < 0 ||
    secondSpace < 0
  ) {
    Serial.println(
      F("PRINT_BITMAP BAD HEADER")
    );

    setPrinterDisplayState(
      PRINTER_ERROR,
      "BAD HEADER"
    );

    return;
  }

  int requestedW =
    cmd.substring(
      firstSpace + 1,
      secondSpace
    ).toInt();

  int requestedH =
    cmd.substring(
      secondSpace + 1
    ).toInt();

  if (
    requestedW <= 0 ||
    requestedH <= 0 ||
    requestedW > PRINT_BITMAP_MAX_W ||
    requestedH > PRINT_BITMAP_MAX_H ||
    requestedW % 8 != 0
  ) {
    Serial.println(
      F("PRINT_BITMAP BAD SIZE")
    );

    setPrinterDisplayState(
      PRINTER_ERROR,
      "BAD IMAGE SIZE"
    );

    return;
  }

  bitmapW = requestedW;
  bitmapH = requestedH;

  bitmapRowBytes =
    bitmapW / 8;

  bitmapCurrentRow = 0;
  receivingBitmap = true;

  printerProgressCurrent = 0;
  printerProgressTotal = bitmapH;

  setPrinterDisplayState(
    PRINTER_RECEIVING,
    "RECEIVING"
  );

  updatePrintLCD(true);

  Serial.print(
    F("PRINT_BITMAP READY ")
  );

  Serial.print(bitmapW);
  Serial.print(F("x"));
  Serial.println(bitmapH);
}

void processBitmapLine(String line) {
  line.trim();

  if (line == "END_BITMAP") {
    if (
      bitmapCurrentRow ==
      bitmapH
    ) {
      printReceivedBitmap();
    } else {
      Serial.print(
        F("PRINT_BITMAP INCOMPLETE rows=")
      );

      Serial.println(
        bitmapCurrentRow
      );

      setPrinterDisplayState(
        PRINTER_ERROR,
        "DATA INCOMPLETE"
      );
    }

    resetBitmapReceive();
    return;
  }

  if (
    bitmapCurrentRow >= bitmapH ||
    line.length() <
      bitmapRowBytes * 2
  ) {
    Serial.println(
      F("PRINT_BITMAP BAD ROW")
    );

    setPrinterDisplayState(
      PRINTER_ERROR,
      "BAD BITMAP ROW"
    );

    resetBitmapReceive();
    return;
  }

  int offset =
    bitmapCurrentRow *
    bitmapRowBytes;

  for (
    int i = 0;
    i < bitmapRowBytes;
    i++
  ) {
    int hi =
      hexNibble(
        line.charAt(i * 2)
      );

    int lo =
      hexNibble(
        line.charAt(i * 2 + 1)
      );

    if (
      hi < 0 ||
      lo < 0
    ) {
      Serial.println(
        F("PRINT_BITMAP BAD HEX")
      );

      setPrinterDisplayState(
        PRINTER_ERROR,
        "BAD HEX DATA"
      );

      resetBitmapReceive();
      return;
    }

    printBitmapBuffer[
      offset + i
    ] = byte(
      (hi << 4) | lo
    );
  }

  bitmapCurrentRow++;

  printerProgressCurrent =
    bitmapCurrentRow;

  updatePrintLCD();
}

void printSystemStatus() {
  if (!printerReadyForNewJob()) {
    Serial.println(F("PRINTER BUSY"));

    setPrinterDisplayState(
      PRINTER_BUSY_STATE,
      "PRINTER BUSY"
    );

    return;
  }

  lastPrinterActionTime = millis();

  setPrinterDisplayState(
    PRINTER_PRINTING,
    "STATUS PRINT"
  );

  printerProgressCurrent = 0;
  printerProgressTotal = 1;

  updatePrintLCD(true);

  Serial.println(
    F("PRINT_STATUS RECEIVED")
  );

  printer.wake();
  printer.setDefault();

  applyThermalPrintQuality();

  printer.justify('L');
  printer.setSize('M');
  printer.boldOn();

  printer.println(
    F("PROBIFORM STATUS")
  );

  printer.print(F("active: "));

  printer.println(
    systemActive ?
    F("yes") :
    F("no")
  );

  printer.print(F("heart: "));

  printer.println(
    heartFound ?
    F("found") :
    F("missing")
  );

  printer.print(F("PMSD: "));
  printer.println(getPMSDCode());

  printer.boldOff();
  printer.setSize('S');

  printer.feed(2);
  printer.sleep();

  printerProgressCurrent = 1;

  setPrinterDisplayState(
    PRINTER_COMPLETE,
    "STATUS COMPLETE"
  );

  updatePrintLCD(true);

  Serial.println(
    F("PRINT_STATUS DONE")
  );
}

// ============================================================
// SYSTEM START / STOP FORWARD DECLARATIONS
// ============================================================

void startSystem();
void stopSystem();

// ============================================================
// USB COMMANDS
// ============================================================

void processUsbCommand(String cmd) {
  cmd.trim();

  if (cmd.length() == 0) {
    return;
  }

  if (receivingBitmap) {
    processBitmapLine(cmd);
    return;
  }

  cmd.toUpperCase();

  if (cmd == "PRINT_TEST") {
    printThermalTestShape();
  }
  else if (
    cmd.startsWith("PRINT_BITMAP ")
  ) {
    beginBitmapReceive(cmd);
  }
  else if (
    cmd == "PRINT_STATUS"
  ) {
    printSystemStatus();
  }
  else if (
    cmd == "STOP_SYSTEM" ||
    cmd == "STOP"
  ) {
    if (systemActive) {
      stopSystem();
    } else {
      Serial.println(
        F("SYSTEM ALREADY STOPPED")
      );
    }
  }
}

void readUsbCommands() {
  while (Serial.available() > 0) {
    char c =
      char(Serial.read());

    if (
      c == '\n' ||
      c == '\r'
    ) {
      processUsbCommand(
        usbCommand
      );

      usbCommand = "";
    }
    else if (
      usbCommand.length() < 80
    ) {
      usbCommand += c;
    }
  }
}

// ============================================================
// ULTRASONIC
// ============================================================

long readUltrasonicCM(
  int trigPin,
  int echoPin
) {
  digitalWrite(
    trigPin,
    LOW
  );

  delayMicroseconds(3);

  digitalWrite(
    trigPin,
    HIGH
  );

  delayMicroseconds(10);

  digitalWrite(
    trigPin,
    LOW
  );

  long duration =
    pulseIn(
      echoPin,
      HIGH,
      30000
    );

  if (duration == 0) {
    return -1;
  }

  long distance =
    duration * 0.034 / 2;

  return distance;
}

// ============================================================
// MICROPHONES
// ============================================================

int readMicPeak(int pin) {
  int minVal = 1023;
  int maxVal = 0;

  for (
    int i = 0;
    i < MIC_SAMPLE_COUNT;
    i++
  ) {
    int value =
      analogRead(pin);

    if (value < minVal) {
      minVal = value;
    }

    if (value > maxVal) {
      maxVal = value;
    }

    delayMicroseconds(
      MIC_SAMPLE_DELAY_US
    );
  }

  return maxVal - minVal;
}

// ============================================================
// LD2410
// ============================================================

void resetLD2410Frame() {
  ldFramePos = 0;
  ldExpectedLength = 0;
}

void parseLD2410Frame() {
  if (ldExpectedLength < 23) {
    return;
  }

  int footer =
    ldExpectedLength - 4;

  if (
    ldFrame[footer] != 0xF8 ||
    ldFrame[footer + 1] != 0xF7 ||
    ldFrame[footer + 2] != 0xF6 ||
    ldFrame[footer + 3] != 0xF5
  ) {
    return;
  }

  // Basic target frame:
  // 02 AA, state,
  // moving distance/energy,
  // stationary distance/energy,
  // detection distance,
  // 55 00.

  if (
    ldFrame[6] != 0x02 ||
    ldFrame[7] != 0xAA
  ) {
    return;
  }

  ldTargetState =
    ldFrame[8];

  ldMovingDistance =
    int(ldFrame[9]) |
    (int(ldFrame[10]) << 8);

  ldMovingEnergy =
    ldFrame[11];

  ldStationaryDistance =
    int(ldFrame[12]) |
    (int(ldFrame[13]) << 8);

  ldStationaryEnergy =
    ldFrame[14];

  ldLastValidFrameTime =
    millis();

  // Copy into LCD cache.
  latestLDTargetState =
    ldTargetState;

  latestLDMovingDistance =
    ldMovingDistance;

  latestLDMovingEnergy =
    ldMovingEnergy;

  latestLDStationaryDistance =
    ldStationaryDistance;

  latestLDStationaryEnergy =
    ldStationaryEnergy;
}

void pollLD2410() {
  const byte header[4] = {
    0xF4,
    0xF3,
    0xF2,
    0xF1
  };

  while (
    Serial2.available() > 0
  ) {
    byte incomingByte =
      Serial2.read();

    if (ldFramePos < 4) {
      if (
        incomingByte ==
        header[ldFramePos]
      ) {
        ldFrame[
          ldFramePos++
        ] = incomingByte;
      } else {
        ldFramePos =
          incomingByte ==
          header[0] ?
          1 :
          0;

        if (ldFramePos == 1) {
          ldFrame[0] =
            incomingByte;
        }
      }

      continue;
    }

    if (
      ldFramePos >=
      int(sizeof(ldFrame))
    ) {
      resetLD2410Frame();
      continue;
    }

    ldFrame[
      ldFramePos++
    ] = incomingByte;

    if (ldFramePos == 6) {
      int payloadLength =
        int(ldFrame[4]) |
        (int(ldFrame[5]) << 8);

      ldExpectedLength =
        4 +
        2 +
        payloadLength +
        4;

      if (
        ldExpectedLength < 10 ||
        ldExpectedLength >
          int(sizeof(ldFrame))
      ) {
        resetLD2410Frame();
      }
    }

    if (
      ldExpectedLength > 0 &&
      ldFramePos ==
        ldExpectedLength
    ) {
      parseLD2410Frame();
      resetLD2410Frame();
    }
  }

  if (
    ldLastValidFrameTime > 0 &&
    millis() -
      ldLastValidFrameTime >
      1500
  ) {
    ldTargetState = 0;
    ldMovingEnergy = 0;
    ldStationaryEnergy = 0;

    latestLDTargetState = 0;
    latestLDMovingEnergy = 0;
    latestLDStationaryEnergy = 0;
  }
}

void printLD2410State() {
  Serial.print(
    F("LD_STATE: ")
  );

  Serial.print(
    ldTargetState
  );

  Serial.print(
    F(" LD_MOVE: ")
  );

  Serial.print(
    ldMovingEnergy
  );

  Serial.print(
    F(" LD_STILL: ")
  );

  Serial.print(
    ldStationaryEnergy
  );

  Serial.print(
    F(" LD_MDIST: ")
  );

  Serial.print(
    ldMovingDistance
  );

  Serial.print(
    F(" LD_SDIST: ")
  );

  Serial.println(
    ldStationaryDistance
  );
}

// ============================================================
// START SYSTEM
// ============================================================

void startSystem() {
  systemActive = true;
  systemHasStartedOnce = true;
  startTime = millis();
  lastHumanActivityTime = startTime;
  ldPowerOnTime = startTime;
  idleUltrasonicConfirmations = 0;

  // Power LD2410.
  digitalWrite(
    RELAY_PIN,
    LD2410_POWER_ON_LEVEL
  );

  Serial.println();

  Serial.println(
    F("================================")
  );

  Serial.println(
    F("SYSTEM START")
  );

  Serial.println(
    F("DATA COLLECTION BEGIN")
  );

  Serial.println(
    F("AUTO SLEEP ARMED")
  );

  Serial.println(
    F("================================")
  );

  lastDataLCDUpdate = 0;
}

// ============================================================
// STOP SYSTEM
// ============================================================

void stopSystem() {
  systemActive = false;
  ldPowerOnTime = 0;
  idleUltrasonicConfirmations = 0;
  lastIdleUltrasonicReadTime = 0;

  // Power off LD2410.
  digitalWrite(
    RELAY_PIN,
    LD2410_POWER_OFF_LEVEL
  );

  while (
    Serial2.available()
  ) {
    Serial2.read();
  }

  latestLDTargetState = 0;
  latestLDMovingDistance = 0;
  latestLDMovingEnergy = 0;
  latestLDStationaryDistance = 0;
  latestLDStationaryEnergy = 0;

  ldTargetState = 0;
  ldMovingDistance = 0;
  ldMovingEnergy = 0;
  ldStationaryDistance = 0;
  ldStationaryEnergy = 0;
  ldLastValidFrameTime = 0;
  resetLD2410Frame();

  latestUsL = -1;
  latestUsR = -1;

  latestMicFL = 0;
  latestMicFR = 0;
  latestMicBL = 0;
  latestMicBR = 0;

  Serial.println();

  Serial.println(
    F("================================")
  );

  Serial.println(
    F("SYSTEM STOP")
  );

  Serial.println(
    F("DATA COLLECTION END")
  );

  Serial.println(
    F("WAITING FOR NEXT HEART TOUCH")
  );

  Serial.println(
    F("================================")
  );

  lastDataLCDUpdate = 0;
}

bool ultrasonicInteractionDetected() {
  bool leftNear =
    latestUsL >= DISTANCE_MIN_CM &&
    latestUsL <= DISTANCE_MAX_CM;

  bool rightNear =
    latestUsR >= DISTANCE_MIN_CM &&
    latestUsR <= DISTANCE_MAX_CM;

  return leftNear || rightNear;
}

bool currentHumanActivityDetected() {
  return
    latestIR > HEART_THRESHOLD ||
    ultrasonicInteractionDetected();
}

void updateAutomaticPowerManagement() {
  if (!AUTO_SLEEP_ENABLED || !systemActive) {
    return;
  }

  unsigned long now = millis();

  if (currentHumanActivityDetected()) {
    lastHumanActivityTime = now;
    return;
  }

  if (now - lastHumanActivityTime < AUTO_SLEEP_TIMEOUT_MS) {
    return;
  }

  Serial.println(F("AUTO SLEEP: NO PARTICIPANT"));
  stopSystem();
}

// ============================================================
// SETUP
// ============================================================

void setup() {
  Serial.begin(USB_BAUD);

  pinMode(
    TRIG_L,
    OUTPUT
  );

  pinMode(
    ECHO_L,
    INPUT
  );

  pinMode(
    TRIG_R,
    OUTPUT
  );

  pinMode(
    ECHO_R,
    INPUT
  );

  pinMode(
    RELAY_PIN,
    OUTPUT
  );

  digitalWrite(
    RELAY_PIN,
    LD2410_POWER_OFF_LEVEL
  );

  // Start I2C bus.
  Wire.begin();

  // Optional:
  // 400 kHz I2C makes LCD updates faster.
  Wire.setClock(400000);

  // Initialise both LCD displays.
  dataLCD.init();
  dataLCD.backlight();

  printLCD.init();
  printLCD.backlight();

  lcdPrintLine(
    dataLCD,
    0,
    "PROBIFORM"
  );

  lcdPrintLine(
    dataLCD,
    1,
    "SENSOR TERMINAL"
  );

  lcdPrintLine(
    dataLCD,
    2,
    "INITIALISING..."
  );

  lcdPrintLine(
    dataLCD,
    3,
    "PLEASE WAIT"
  );

  lcdPrintLine(
    printLCD,
    0,
    "PROBIFORM"
  );

  lcdPrintLine(
    printLCD,
    1,
    "ARCHIVE TERMINAL"
  );

  lcdPrintLine(
    printLCD,
    2,
    "INITIALISING..."
  );

  lcdPrintLine(
    printLCD,
    3,
    "PLEASE WAIT"
  );

  setupThermalPrinter();

  Serial2.begin(
    LD2410_BAUD
  );

  Serial.println(
    F("===== SENSOR SYSTEM READY =====")
  );

  Serial.println(
    F("Thermal printer: Serial1 / 9600 baud")
  );

  Serial.println(
    F("Data LCD: 0x27")
  );

  Serial.println(
    F("Printer LCD: 0x26")
  );

  Serial.println(
    F("USB commands: PRINT_BITMAP, PRINT_TEST, PRINT_STATUS")
  );

  Serial.println(
    F("Waiting for MAX30102...")
  );

  if (
    heartSensor.begin(
      Wire,
      I2C_SPEED_FAST
    )
  ) {
    heartFound = true;

    Serial.println(
      F("MAX30102: FOUND")
    );

    heartSensor.setup();

    heartSensor.setPulseAmplitudeRed(
      0x0A
    );

    heartSensor.setPulseAmplitudeGreen(
      0
    );
  } else {
    heartFound = false;

    Serial.println(
      F("MAX30102: NOT FOUND")
    );
  }

  setPrinterDisplayState(
    PRINTER_READY,
    "READY"
  );

  updatePrintLCD(true);
  updateDataLCD();

  Serial.println(
    F("Waiting for heart touch to start...")
  );

  delay(1000);
}

// ============================================================
// LOOP
// ============================================================

void loop() {
  readUsbCommands();

  updatePrinterStateTimeout();
  updatePrintLCD();

  if (
    systemActive &&
    millis() - ldPowerOnTime >= LD2410_WARMUP_MS
  ) {
    pollLD2410();
  }

  // Pause normal sensor collection while receiving or printing
  // a bitmap. Printer LCD updates still occur inside the
  // printing and receiving functions.
  if (
    receivingBitmap ||
    bitmapPrintActive
  ) {
    return;
  }

  long irValue = 0;

  if (heartFound) {
    irValue =
      heartSensor.getIR();
  }

  latestIR = irValue;

  // ================= Waiting State =================

  if (!systemActive) {
    if (
      systemHasStartedOnce &&
      millis() - lastIdleUltrasonicReadTime >=
        IDLE_ULTRASONIC_INTERVAL_MS
    ) {
      lastIdleUltrasonicReadTime = millis();

      latestUsL = readUltrasonicCM(TRIG_L, ECHO_L);
      latestUsR = readUltrasonicCM(TRIG_R, ECHO_R);

      if (ultrasonicInteractionDetected()) {
        idleUltrasonicConfirmations = min(
          int(IDLE_ULTRASONIC_CONFIRMATION_SAMPLES),
          int(idleUltrasonicConfirmations) + 1
        );
      } else {
        idleUltrasonicConfirmations = 0;
      }

      if (
        idleUltrasonicConfirmations >=
          IDLE_ULTRASONIC_CONFIRMATION_SAMPLES
      ) {
        Serial.println(F("ULTRASONIC WAKE: PARTICIPANT DETECTED"));
        startSystem();
        delay(500);
        return;
      }
    }

    updateDataLCD();

    if (
      millis() -
      lastPrintTime >=
      PRINT_INTERVAL
    ) {
      lastPrintTime = millis();

      Serial.print(
        F("WAITING | IR: ")
      );

      Serial.print(
        irValue
      );

      if (systemHasStartedOnce) {
        Serial.print(F(" WAKE_L: "));
        Serial.print(latestUsL);
        Serial.print(F(" WAKE_R: "));
        Serial.print(latestUsR);
        Serial.print(F(" CONFIRM: "));
        Serial.print(idleUltrasonicConfirmations);
        Serial.print('/');
        Serial.print(IDLE_ULTRASONIC_CONFIRMATION_SAMPLES);
      }

      Serial.println();
    }

    if (
      heartFound &&
      irValue >
      HEART_THRESHOLD
    ) {
      startSystem();

      delay(500);
    }

    return;
  }

  // ================= Active State =================

  unsigned long elapsed =
    millis() - startTime;

  if (
    millis() -
    lastPrintTime >=
    PRINT_INTERVAL
  ) {
    lastPrintTime = millis();

    // Read sensors once and store values.
    latestUsL =
      readUltrasonicCM(
        TRIG_L,
        ECHO_L
      );

    latestUsR =
      readUltrasonicCM(
        TRIG_R,
        ECHO_R
      );

    latestMicFL =
      readMicPeak(MIC_FL);

    latestMicFR =
      readMicPeak(MIC_FR);

    latestMicBL =
      readMicPeak(MIC_BL);

    latestMicBR =
      readMicPeak(MIC_BR);

    updatePMSDState();

    Serial.println();

    Serial.println(
      F("---------- ACTIVE DATA ----------")
    );

    Serial.print(
      F("RUNNING TIME: ")
    );

    Serial.print(
      elapsed / 1000
    );

    Serial.println(
      F(" s")
    );

    Serial.print(
      F("SYSTEM_ELAPSED_MS: ")
    );

    Serial.println(
      elapsed
    );

    Serial.print(
      F("IR: ")
    );

    Serial.println(
      latestIR
    );

    Serial.print(
      F("US_L: ")
    );

    Serial.print(
      latestUsL
    );

    Serial.print(
      F(" cm   ")
    );

    Serial.print(
      F("US_R: ")
    );

    Serial.print(
      latestUsR
    );

    Serial.println(
      F(" cm")
    );

    Serial.print(
      F("MIC_FL MAX9814: ")
    );

    Serial.print(
      latestMicFL
    );

    Serial.print(
      F("   MIC_FR MAX9814: ")
    );

    Serial.println(
      latestMicFR
    );

    Serial.print(
      F("MIC_BL KY038: ")
    );

    Serial.print(
      latestMicBL
    );

    Serial.print(
      F("   MIC_BR KY038: ")
    );

    Serial.println(
      latestMicBR
    );

    printLD2410State();

    Serial.print(
      F("PMSD: ")
    );

    Serial.println(
      getPMSDCode()
    );

    Serial.println(
      F("---------------------------------")
    );
  }

  updateAutomaticPowerManagement();
  updateDataLCD();
}
