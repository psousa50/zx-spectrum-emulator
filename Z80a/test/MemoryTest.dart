import 'dart:typed_data';

import 'package:Z80a/Memory.dart';
import 'package:Z80a/Util.dart';

class MemoryTest extends Memory {
  List<int> bytes;

  MemoryTest.fromBytes(this.bytes);

  MemoryTest({size = 10}) {
    this.bytes = List<int>.filled(size, 0);
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
  Uint8List range(int start, {int end}) =>
      Uint8List.fromList(bytes.sublist(start, end));
}
