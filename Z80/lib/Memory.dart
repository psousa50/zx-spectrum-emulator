import 'dart:typed_data';

typedef void OnMemoryError(int address);

void onMemoryErrorDefault(int address) {
  print("Memory error in $address");
}

abstract class Memory {
  int get size;
  bool get readonly;

  int peek(int address);
  int peek2(int address);

  Uint8List range(int address, {int? end});

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
