part of 'painter.dart';

abstract class _PathInfo {
  const _PathInfo();

  Path get path;
}

class _LinePathInfo extends _PathInfo {
  final Offset startingPoint;
  final List<Offset> lines;

  const _LinePathInfo({
    required this.startingPoint,
    required this.lines,
  });

  @override
  Path get path {
    final Path path = Path();

    path.moveTo(startingPoint.dx, startingPoint.dy);
    for (final line in lines) {
      path.lineTo(line.dx, line.dy);
    }

    return path;
  }
}

class _CirclePathInfo extends _PathInfo {
  final Offset point;
  final double radius;

  const _CirclePathInfo({
    required this.point,
    required this.radius,
  });

  @override
  Path get path {
    final Path path = Path();

    path.addOval(Rect.fromCircle(
      center: point,
      radius: radius,
    ));

    return path;
  }
}

class _RectPathInfo extends _PathInfo {
  final Rect rect;

  const _RectPathInfo({required this.rect});

  @override
  Path get path {
    final Path path = Path();

    path.addRect(rect);

    return path;
  }
}

class _Path {
  final _PathInfo info;
  final Paint paint;

  const _Path({required this.info, required this.paint});
}

class _PathHistory {
  final List<_Path> _redoPaths;
  final List<_Path> _paths;
  Paint currentPaint;
  final Paint _backgroundPaint;
  bool _inDrag;

  bool get isEmpty => _paths.isEmpty || (_paths.length == 1 && _inDrag);

  _PathHistory()
      : _paths = [],
        _redoPaths = [],
        _inDrag = false,
        _backgroundPaint = Paint()..blendMode = BlendMode.dstOver,
        currentPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 1.0
          ..style = PaintingStyle.fill;

  void setBackgroundColor(Color backgroundColor) {
    _backgroundPaint.color = backgroundColor;
  }

  void undo() {
    if (!_inDrag) {
      if (_paths.isNotEmpty) {
        _redoPaths.add(_paths.last);
      }
      _paths.removeLast();
    }
  }

  void redo() {
    if (_redoPaths.isNotEmpty) {
      _paths.add(_redoPaths.last);
      _redoPaths.removeLast();
    }
  }

  void clear() {
    if (!_inDrag) {
      _paths.clear();
      _redoPaths.clear();
    }
  }

  void addRect(Rect rect) {
    if (!_inDrag) {
      _inDrag = true;
      Path path = Path();
      path.addRect(rect);
      _paths.add(_Path(
        info: _RectPathInfo(rect: rect),
        paint: currentPaint..style = PaintingStyle.fill,
      ));
    }
  }

  void addTap(Offset point) {
    if (!_inDrag) {
      _inDrag = true;
      _paths.add(_Path(
        info: _CirclePathInfo(
          point: point,
          radius: currentPaint.strokeWidth,
        ),
        paint: currentPaint,
      ));
    }
  }

  void add(Offset startPoint) {
    if (!_inDrag) {
      _inDrag = true;
      _paths.add(_Path(
        info: _LinePathInfo(
          startingPoint: startPoint,
          lines: [],
        ),
        paint: currentPaint,
      ));
    }
  }

  void updateCurrent(Offset nextPoint) {
    if (_inDrag) {
      _LinePathInfo path = _paths.last.info as _LinePathInfo;
      path.lines.add(nextPoint);
    }
  }

  void endCurrent() {
    _inDrag = false;
  }

  void draw(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final path in _paths) {
      canvas.drawPath(path.info.path, path.paint);
    }
    canvas.drawRect(
      Rect.fromLTWH(0.0, 0.0, size.width, size.height),
      _backgroundPaint,
    );
    canvas.restore();
  }

  // Map<String, dynamic> toJson() {
  //   _paths.map<Map<String, dynamic>>((entry) {
  //     final path = entry.key;
  //     final paint = entry.value;

  //     return {
  //       'a': path.
  //     };
  //   });
  // }
}
