part of 'painter.dart';

abstract class _PathInfo {
  const _PathInfo();

  Path get path;

  Map<String, dynamic> get json;

  static _PathInfo _fromJson(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'line':
        return _LinePathInfo.fromJson(data);
      case 'circle':
        return _CirclePathInfo.fromJson(data);
      case 'rect':
        return _RectPathInfo.fromJson(data);
      default:
        throw UnsupportedError('${data['type']} is not a supported path type');
    }
  }
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

  @override
  Map<String, dynamic> get json {
    return {
      'type': 'line',
      'startingPointX': startingPoint.dx,
      'startingPointY': startingPoint.dy,
      'lines': lines.map<Map<String, dynamic>>((line) {
        return {
          'x': line.dx,
          'y': line.dy,
        };
      }).toList(),
    };
  }

  static _LinePathInfo fromJson(Map<String, dynamic> json) {
    return _LinePathInfo(
      startingPoint: Offset(
        json['startingPointX'].toDouble(),
        json['startingPointY'].toDouble(),
      ),
      lines: (json['lines'] as List)
          .cast<Map<String, dynamic>>()
          .map<Offset>((offset) {
        return Offset(
          offset['x'].toDouble(),
          offset['y'].toDouble(),
        );
      }).toList(),
    );
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

  @override
  Map<String, dynamic> get json {
    return {
      'type': 'circle',
      'pointX': point.dx,
      'pointY': point.dy,
      'radius': radius,
    };
  }

  static _CirclePathInfo fromJson(Map<String, dynamic> json) {
    return _CirclePathInfo(
      point: Offset(
        json['pointX'].toDouble(),
        json['pointY'].toDouble(),
      ),
      radius: json['radius'].toDouble(),
    );
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

  @override
  Map<String, dynamic> get json {
    return {
      'type': 'rect',
      'left': rect.left,
      'top': rect.top,
      'right': rect.right,
      'bottom': rect.bottom,
    };
  }

  static _RectPathInfo fromJson(Map<String, dynamic> json) {
    return _RectPathInfo(
      rect: Rect.fromLTRB(
        json['left'].toDouble(),
        json['top'].toDouble(),
        json['right'].toDouble(),
        json['bottom'].toDouble(),
      ),
    );
  }
}

class _Path {
  final _PathInfo info;
  final Paint paint;

  const _Path({required this.info, required this.paint});
}

extension _PaintExtension on Paint {
  Map<String, dynamic> toJson() {
    return {
      'color': color.toHex(),
      'strokeWidth': strokeWidth,
      'style': style.name,
      'blendMode': blendMode.name,
    };
  }

  static Paint fromJson(Map<String, dynamic> json) {
    return Paint()
      ..color = _HexColor.fromHex(json['color'])
      ..strokeWidth = json['strokeWidth'].toDouble()
      ..style = PaintingStyle.values.firstWhere(
        (style) => style.name == json['style'],
        orElse: () => PaintingStyle.fill,
      )
      ..blendMode = BlendMode.values.firstWhere(
        (mode) => mode.name == json['blendMode'],
        orElse: () => BlendMode.srcOver,
      );
  }
}

extension _HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String toHex() => '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}'
      '${alpha.toRadixString(16).padLeft(2, '0')}';
}

class _PathHistory {
  final List<_Path> _redoPaths = [];
  final List<_Path> _paths = [];

  Color color;
  double strokeWidth;
  BlendMode blendMode = BlendMode.srcOver;

  final Paint _backgroundPaint = Paint()..blendMode = BlendMode.dstOver;
  bool _inDrag = false;

  bool get isEmpty => _paths.isEmpty || (_paths.length == 1 && _inDrag);

  _PathHistory()
      : color = Colors.black,
        strokeWidth = 1.0;

  factory _PathHistory.fromJson(Map<String, dynamic> json) {
    return _PathHistory().._paths.addAll(_fromJson(json));
  }

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
        paint: Paint()
          ..style = PaintingStyle.fill
          ..color = color
          ..strokeWidth = strokeWidth
          ..blendMode = blendMode,
      ));
    }
  }

  void addTap(Offset point) {
    if (!_inDrag) {
      _inDrag = true;
      _paths.add(_Path(
        info: _CirclePathInfo(
          point: point,
          radius: strokeWidth / 2,
        ),
        paint: Paint()
          ..style = PaintingStyle.fill
          ..color = color
          ..strokeWidth = strokeWidth
          ..blendMode = blendMode,
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
        paint: Paint()
          ..style = PaintingStyle.stroke
          ..color = color
          ..strokeWidth = strokeWidth
          ..blendMode = blendMode,
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
      canvas.drawPath(
        path.info.path,
        path.paint
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0.0, 0.0, size.width, size.height),
      _backgroundPaint,
    );
    canvas.restore();
  }

  Map<String, dynamic> toJson() {
    return {
      'paths': _paths.map<Map<String, dynamic>>((path) {
        return {
          'path': path.info.json,
          'paint': path.paint.toJson(),
        };
      }).toList(),
    };
  }

  static Iterable<_Path> _fromJson(Map<String, dynamic> json) {
    return (json['paths'] as List).cast<Map<String, dynamic>>().map((e) {
      final paint = _PaintExtension.fromJson(e['paint']);
      final info = _PathInfo._fromJson(e['path']);

      return _Path(info: info, paint: paint);
    });
  }
}
