/// Provides a widget and an associated controller for simple painting using touch.
library painter;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart' hide Image;

part 'history.dart';

/// A very simple widget that supports drawing using touch.
class Painter extends StatefulWidget {
  final PainterController painterController;

  /// Creates an instance of this widget that operates on top of the supplied [PainterController].
  Painter(
    this.painterController,
  ) : super(key: ValueKey<PainterController>(painterController));

  @override
  _PainterState createState() => _PainterState();
}

class _PainterState extends State<Painter> {
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    widget.painterController._widgetFinish = _finish;
  }

  Size _finish() {
    setState(() {
      _finished = true;
    });
    return context.size ?? const Size(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = CustomPaint(
      willChange: true,
      painter: _PainterPainter(
        widget.painterController._pathHistory,
        repaint: widget.painterController,
      ),
    );
    child = ClipRect(child: child);
    if (!_finished) {
      child = GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTapUp: _onTapUp,
        onLongPress: _onLongPress,
        child: child,
      );
    }
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: child,
    );
  }

  void _onPanStart(DragStartDetails start) {
    Offset pos = (context.findRenderObject() as RenderBox)
        .globalToLocal(start.globalPosition);
    widget.painterController._pathHistory.add(pos);
    widget.painterController._notifyListeners();
  }

  void _onPanUpdate(DragUpdateDetails update) {
    Offset pos = (context.findRenderObject() as RenderBox)
        .globalToLocal(update.globalPosition);
    widget.painterController._pathHistory.updateCurrent(pos);
    widget.painterController._notifyListeners();
  }

  void _onPanEnd(DragEndDetails end) {
    widget.painterController._pathHistory.endCurrent();
    widget.painterController._notifyListeners();
  }

  void _onTapUp(TapUpDetails details) {
    Offset pos = (context.findRenderObject() as RenderBox).globalToLocal(
      details.globalPosition,
    );
    widget.painterController._pathHistory.addTap(pos);
    widget.painterController._pathHistory.endCurrent();
    widget.painterController._notifyListeners();
  }

  void _onLongPress() {
    final size = (context.findRenderObject() as RenderBox).size;
    widget.painterController._pathHistory.addRect(Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    ));
    widget.painterController._pathHistory.endCurrent();
    widget.painterController._notifyListeners();
  }
}

class _PainterPainter extends CustomPainter {
  final _PathHistory _path;

  _PainterPainter(this._path, {Listenable? repaint}) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    _path.draw(canvas, size);
  }

  @override
  bool shouldRepaint(_PainterPainter oldDelegate) {
    return true;
  }
}

/// Used with a [Painter] widget to control drawing.
class PainterController extends ChangeNotifier {
  Color _drawColor = const Color.fromARGB(255, 0, 0, 0);
  bool _eraseMode = false;

  double _thickness = 1.0;
  bool finished = false;
  final _PathHistory _pathHistory;
  ValueGetter<Size>? _widgetFinish;

  /// Creates a new instance for the use in a [Painter] widget.
  PainterController() : _pathHistory = _PathHistory();

  PainterController.fromJson(Map<String, dynamic> json)
      : _pathHistory = _PathHistory.fromJson(json);

  /// Returns true if nothing has been drawn yet.
  bool get isEmpty => _pathHistory.isEmpty;

  /// Returns true if the the [PainterController] is currently in erase mode,
  /// false otherwise.
  bool get eraseMode => _eraseMode;

  /// If set to true, erase mode is enabled, until this is called again with
  /// false to disable erase mode.
  set eraseMode(bool enabled) {
    _eraseMode = enabled;
    _updatePaint();
  }

  /// Retrieves the current draw color.
  Color get drawColor => _drawColor;

  /// Sets the draw color.
  set drawColor(Color color) {
    _drawColor = color;
    _updatePaint();
  }

  /// Returns the current thickness that is used for drawing.
  double get thickness => _thickness;

  /// Sets the draw thickness..
  set thickness(double t) {
    _thickness = t;
    _updatePaint();
  }

  void _updatePaint() {
    Paint paint = Paint();
    if (_eraseMode) {
      paint.blendMode = BlendMode.clear;
      paint.color = const Color.fromARGB(0, 255, 0, 0);
    } else {
      paint.color = drawColor;
      paint.blendMode = BlendMode.srcOver;
    }
    paint.strokeWidth = thickness;

    _pathHistory
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..blendMode = paint.blendMode;

    notifyListeners();
  }

  /// Undoes the last drawing action (but not a background color change).
  /// If the picture is already finished, this is a no-op and does nothing.
  void undo() {
    if (!isFinished()) {
      _pathHistory.undo();
      notifyListeners();
    }
  }

  /// Redoes the last drawing action (but not a background color change).
  /// If the picture is already finished, this is a no-op and does nothing.
  void redo() {
    if (!isFinished()) {
      _pathHistory.redo();
      notifyListeners();
    }
  }

  void _notifyListeners() {
    notifyListeners();
  }

  /// Deletes all drawing actions, but does not affect the background.
  /// If the picture is already finished, this is a no-op and does nothing.
  void clear() {
    if (!isFinished()) {
      _pathHistory.clear();
      notifyListeners();
    }
  }

  /// The drawing is cached and on subsequent calls to this method, the cached
  /// drawing is returned.
  ///
  /// This might throw a [StateError] if this PainterController is not attached
  /// to a widget, or the associated widget's [Size.isEmpty].
  ///
  /// If already finished, this does nothing
  void finish() {
    if (!isFinished()) {
      finished = true;
    }
  }

  Map<String, dynamic> toJson() {
    return _pathHistory.toJson();
  }

  /// Returns true if this drawing is finished.
  ///
  /// Trying to modify a finished drawing is a no-op.
  bool isFinished() => finished;
}
