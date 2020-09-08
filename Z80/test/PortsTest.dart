import 'dart:typed_data';

import 'package:Z80/Ports.dart';

class PortsTest extends Ports {
  Uint8List inPorts = Uint8List(65536);
  Uint8List outPorts = Uint8List(65536);

  @override
  int inPort(int port) => inPorts[port];

  @override
  void outPort(int port, int value) {
    outPorts[port] = value;
  }

  int readOutPort(int port) => outPorts[port];

  void writeInPort(int port, int value) {
    inPorts[port] = value;
  }
}
