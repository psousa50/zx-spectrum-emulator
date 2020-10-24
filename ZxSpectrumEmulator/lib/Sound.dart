import 'dart:typed_data';

const BUFFER_SIZE = 1000;

class Sound {
  var buffer = Uint8List(BUFFER_SIZE);
  var bufferPos = 0;

  void addSample(int value) {
    buffer[bufferPos++] = value % 256;
    buffer[bufferPos++] = value ~/ 256;
    if (bufferPos + 1 >= BUFFER_SIZE) {
      bufferPos = 0;
    }
  }
}
