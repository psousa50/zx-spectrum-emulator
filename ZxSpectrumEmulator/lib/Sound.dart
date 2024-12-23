import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';

const BUFFER_SIZE = 10000;

class Sound {
  final int sampleRate;

  late FlutterSoundPlayer player;
  var buffer = Uint8List(BUFFER_SIZE);
  var bufferPos = 0;

  Sound({this.sampleRate = 48000}) {
    player = FlutterSoundPlayer();
  }

  Future<void> start() async {
    await player.openPlayer();
    return player.startPlayerFromStream(
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: sampleRate,
    );
  }

  Future<void> stop() {
    print("Sound STOP");
    return player.closePlayer();
  }

  void addBuffer(Uint8List buffer) async {
    await player.feedFromStream(buffer);
    // player.foodSink.add(FoodData(buffer));
  }

  void addSample(int value) {
    try {
      buffer[bufferPos++] = value % 256;
      buffer[bufferPos++] = value ~/ 256;
      if (bufferPos + 1 >= 1000) {
        addBuffer(buffer.sublist(0, 1000));
        // print(buffer.sublist(0, 10));
        bufferPos = 0;
      }
    } catch (e) {
      print(e.toString());
    }
  }
}
