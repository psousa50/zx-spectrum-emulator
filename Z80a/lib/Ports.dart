abstract class Ports {
  int inPort(int port);
  void outPort(int port, int value);

  void writeInPort(int port, int value);
  int readOutPort(int port);
}
