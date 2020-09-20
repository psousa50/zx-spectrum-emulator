import 'package:flutter/material.dart';

enum JoystickState { On, Off }
typedef void JoystickAction(JoystickState state);

class Joystick extends StatefulWidget {
  final JoystickAction left;
  final JoystickAction right;
  final JoystickAction up;
  final JoystickAction down;
  final JoystickAction fire;

  Joystick(
    this.left,
    this.right,
    this.up,
    this.down,
    this.fire,
  );
  @override
  _JoystickState createState() => _JoystickState();
}

const threshold = 1;

class _JoystickState extends State<Joystick> {
  double sx = 0;
  double sy = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Row(children: [
        Expanded(
            flex: 1,
            child: GestureDetector(
              onTapDown: (_) {
                widget.fire(JoystickState.On);
              },
              onTapUp: (_) {
                widget.fire(JoystickState.Off);
              },
              onTapCancel: () {
                widget.fire(JoystickState.Off);
              },
              onPanCancel: () {
                widget.fire(JoystickState.Off);
              },
              onPanEnd: (_) {
                widget.fire(JoystickState.Off);
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
              widget.left(JoystickState.Off);
              widget.right(JoystickState.Off);
              widget.up(JoystickState.Off);
              widget.down(JoystickState.Off);
            },
            onPanUpdate: (details) {
              double x = details.localPosition.dx;
              double y = details.localPosition.dy;

              double dx = x - sx;
              double dy = y - sy;

              if (dy.abs() > threshold && dx.abs() < threshold) {
                widget.left(JoystickState.Off);
                widget.right(JoystickState.Off);
              }

              if (dx.abs() > threshold && dy.abs() < threshold) {
                widget.up(JoystickState.Off);
                widget.down(JoystickState.Off);
              }

              if (dx > threshold) {
                widget.right(JoystickState.On);
                widget.left(JoystickState.Off);
              }

              if (dx < -threshold) {
                widget.left(JoystickState.On);
                widget.right(JoystickState.Off);
              }

              if (dy < -threshold) {
                widget.up(JoystickState.On);
                widget.down(JoystickState.Off);
              }

              if (dy > threshold) {
                widget.down(JoystickState.On);
                widget.up(JoystickState.Off);
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
