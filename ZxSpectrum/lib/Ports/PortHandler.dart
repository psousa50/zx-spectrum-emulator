mixin PortHandler {
  int read(int port);
  void write(int port, int value);
}

class NullPortHandler with PortHandler {
  int read(int port) => 0x00;

  void write(int port, int value) {}
}

var nullPortHandler = NullPortHandler();
