import 'dart:typed_data';

import 'package:Z80a/Memory.dart';
import 'Util.dart';

class Memory48K extends Memory {
  Uint8List bytes;

  Memory48K.fromBytes(this.bytes);

  Memory48K({size = 10}) {
    this.bytes = Uint8List.fromList(List.filled(size, 0));
  }

  int normalize(int address) => address % 65536;

  peek(int address) => bytes[normalize(address)];

  peek2(int address) =>
      bytes[normalize(address)] + 256 * bytes[normalize(address + 1)];

  poke(int address, int b) {
    this.bytes[normalize(address)] = b;
  }

  poke2(int address, int b) {
    this.bytes[normalize(address)] = lo(b);
    this.bytes[normalize(address + 1)] = hi(b);
  }

  @override
  Uint8List range(int start, {int end}) => bytes.sublist(start, end);
}
