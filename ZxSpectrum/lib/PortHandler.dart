abstract class PortHandler {
  int read(int port);
  void write(int port, int value);
}

class NullPortHandler extends PortHandler {
  int read(int port) => 0;
  void write(int port, int value) {}
}

var nullPortHandler = NullPortHandler();
