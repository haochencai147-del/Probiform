// OSC bridge to MAX/MSP. Processing keeps visuals, sensing and archive logic only.

OscP5 oscP5;
NetAddress maxAddress;

int lastOscSendTime = 0;
final int OSC_SEND_INTERVAL = 50;

boolean oscDropPending = false;

void initOscBridge() {
  oscP5 = new OscP5(this, 12000);
  maxAddress = new NetAddress("127.0.0.1", 7400);
}

void sendOscToMax() {
  if (oscP5 == null || maxAddress == null) return;

  int now = millis();
  if (now - lastOscSendTime < OSC_SEND_INTERVAL) return;
  lastOscSendTime = now;

  sendOscFloat("/distanceL", smoothUsL);
  sendOscFloat("/distanceR", smoothUsR);
  sendOscFloat("/voice", soundLevel);
  sendOscFloat("/confidence", active == null ? input.confidence() : active.confidence);
  sendOscFloat("/misread", active == null ? input.conflict : active.misread);
  sendOscInt("/rotation", active == null ? 0 : active.rotation);

  if (oscDropPending) {
    OscMessage dropMessage = new OscMessage("/drop");
    dropMessage.add(1);
    oscP5.send(dropMessage, maxAddress);
    oscDropPending = false;
  }
}

void triggerOscDropBang() {
  oscDropPending = true;
}

void sendOscFloat(String address, float value) {
  OscMessage message = new OscMessage(address);
  message.add(value);
  oscP5.send(message, maxAddress);
}

void sendOscInt(String address, int value) {
  OscMessage message = new OscMessage(address);
  message.add(value);
  oscP5.send(message, maxAddress);
}
