import 'dart:typed_data';

import 'package:Z80a/Ports.dart';

class ZxSpectrumPorts extends Ports {
  Uint8List ports = Uint8List(256);

  @override
  int inPort(int port) => ports[port];

  @override
  void outPort(int port, int value) {
    ports[port] = value;
  }
}
