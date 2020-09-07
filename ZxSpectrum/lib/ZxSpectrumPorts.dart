import 'package:Z80a/Ports.dart';

import 'PortHandler.dart';

class PortBinding {
  int bitMask;
  int value;
  PortHandler portHandler;

  PortBinding(this.bitMask, this.value, this.portHandler);
}

class ZxSpectrumPorts extends Ports {
  var bindings = List<PortBinding>();

  void bindPort(int bitMask, int value, PortHandler handler) {
    bindings.add(PortBinding(bitMask, value, handler));
  }

  PortHandler handler(int port) {
    var h = bindings.firstWhere((b) => (port & b.bitMask) == b.value);
    return h == null ? null : h.portHandler;
  }

  @override
  int inPort(int port) => handler(port)?.read(port);

  @override
  void outPort(int port, int value) => handler(port)?.write(port, value);
}
