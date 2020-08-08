class Memory {
  var bytes;

  Memory.withBytes(this.bytes);

  Memory({int size = 10}) {
    this.bytes = List<int>(size);
  }

  peek(int address) => bytes[address];

  peek2(int address) => bytes[address] + 256 * bytes[address + 1];

  poke(int address, int b) {
    this.bytes[address] = b;
  }

  poke2(int address, int b) {
    this.bytes[address] = b % 256;
    this.bytes[address + 1] = b ~/ 256;
  }
}
