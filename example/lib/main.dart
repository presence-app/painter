import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:painter/painter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Painter Example',
      home: ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({Key? key}) : super(key: key);

  @override
  _ExamplePageState createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  bool _finished = false;
  PainterController _controller = _newController();

  @override
  void initState() {
    super.initState();
  }

  static PainterController _newController() {
    PainterController controller = PainterController();
    controller.thickness = 5.0;
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actions;
    if (_finished) {
      actions = <Widget>[
        IconButton(
          icon: const Icon(Icons.content_copy),
          tooltip: 'New Painting',
          onPressed: () => setState(() {
            _finished = false;
            _controller = _newController();
          }),
        ),
      ];
    } else {
      actions = <Widget>[
        IconButton(
          icon: const Icon(
            Icons.undo,
          ),
          tooltip: 'Undo',
          onPressed: () {
            if (_controller.isEmpty) {
              showModalBottomSheet(
                context: context,
                builder: (context) => const Text('Nothing to undo'),
              );
            } else {
              _controller.undo();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          tooltip: 'Redo',
          onPressed: _controller.redo,
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: 'Clear',
          onPressed: _controller.clear,
        ),
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: () => _show(_controller.finish(), context),
        ),
        IconButton(
          icon: const Icon(Icons.check),
          tooltip: 'See json',
          onPressed: () {
            final json = _controller.toJson();

            String getPrettyJSONString(jsonObject) {
              var encoder = const JsonEncoder.withIndent("     ");
              return encoder.convert(jsonObject);
            }

            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              final controller = PainterController.fromJson(json);

              return Scaffold(
                appBar: AppBar(),
                body: ListView(children: [
                  SizedBox(
                    height: 400,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: Container(
                          color: Colors.blue,
                          child: IgnorePointer(child: Painter(controller)),
                        ),
                      ),
                    ),
                  ),
                  Text(getPrettyJSONString(json)),
                ]),
              );
            }));
          },
        ),
      ];
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painter Example'),
        actions: actions,
        bottom: PreferredSize(
          preferredSize: Size(MediaQuery.of(context).size.width, 30.0),
          child: DrawBar(_controller),
        ),
      ),
      body: SizedBox(
        height: 400,
        child: Center(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: Container(
              color: Colors.blue,
              child: Painter(_controller),
            ),
          ),
        ),
      ),
    );
  }

  void _show(PictureDetails picture, BuildContext context) {
    setState(() {
      _finished = true;
    });
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('View your image'),
        ),
        body: Container(
          alignment: Alignment.center,
          child: FutureBuilder<Uint8List>(
            future: picture.toPNG(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.done:
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return Image.memory(snapshot.data!);
                  }
                default:
                  return const FractionallySizedBox(
                    widthFactor: 0.1,
                    alignment: Alignment.center,
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: CircularProgressIndicator(),
                    ),
                  );
              }
            },
          ),
        ),
      );
    }));
  }
}

class DrawBar extends StatelessWidget {
  final PainterController _controller;

  const DrawBar(this._controller, [Key? key]) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      Flexible(
        child: StatefulBuilder(builder: (context, setState) {
          return Slider(
            value: _controller.thickness,
            onChanged: (double value) => setState(() {
              _controller.thickness = value;
            }),
            min: 1.0,
            max: 20.0,
            activeColor: Colors.white,
          );
        }),
      ),
      StatefulBuilder(builder: (context, setState) {
        return RotatedBox(
          quarterTurns: _controller.eraseMode ? 2 : 0,
          child: IconButton(
            icon: const Icon(Icons.create),
            tooltip: '${_controller.eraseMode ? 'Disable' : 'Enable'} eraser',
            onPressed: () {
              setState(() {
                _controller.eraseMode = !_controller.eraseMode;
              });
            },
          ),
        );
      }),
      ColorPickerButton(_controller),
    ]);
  }
}

class ColorPickerButton extends StatefulWidget {
  final PainterController _controller;

  const ColorPickerButton(
    this._controller, [
    Key? key,
  ]) : super(key: key);

  @override
  _ColorPickerButtonState createState() => _ColorPickerButtonState();
}

class _ColorPickerButtonState extends State<ColorPickerButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
        icon: Icon(_iconData, color: _color),
        tooltip: 'Change draw color',
        onPressed: _pickColor);
  }

  void _pickColor() {
    Color pickerColor = _color;
    Navigator.of(context)
        .push(MaterialPageRoute(
            fullscreenDialog: true,
            builder: (BuildContext context) {
              return Scaffold(
                  appBar: AppBar(
                    title: const Text('Pick color'),
                  ),
                  body: Container(
                      alignment: Alignment.center,
                      child: ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: (Color c) => pickerColor = c,
                      )));
            }))
        .then((_) {
      setState(() {
        _color = pickerColor;
      });
    });
  }

  Color get _color => widget._controller.drawColor;

  IconData get _iconData => Icons.brush;

  set _color(Color color) {
    widget._controller.drawColor = color;
  }
}
