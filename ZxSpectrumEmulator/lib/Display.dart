import 'dart:typed_data';

import 'package:flutter/material.dart';

class Display extends StatelessWidget {
  final Uint8List screen;
  final Color borderColor;

  Display(this.screen, this.borderColor);

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 352 / 296,
            child: Container(
              color: borderColor,
              child: FractionallySizedBox(
                widthFactor: 1 - 48 / 352,
                heightFactor: 1 - 48 / 296,
                child: screen != null
                    ? Image.memory(
                        screen,
                        gaplessPlayback: true,
                        fit: BoxFit.contain,
                      )
                    : Container(),
              ),
            ),
          ),
        ),
      ]);
}
