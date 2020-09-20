import 'package:flutter/material.dart';

import 'package:ZxSpectrum/JoystickListener.dart';

class JoystickPanel extends StatefulWidget {
  final List<JoystickListener> listeners;

  JoystickPanel(this.listeners);

  @override
  _JoystickPanelState createState() => _JoystickPanelState();
}

const threshold = 1;

class _JoystickPanelState extends State<JoystickPanel> {
  double sx = 0;
  double sy = 0;

  void onAction(JoystickAction action, bool active) {
    widget.listeners.forEach((l) {
      l.onJoystickAction(action, active);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Row(children: [
        Expanded(
            flex: 1,
            child: GestureDetector(
              onTapDown: (_) {
                onAction(JoystickAction.fire, true);
              },
              onTapUp: (_) {
                onAction(JoystickAction.fire, false);
              },
              onTapCancel: () {
                onAction(JoystickAction.fire, false);
              },
              onPanEnd: (_) {
                onAction(JoystickAction.fire, false);
              },
              child: Container(
                color: Colors.transparent,
              ),
            )),
        Expanded(
          flex: 3,
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                sx = details.localPosition.dx;
                sy = details.localPosition.dy;
              });
            },
            onPanEnd: (details) {
              onAction(JoystickAction.left, false);
              onAction(JoystickAction.right, false);
              onAction(JoystickAction.up, false);
              onAction(JoystickAction.down, false);
            },
            onPanUpdate: (details) {
              double x = details.localPosition.dx;
              double y = details.localPosition.dy;

              double dx = x - sx;
              double dy = y - sy;

              if (dy.abs() > threshold && dx.abs() < threshold) {
                onAction(JoystickAction.left, false);
                onAction(JoystickAction.right, false);
              }

              if (dx.abs() > threshold && dy.abs() < threshold) {
                onAction(JoystickAction.up, false);
                onAction(JoystickAction.down, false);
              }

              if (dx > threshold) {
                onAction(JoystickAction.right, true);
                onAction(JoystickAction.left, false);
              }

              if (dx < -threshold) {
                onAction(JoystickAction.left, true);
                onAction(JoystickAction.right, false);
              }

              if (dy < -threshold) {
                onAction(JoystickAction.up, true);
                onAction(JoystickAction.down, false);
              }

              if (dy > threshold) {
                onAction(JoystickAction.down, true);
                onAction(JoystickAction.up, false);
              }

              sx = x;
              sy = y;
            },
            child: Container(color: Colors.transparent),
          ),
        )
      ]),
    );
  }
}
