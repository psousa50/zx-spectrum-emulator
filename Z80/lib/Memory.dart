import 'dart:typed_data';

import 'Util.dart';

typedef void OnMemoryError(int address);

void onMemoryErrorDefault(int address) {
  print("Memory error in $address");
}

abstract class Memory {
  int get size;
  bool get readonly;

  int peek(int address);
  int peek2(int address);

  Uint8List range(int address, {int end});

  void poke(int address, int b);
  void poke2(int address, int w);

  void setRange(int address, Uint8List bytes);
}

abstract class ReadOnlyMemory extends Memory {
  bool get readonly => true;
  void poke(int address, int b) {}
  void poke2(int address, int w) {}

  void setRange(int address, Uint8List bytes) {}
}

class MemoryAsBytes extends Memory {
  Uint8List bytes;
  final bool readonly;
  final OnMemoryError onMemoryError;

  MemoryAsBytes.fromBytes(this.bytes, this.onMemoryError,
      {this.readonly = false});

  MemoryAsBytes(int size, this.onMemoryError, {this.readonly = false}) {
    this.bytes = Uint8List.fromList(List.filled(size, 0));
  }

  bool checkAddress(int address, int size) {
    var a = word(address);
    bool valid = a >= 0 && a + size <= bytes.length;
    if (!valid) onMemoryError(address);
    return valid;
  }

  bool checkWritableAddress(int address, int size) =>
      !readonly && checkAddress(address, size);

  @override
  peek(int address) => checkAddress(address, 0) ? bytes[word(address)] : 0;

  @override
  peek2(int address) => checkAddress(address, 1)
      ? bytes[word(address)] + 256 * bytes[word(address + 1)]
      : 0;

  @override
  Uint8List range(int address, {int end}) =>
      checkAddress(address, (end ?? bytes.length) - address)
          ? bytes.sublist(word(address), end)
          : Uint8List(0);

  @override
  int get size => bytes.length;

  @override
  poke(int address, int b) {
    if (checkWritableAddress(address, 0)) {
      this.bytes[word(address)] = byte(b);
    }
  }

  @override
  poke2(int address, int w) {
    if (checkWritableAddress(address, 1)) {
      var nw = word(w);
      this.bytes[word(address)] = lo(nw);
      this.bytes[word(address + 1)] = hi(nw);
    }
  }

  @override
  void setRange(int address, Uint8List bytes) {
    if (checkAddress(address, bytes.length)) {
      this.bytes.setRange(address, address + bytes.length, bytes);
    }
  }
}
