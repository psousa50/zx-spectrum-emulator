import 'dart:typed_data';

import 'package:ZxSpectrumEmulator/ula.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Display extends StatefulWidget {
  @override
  _DisplayState createState() => _DisplayState();
}

class _DisplayState extends State<Display> {
  ByteData screen;

  void getScreen() async {
    var s = await rootBundle.load('assets/google.scr');
    setState(() {
      screen = s;
    });
  }

  @override
  void initState() {
    super.initState();
    getScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (screen == null) {
      return Text("No Screen!");
    }
    var bitmap = Ula.buildImage(screen.buffer.asUint8List());
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.grey, offset: Offset(20, 20), blurRadius: 20),
        ],
        border: Border.all(color: Color(0)),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Image.memory(
        bitmap,
        width: 256,
        height: 192,
        gaplessPlayback: true,
      ),
    );
  }
}
