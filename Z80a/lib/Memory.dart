import './Util.dart';

class Memory {
  List<int> bytes;
  int baseAddress;

  Memory.fromBytes(this.bytes, {this.baseAddress = 0});

  Memory({size = 10, this.baseAddress = 0}) {
    this.bytes = List<int>.filled(size, 0);
  }

  peek(int address) => bytes[address - baseAddress];

  peek2(int address) =>
      bytes[address - baseAddress] + 256 * bytes[address - baseAddress + 1];

  poke(int address, int b) {
    this.bytes[address - baseAddress] = b;
  }

  poke2(int address, int b) {
    this.bytes[address - baseAddress] = lo(b);
    this.bytes[address - baseAddress + 1] = hi(b);
  }
}
