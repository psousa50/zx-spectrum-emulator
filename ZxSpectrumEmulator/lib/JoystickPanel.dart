import 'dart:math';

import 'package:flutter/material.dart';

import 'package:ZxSpectrum/JoystickListener.dart';

class JoystickPanel extends StatefulWidget {
  final List<JoystickListener> listeners;

  JoystickPanel(this.listeners);

  @override
  _JoystickPanelState createState() => _JoystickPanelState();
}

class Direction {
  static double tan15 = tan(15 * pi / 180);
  static double tan75 = tan(75 * pi / 180);

  int dx;
  int dy;

  Direction(double dx, double dy) {
    var tanDyDx = dx.abs() > 0 ? dy.abs() / dx.abs() : double.maxFinite;
    this.dx = dx.sign.toInt() * (tanDyDx < tan75 ? 1 : 0);
    this.dy = dy.sign.toInt() * (tanDyDx > tan15 ? 1 : 0);
  }

  bool stopped() => dx == 0 && dy == 0;

  @override
  bool operator ==(Object other) =>
      other is Direction && other.dx == dx && other.dy == dy;

  @override
  int get hashCode => dx + dy;

  @override
  String toString() {
    return "($dx,$dy)";
  }
}

class _JoystickPanelState extends State<JoystickPanel> {
  double startX = 0;
  double startY = 0;
  double lastX = 0;
  double lastY = 0;
  Direction currentDirection;

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
              startX = details.localPosition.dx;
              startY = details.localPosition.dy;
              lastX = startX;
              lastY = startY;
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

              double dx = x - startX;
              double dy = y - startY;

              if (dx.abs() + dy.abs() < 5) return;

              var direction = Direction(x - lastX, y - lastY);
              lastX = x;
              lastY = y;

              if (direction.stopped()) return;

              if (direction != currentDirection) {
                startX = x;
                startY = y;
                currentDirection = direction;
                return;
              }

              direction = Direction(x - startX, y - startY);

              switch (currentDirection.dx) {
                case -1:
                  onAction(JoystickAction.left, true);
                  onAction(JoystickAction.right, false);
                  break;
                case 0:
                  onAction(JoystickAction.left, false);
                  onAction(JoystickAction.right, false);
                  break;
                case 1:
                  onAction(JoystickAction.left, false);
                  onAction(JoystickAction.right, true);
                  break;
              }

              switch (currentDirection.dy) {
                case -1:
                  onAction(JoystickAction.up, true);
                  onAction(JoystickAction.down, false);
                  break;
                case 0:
                  onAction(JoystickAction.up, false);
                  onAction(JoystickAction.down, false);
                  break;
                case 1:
                  onAction(JoystickAction.up, false);
                  onAction(JoystickAction.down, true);
                  break;
              }
            },
            child: Container(color: Colors.transparent),
          ),
        )
      ]),
    );
  }
}
