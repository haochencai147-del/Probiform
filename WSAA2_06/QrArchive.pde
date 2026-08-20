// Generates a scan-ready archive of the current probabilistic body.
// ZXing is bundled in the sketch's code/ folder, so no online service is used.

final int QR_IMAGE_SIZE = 640;
final int AUTO_QR_BLOCK_INTERVAL = 15;
final int QR_DISPLAY_DURATION_MS = 15000;
final int QR_RECENT_STATUS_MS = 2400;

boolean autoQrArchiveEnabled = true;
int blocksSinceLastQrArchive = 0;
boolean autoQrArchiveRequested = false;
int qrArchiveEdition = 1;
PImage latestQrArchiveImage = null;
String latestQrArchivePayload = "";
String latestQrArchivePath = "";
int qrArchiveVisibleUntil = -1;
int qrArchiveGeneratedAt = -99999;

void notifyBlockDepositedForQr() {
  if (!autoQrArchiveEnabled) return;
  blocksSinceLastQrArchive++;
  if (blocksSinceLastQrArchive >= AUTO_QR_BLOCK_INTERVAL) {
    autoQrArchiveRequested = true;
  }
}

void updateAutoQrArchive() {
  if (!autoQrArchiveEnabled || !autoQrArchiveRequested) return;
  if (generateCurrentQrArchive("auto")) {
    blocksSinceLastQrArchive = 0;
    autoQrArchiveRequested = false;
  }
}

void generateCurrentQrArchive() {
  generateCurrentQrArchive("manual");
}

boolean generateCurrentQrArchive(String source) {
  if (sedimentOccupiedCount() <= 0) {
    println("QR archive skipped: no sediment data yet.");
    return false;
  }

  String payload = buildQrArchivePayload();
  PImage generated = encodeQrPayload(payload, QR_IMAGE_SIZE);
  if (generated == null) return false;

  String editionLabel = nf(qrArchiveEdition, 3);
  java.io.File archiveDirectory = new java.io.File(sketchPath("../output/qr"));
  if (!archiveDirectory.exists() && !archiveDirectory.mkdirs()) {
    println("QR archive warning: could not create " + archiveDirectory.getAbsolutePath());
  }

  String filename = "probiform-" + editionLabel + "-" + qrArchiveTimestamp() + ".png";
  latestQrArchivePath = new java.io.File(archiveDirectory, filename).getAbsolutePath();
  generated.save(latestQrArchivePath);

  latestQrArchiveImage = generated;
  latestQrArchivePayload = payload;
  qrArchiveGeneratedAt = millis();
  qrArchiveVisibleUntil = millis() + QR_DISPLAY_DURATION_MS;
  qrArchiveEdition++;

  println("QR archive generated (" + source + "): " + latestQrArchivePath);
  return true;
}

PImage encodeQrPayload(String payload, int imageSize) {
  try {
    HashMap<EncodeHintType, Object> hints = new HashMap<EncodeHintType, Object>();
    hints.put(EncodeHintType.CHARACTER_SET, "UTF-8");
    hints.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.M);
    hints.put(EncodeHintType.MARGIN, 3);

    QRCodeWriter writer = new QRCodeWriter();
    BitMatrix matrix = writer.encode(payload, BarcodeFormat.QR_CODE, imageSize, imageSize, hints);
    PImage result = createImage(matrix.getWidth(), matrix.getHeight(), RGB);
    result.loadPixels();
    for (int y = 0; y < matrix.getHeight(); y++) {
      for (int x = 0; x < matrix.getWidth(); x++) {
        result.pixels[y * matrix.getWidth() + x] = matrix.get(x, y) ? color(0) : color(255);
      }
    }
    result.updatePixels();
    return result;
  }
  catch (Exception error) {
    println("QR archive failed: " + error.getMessage());
    return null;
  }
}

String buildQrArchivePayload() {
  float confidence = active == null ? input.confidence() : active.confidence;
  float misread = active == null ? input.conflict : active.misread;
  StringBuilder payload = new StringBuilder();
  payload.append("PROBIFORM|v=1");
  payload.append("|edition=").append(nf(qrArchiveEdition, 3));
  payload.append("|time=").append(qrArchiveTimestamp());
  payload.append("|pmsd=").append(binary(currentPMSD, 4));
  payload.append("|confidence=").append(nf(constrain(confidence, 0, 1), 1, 3));
  payload.append("|misread=").append(nf(constrain(misread, 0, 1), 1, 3));
  payload.append("|presence=").append(shapePresenceNow() ? 1 : 0);
  payload.append("|motion=").append(shapeMotionNow() ? 1 : 0);
  payload.append("|sound=").append(shapeSoundNow() ? 1 : 0);
  payload.append("|distance=").append(shapeDistanceNow() ? 1 : 0);
  payload.append("|distanceL=").append(nf(smoothUsL, 1, 2));
  payload.append("|distanceR=").append(nf(smoothUsR, 1, 2));
  payload.append("|field=").append(qrSedimentFieldHex());
  return payload.toString();
}

String qrSedimentFieldHex() {
  StringBuilder encoded = new StringBuilder((COLS * ROWS) / 4);
  int nibble = 0;
  int bitCount = 0;
  final String HEX_DIGITS = "0123456789ABCDEF";

  for (int y = 0; y < ROWS; y++) {
    for (int x = 0; x < COLS; x++) {
      nibble = (nibble << 1) | (sediment[x][y].occupied ? 1 : 0);
      bitCount++;
      if (bitCount == 4) {
        encoded.append(HEX_DIGITS.charAt(nibble));
        nibble = 0;
        bitCount = 0;
      }
    }
  }

  if (bitCount > 0) {
    nibble <<= 4 - bitCount;
    encoded.append(HEX_DIGITS.charAt(nibble));
  }
  return encoded.toString();
}

String qrArchiveTimestamp() {
  return nf(year(), 4) + nf(month(), 2) + nf(day(), 2) + "-" +
    nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
}

void showLatestQrArchive() {
  if (latestQrArchiveImage == null) {
    println("No QR archive has been generated yet.");
    return;
  }
  qrArchiveVisibleUntil = millis() + QR_DISPLAY_DURATION_MS;
}

boolean qrArchiveIsVisible() {
  return latestQrArchiveImage != null && millis() < qrArchiveVisibleUntil;
}

boolean qrArchiveRecentlyGenerated() {
  return millis() - qrArchiveGeneratedAt < QR_RECENT_STATUS_MS;
}

void drawQrArchiveOverlay() {
  if (!qrArchiveIsVisible()) return;

  pushStyle();
  noStroke();
  fill(0, 205);
  rect(0, 0, width, height);

  float qrSize = min(QR_IMAGE_SIZE, min(width * 0.58, height * 0.68));
  float panelPad = max(18, qrSize * 0.055);
  float footerH = max(62, qrSize * 0.13);
  float panelW = qrSize + panelPad * 2;
  float panelH = qrSize + panelPad * 2 + footerH;
  float panelX = width * 0.5 - panelW * 0.5;
  float panelY = height * 0.5 - panelH * 0.5;

  fill(255);
  rect(panelX, panelY, panelW, panelH);
  image(latestQrArchiveImage, panelX + panelPad, panelY + panelPad, qrSize, qrSize);

  fill(0);
  textAlign(CENTER, TOP);
  useMachineFont(max(13, min(22, qrSize * 0.035)));
  text("PROBABILISTIC BODY ARCHIVE " + nf(qrArchiveEdition - 1, 3),
    width * 0.5, panelY + panelPad + qrSize + panelPad * 0.45);
  useMachineFont(max(10, min(16, qrSize * 0.025)));
  text("P: GENERATE   I: REOPEN   AUTO CLOSE: 15 SEC",
    width * 0.5, panelY + panelPad + qrSize + panelPad * 1.55);
  popStyle();
}
