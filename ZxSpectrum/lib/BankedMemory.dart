import 'dart:typed_data';

import 'package:Z80/Memory.dart';
import 'package:Z80/Util.dart';

class MemoryBank extends Memory {
  final int startAddress;
  final Memory memory;

  MemoryBank(this.startAddress, this.memory);

  @override
  int peek(int address) => memory.peek(address - startAddress);

  @override
  int peek2(int address) => memory.peek2(address - startAddress);

  @override
  void poke(int address, int b) {
    memory.poke(address - startAddress, b);
  }

  @override
  void poke2(int address, int w) {
    memory.poke2(address - startAddress, w);
  }

  @override
  Uint8List range(int address, {int end}) =>
      memory.range(address - startAddress, end: end - startAddress);

  @override
  bool get readonly => memory.readonly;

  @override
  void setRange(int address, Uint8List bytes) {
    memory.setRange(address - startAddress, bytes);
  }

  @override
  int get size => memory.size;
}

class InvalidMemory extends ReadOnlyMemory {
  final OnMemoryError onMemoryError;

  InvalidMemory(this.onMemoryError);

  @override
  int peek(int address) {
    onMemoryError(address);
    return 0;
  }

  @override
  int peek2(int address) {
    onMemoryError(address);
    return 0;
  }

  @override
  Uint8List range(int address, {int end}) {
    onMemoryError(address);
    return Uint8List(0);
  }

  @override
  int get size => 0;
}

class BankedMemory extends Memory {
  final List<MemoryBank> banks;
  final OnMemoryError onMemoryError;

  BankedMemory(this.banks, {this.onMemoryError});

  int normalize(int address) => address % 65536;

  Memory getBank(int address) {
    var a = normalize(address);
    MemoryBank bank = banks.firstWhere(
        (bank) =>
            a >= bank.startAddress && a < bank.startAddress + bank.memory.size,
        orElse: () => MemoryBank(0, InvalidMemory(this.onMemoryError)));

    return bank;
  }

  @override
  int get size => banks.fold(
      0, (previousValue, element) => previousValue + element.memory.size);

  @override
  int peek(int address) => getBank(address).peek(address);

  @override
  int peek2(int address) =>
      w(getBank(address).peek(address), getBank(address + 1).peek(address + 1));

  @override
  void poke(int address, int b) {
    getBank(address).poke(address, b);
  }

  @override
  void poke2(int address, int w) {
    getBank(address).poke2(address, w);
  }

  @override
  Uint8List range(int address, {int end}) =>
      getBank(address).range(address, end: end);

  @override
  void setRange(int address, Uint8List bytes) {
    getBank(address).setRange(address, bytes);
  }

  @override
  bool get readonly => banks.fold(
      true, (previousValue, bank) => previousValue && bank.memory.readonly);
}
