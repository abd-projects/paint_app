import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';

void main() {
  runApp(const App());
}

class DrawingPoint {
  final Offset point;
  final double brushSize;
  final Color color;
  final List<Offset> sprayPoints;
  DrawingPoint(this.point, this.brushSize, this.color, this.sprayPoints);
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PaintPage(),
    );
  }
}

class PaintPage extends StatefulWidget {
  const PaintPage ({super.key});

  @override
  State<PaintPage> createState() {
    return PaintPageState();
  }
}

class ColorSquarePainter extends CustomPainter {
  final double hue;
  final double saturation;
  final double brightness;
  ColorSquarePainter(this.hue, this.saturation, this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    Color hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    paint.shader = LinearGradient(
      colors: [
        Colors.white,
        hueColor,
      ],
    ).createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
    double x = saturation*size.width;
    double y = (1-brightness)*size.height;
    Paint circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(x,y),7,circlePaint);
  }

  @override
  bool shouldRepaint(covariant ColorSquarePainter oldDelegate) {
    return oldDelegate.hue!=hue||oldDelegate.saturation!=saturation||oldDelegate.brightness!=brightness;
  }
}

class HuePainter extends CustomPainter {
  final double hue;
  HuePainter(this.hue);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.red,
        Colors.yellow,
        Colors.green,
        Colors.cyan,
        Colors.blue,
        Colors.purple,
        Colors.red,
      ],
    ).createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
    double y = (hue/360)*size.height;
    Paint circlePaint =  Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.width/2,y),7,circlePaint);
  }

  @override
  bool shouldRepaint(covariant HuePainter oldDelegate) {
      return oldDelegate.hue!=hue;
  }
}

class OpacityPainter extends CustomPainter {
  final Color color;
  final double opacity;
  OpacityPainter(this.color, this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 1.0),
      ],
    ).createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
    double y = opacity*size.height;
    Paint circlePaint =  Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.width/2,y),7,circlePaint);
  }

  @override
  bool shouldRepaint(covariant OpacityPainter oldDelegate) {
      return oldDelegate.color!=color||oldDelegate.opacity!=opacity;
  }
}

abstract class CanvasObject {}

class BrushStroke extends CanvasObject {
  final List<DrawingPoint> points;
  final BrushType brushType;
  BrushStroke(this.points, this.brushType);
}

enum ToolType {
  eyedropper,
  brush,
  text,
  shape,
}

enum BrushType {
  normal,
  pencil,
  marker,
  highlighter,
  spray,
  eraser,
}

enum ShapeType {
  line,
  rectangle,
  circle,
  triangle,
  arrow,
}

class TextObject extends CanvasObject {
  final String text;
  final Offset position;
  final double fontSize;
  final Color color;
  final String fontFamily;
  TextObject(this.text, this.position, this.fontSize, this.color, this.fontFamily);
}

class ImageObject extends CanvasObject {
  final ui.Image image;
  Offset position;
  double width;
  double height;
  bool finalized;
  ImageObject(this.image, this.position, this.width, this.height, this.finalized);
}

class PaintPageState extends State<PaintPage> {
  double canvasWidth = 1080;
  double canvasHeight = 1920;
  Size canvasAreaSize = Size.zero;

  List<CanvasObject> objects = [];
  List<CanvasObject> undoStack = [];
  List<DrawingPoint> currentStroke = [];

  int pointerCount = 0;
  double canvasScale = 1.0;
  double startScale = 0;
  Offset canvasOffset = Offset.zero;
  Offset startOffset = Offset.zero;
  Offset startFocalPoint = Offset.zero;

  ToolType selectedTool = ToolType.brush;

  Color selectedColor = Colors.black;
  double hue = 0;
  double saturation = 0;
  double brightness = 0;
  double opacity = 1;
  final TextEditingController redCon = TextEditingController();
  final TextEditingController greenCon = TextEditingController();
  final TextEditingController blueCon = TextEditingController();
  final TextEditingController aCon = TextEditingController();
  final GlobalKey canvasKey = GlobalKey();

  BrushType selectedBrush = BrushType.normal;
  double brushSize = 5;
  Random random = Random();

  String textValue = "";
  String selectedFont = "Roboto";
  double textSize = 30;
  bool editingText = false;
  Offset textPosition = const Offset(50, 50);
  final TextEditingController textCon = TextEditingController();
  final List<String> fonts = [
    "Roboto",
    "Arial",
    "Courier New",
    "Times New Roman",
  ];

  ImageObject? selectedImage;
  bool resizingImage = false;
  bool movingImage = false;
  Offset imageInteractionStart = Offset.zero;
  Offset imageStartPosition = Offset.zero;
  double imageStartWidth = 0;
  double imageStartHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showCanvasSetup();
    });
  }

  void showCanvasSetup({bool newDrawing = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Choose Canvas Orientation"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    canvasWidth = 1920;
                    canvasHeight = 1080;

                    if (newDrawing) {
                      objects.clear();
                      undoStack.clear();
                      currentStroke.clear();
                    }

                    if (canvasAreaSize != Size.zero) {
                      fitCanvasToScreen(canvasAreaSize);
                    }
                  });
                  Navigator.pop(dialogContext);
                },
                icon: const Icon(Icons.landscape),
                label: const Text("Landscape"),
              ),

              const SizedBox(
                height: 15,
              ),

              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    canvasWidth = 1080;
                    canvasHeight = 1920;

                    if (newDrawing) {
                      objects.clear();
                      undoStack.clear();
                      currentStroke.clear();
                    }

                    if (canvasAreaSize != Size.zero) {
                      fitCanvasToScreen(canvasAreaSize);
                    }
                  });
                  Navigator.pop(dialogContext);
                },
                icon: const Icon(Icons.portrait),
                label: const Text("Portrait"),
              ),
            ],
          ),
        );
      },
    );
  }

  void fitCanvasToScreen(Size availableSize) {
    final widthScale = (availableSize.width * 0.95) / canvasWidth;
    final heightScale = (availableSize.height * 0.95) / canvasHeight;
    final newScale = min(widthScale, heightScale);
    final displayedWidth = canvasWidth * newScale;
    final displayedHeight = canvasHeight * newScale;

    canvasScale = newScale;
    canvasOffset = Offset(
      (availableSize.width - displayedWidth) / 2,
      (availableSize.height - displayedHeight) /2
    );
  }

  void startDrawing(DragStartDetails details) {
    RenderBox box = canvasKey.currentContext!.findRenderObject() as RenderBox;
    Size canvasSize = box.size;
    if (details.localPosition.dx < 0 ||
        details.localPosition.dy < 0 ||
        details.localPosition.dx > canvasSize.width ||
        details.localPosition.dy > canvasSize.height) {
      return;
    }
    List<Offset> sprayPoints = [];
    for (int j = 0; j < 20; j++) {
      double angle = random.nextDouble() * 2 * pi;
      double distance = random.nextDouble() * brushSize;
      double dx = cos(angle) * distance;
      double dy = sin(angle) * distance;
      double sprayX = details.localPosition.dx + dx;
      double sprayY = details.localPosition.dy + dy;
      if (sprayX>=0&&sprayY>=0&&sprayX<=canvasSize.width&&sprayY<=canvasSize.height) {
        sprayPoints.add(Offset(sprayX, sprayY));
      }
    }
    setState(() {
      currentStroke.add(
        DrawingPoint(
          details.localPosition,
          brushSize,
          selectedColor,
          sprayPoints,
        ),
      );
    });
  }

  void whileDrawing(Offset position) {
    RenderBox box = canvasKey.currentContext!.findRenderObject() as RenderBox;
    Size canvasSize = box.size;
    if (position.dx<0||position.dy<0||position.dx>canvasSize.width||position.dy>canvasSize.height) {
      return;
    }
    List<Offset> sprayPoints = [];
    for (int j = 0; j < 20; j++) {
      double angle = random.nextDouble() * 2 * pi;
      double distance = random.nextDouble() * brushSize;
      double dx = cos(angle) * distance;
      double dy = sin(angle) * distance;
      double sprayX = position.dx + dx;
      double sprayY = position.dy + dy;
      if (sprayX>=0&&sprayY>=0&&sprayX<=canvasSize.width&&sprayY<=canvasSize.height) {
        sprayPoints.add(Offset(sprayX, sprayY));
      }
    }
    setState(() {
      currentStroke.add(
        DrawingPoint(
          position,
          brushSize,
          selectedColor,
          sprayPoints,
        ),
      );
    });
  }

  void stopDrawing(DragEndDetails details) {
    setState(() {
      objects.add(BrushStroke(currentStroke, selectedBrush));
      currentStroke = [];
      undoStack.clear();
    });
  }

  void undo() {
    if (objects.isNotEmpty) {
      setState(() {
        undoStack.add(objects.removeLast());
      });
    }
  }

  void redo() {
    if (undoStack.isNotEmpty) {
      setState(() {
        objects.add(undoStack.removeLast());
      });
    }
  }

  void updateSquare(Offset position, StateSetter dialogSetState) {
    double x = position.dx.clamp(0,150);
    double y = position.dy.clamp(0,150);
    Color newColor = HSVColor.fromAHSV(opacity, hue, saturation, brightness).toColor();
    setState(() {
      selectedColor = newColor;
    });
    dialogSetState(() {
      saturation = x/150;
      brightness = 1-(y/150);
      selectedColor = newColor;
    });
    updateARGBFromSliders(dialogSetState);
  }

  void updateHue(double y, StateSetter dialogSetState) {
    y = y.clamp(0,150);
    Color newColor = HSVColor.fromAHSV(opacity, hue, saturation, brightness).toColor();
    setState(() {
      selectedColor = newColor;
    });
    dialogSetState(() {
      hue = (y/150)*360;
      selectedColor = newColor;
    });
    updateARGBFromSliders(dialogSetState);
  }

  void updateOpacity(double y, StateSetter dialogSetState) {
    y = y.clamp(0,150);
    Color newColor = HSVColor.fromAHSV(opacity, hue, saturation, brightness).toColor();
    setState(() {
      selectedColor = newColor;
    });
    dialogSetState(() {
      opacity = y/150;
      selectedColor = newColor;
    });
    updateARGBFromSliders(dialogSetState);
  }

  void updateARGBFromSliders(StateSetter dialogSetState) {
    dialogSetState(() {
      redCon.text = (selectedColor.r*255).round().toString();
      greenCon.text = (selectedColor.g*255).round().toString();
      blueCon.text = (selectedColor.b*255).round().toString();
      aCon.text = (selectedColor.a*100).round().toString();
    });
  }

  void updateARGBFromFields(StateSetter dialogSetState) {
    int red = int.tryParse(redCon.text)??0;
    int green = int.tryParse(greenCon.text)??0;
    int blue = int.tryParse(blueCon.text)??0;
    int alpha = int.tryParse(aCon.text)??100;
    red = red.clamp(0,255);
    green = green.clamp(0,255);
    blue = blue.clamp(0,255);
    alpha = alpha.clamp(0,100);
    Color newColor = Color.fromARGB((alpha*255/100).round(), red, green, blue);
    HSVColor hsv = HSVColor.fromColor(newColor);
    setState(() {
      selectedColor = newColor;
    });
    dialogSetState(() {
      selectedColor = newColor;
      hue = hsv.hue;
      saturation = hsv.saturation;
      brightness = hsv.value;
      opacity = alpha/100;
    });
  }

  Future<void> pickColor(Offset position) async {
    RenderRepaintBoundary boundary = canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    ByteData? data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data==null) {
      return;
    }
    int x = position.dx.toInt();
    int y = position.dy.toInt();
    if (x<0||y<0||x>=image.width||y>=image.height) {
      return;
    }
    int pixelIndex = (y*image.width+x)*4;
    int r = data.getUint8(pixelIndex);
    int g = data.getUint8(pixelIndex+1);
    int b = data.getUint8(pixelIndex+2);
    int a = data.getUint8(pixelIndex+3);
    setState(() {
      selectedColor = Color.fromARGB(a, r, g, b);
      selectedTool = ToolType.brush;
    });
  }

  void showTextDialog() {
  textCon.clear();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, dialogSetState) {
          return AlertDialog(
            title: const Text("Enter Text"),
            content: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textCon,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: "Enter Text",
                    ),
                  ),

                  const SizedBox(
                    height: 20
                  ),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Font:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 10
                  ),

                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: fonts.length,
                      itemBuilder: (context, index) {
                        final font = fonts[index];
                        final isSelected = selectedFont == font;
                        return GestureDetector(
                          onTap: () {
                            dialogSetState(() {
                              selectedFont = font;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "Aa",
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 26,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (textCon.text.isEmpty) {
                    return;
                  }
                  textValue = textCon.text;
                  Navigator.pop(dialogContext);
                  setState(() {
                    editingText = true;
                    textPosition = const Offset(50, 50);
                  });
                },
                child: const Text("Enter"),
              ),
            ],
          );
        },
      );
    },
  );
}

  Widget buildTextEditor() {
    return Positioned(
      left: canvasOffset.dx + textPosition.dx * canvasScale,
      top: canvasOffset.dy + textPosition.dy * canvasScale,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            textPosition += details.delta / canvasScale;
          });
        },
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            border: Border.all(),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  textValue,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: textSize * canvasScale,
                    fontFamily: selectedFont,
                    color: selectedColor,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: addTextToCanvas,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 22,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    setState(() {
                      textSize += details.delta.dx*0.2;
                      if (textSize<10) {
                        textSize = 10;
                      } 
                    });
                  },
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void addTextToCanvas () {
    setState(() {
      objects.add(TextObject(
        textValue,
        textPosition + const Offset(8,8),
        textSize,
        selectedColor,
        selectedFont
      ));
      editingText = false;
    });
  }

  Future<void> importImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) {
      return;
    }

    final Uint8List bytes = await file.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;
    double imageWidth = image.width.toDouble();
    double imageHeight = image.height.toDouble();
    double scale = min(
      canvasWidth / imageWidth,
      canvasHeight / imageHeight,
    );

    if (scale > 1) {
      scale = 1;
    }

    imageWidth *= scale;
    imageHeight *= scale;
    double imageX = (canvasWidth - imageWidth) / 2;
    double imageY = (canvasHeight - imageHeight) / 2;
    ImageObject newImage = ImageObject(
      image,
      Offset(imageX, imageY),
      imageWidth,
      imageHeight,
      false,
    );

    setState(() {
      objects.add(newImage);
      selectedImage = newImage;
      undoStack.clear();
    });
  }

  Future<void> exportImage() async {
    RenderRepaintBoundary boundary = canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 1);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData==null) {
      return;
    }

    Uint8List bytes = byteData.buffer.asUint8List();

    await Gal.putImageBytes(bytes, name: "Abd_Paint_${DateTime.now().millisecondsSinceEpoch}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [

            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, dialogSetState) {
                        final List<Color> baseColors = [
                          Colors.black,
                          Colors.white,
                          Colors.red,
                          Colors.green,
                          Colors.blue,
                          Colors.yellow,
                          Colors.orange,
                          Colors.purple,
                          Colors.pink,
                          Colors.brown,
                          Colors.grey,
                          Colors.cyan,
                        ];
                        return AlertDialog(
                          content: SizedBox(
                            height: 350,
                            width: 300,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 300,
                                  height: 100,
                                  child: GridView.count(
                                    crossAxisCount: 6,
                                    children: baseColors.map((color) {
                                      return GestureDetector(
                                        onTap: () {
                                          HSVColor hsv = HSVColor.fromColor(color);
                                          setState(() {
                                            selectedColor = color;
                                          });
                                          dialogSetState(() {
                                            selectedColor = color;
                                            hue = hsv.hue;
                                            saturation = hsv.saturation;
                                            brightness = hsv.value;
                                            opacity = hsv.alpha;
                                        });
                                          updateARGBFromSliders(dialogSetState);
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

                                const Divider(),

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onPanStart: (details) {
                                        updateSquare(details.localPosition, dialogSetState);
                                      },
                                      onPanUpdate: (details) {
                                        updateSquare(details.localPosition, dialogSetState);
                                      },
                                      child: SizedBox(
                                        width: 140,
                                        height: 140,
                                        child: CustomPaint(
                                          painter: ColorSquarePainter(hue, saturation, brightness),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 10,
                                    ),

                                    GestureDetector(
                                      onPanStart: (details) {
                                        updateHue(details.localPosition.dy, dialogSetState);
                                      },
                                      onPanUpdate: (details) {
                                        updateHue(details.localPosition.dy, dialogSetState);
                                      },
                                      child: SizedBox(
                                        width: 20,
                                        height: 140,
                                        child: CustomPaint(
                                          painter: HuePainter(hue),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 10,
                                    ),

                                    GestureDetector(
                                      onPanStart: (details) {
                                        updateOpacity(details.localPosition.dy, dialogSetState);
                                      },
                                      onPanUpdate: (details) {
                                        updateOpacity(details.localPosition.dy, dialogSetState);
                                      },
                                      child: SizedBox(
                                        width: 20,
                                        height: 140,
                                        child: CustomPaint(
                                          painter: OpacityPainter(selectedColor, opacity),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 10,
                                    ),

                                    Column(
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('A:'),
                                            SizedBox(
                                              width: 40,
                                              child: TextField(
                                                controller: aCon,
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 5,
                                                  ),
                                                ),
                                                onChanged: (value) {
                                                  updateARGBFromFields(dialogSetState);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),

                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('R:'),
                                            SizedBox(
                                              width: 40,
                                              child: TextField(
                                                controller: redCon,
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 5,
                                                  ),
                                                ),
                                                onChanged: (value) {
                                                  updateARGBFromFields(dialogSetState);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),

                                        Row(
                                          children: [
                                            const Text('G:'),
                                            SizedBox(
                                              width: 40,
                                              child: TextField(
                                                controller: greenCon,
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 5,
                                                  ),
                                                ),
                                                onChanged: (value) {
                                                  updateARGBFromFields(dialogSetState);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),

                                        Row(
                                          children: [
                                            const Text('B:'),
                                            SizedBox(
                                              width: 40,
                                              child: TextField(
                                                controller: blueCon,
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 5,
                                                  ),
                                                ),
                                                onChanged: (value) {
                                                  updateARGBFromFields(dialogSetState);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 10,
                                ),

                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedTool = ToolType.eyedropper;
                                    });
                                    Navigator.pop(context);
                                  },
                                  icon: Icon(Icons.colorize),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              icon: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: selectedColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    const sizes = [1, 5, 10, 15, 20];
                    return AlertDialog(
                      title: const Center(
                        child: Text("Choose Brush Size"),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final size in sizes)
                                TextButton(
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      brushSize = size.toDouble();
                                      textSize = size.toDouble()+5;
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Text('$size'),
                                ),
                            ],
                          ),
                          const Divider(),
                          TextField(
                            textAlign: TextAlign.center,
                            controller: TextEditingController(),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              hintText: "Enter Custom Value",
                            ),
                            onSubmitted: (text) {
                              final value = double.tryParse(text);
                              if (value != null) {
                                setState(() {
                                  brushSize = value;
                                  textSize = value+5;
                                });
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Icon(Icons.numbers),
            ),

            PopupMenuButton<String>(
              icon: const Icon(Icons.brush),
              onSelected: (String value) {
                if (value=="text") {
                  showTextDialog();
                  return;
                }
                else {
                  setState(() {
                    selectedBrush = BrushType.values.firstWhere(
                      (brush) => brush.name==value,
                    );
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: "normal",
                  child: Text("Normal"),
                ),
                const PopupMenuItem(
                  value: "pencil",
                  child: Text("Pencil"),
                ),
                const PopupMenuItem(
                  value: "marker",
                  child: Text("Marker"),
                ),
                const PopupMenuItem(
                  value: "highlighter",
                  child: Text("Highlighter"),
                ),
                const PopupMenuItem(
                  value: "spray",
                  child: Text("Spray"),
                ),
                const PopupMenuItem(
                  value: "eraser",
                  child: Text("Eraser"),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: "text",
                  child: Text("Text")
                ),
              ],
            ),

            IconButton(
              onPressed: undo,
              icon: Icon(Icons.undo),
            ),

            IconButton(
              onPressed: redo,
              icon: Icon(Icons.redo),
            ),  

            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  objects.clear();
                  undoStack.clear();
                });
              },
            ),

            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                if (value=="import") {
                  importImage();
                }
                if (value=="export") {
                  exportImage();
                }
                if (value=="new") {
                  showCanvasSetup(newDrawing: true);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: "import",
                  child: Text("Import Image"),
                ),
                const PopupMenuItem(
                  value: "export",
                  child: Text("Export Image"),
                ),
                const PopupMenuItem(
                  value: "new",
                  child: Text("New Drawing"),
                )
              ],
            ),
          ],
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          if (canvasAreaSize != constraints.biggest) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                canvasAreaSize = constraints.biggest;
                fitCanvasToScreen(canvasAreaSize);
              }
            });
          }
          return Stack(
            children: [
              Listener(
                onPointerDown: (event) {
                  pointerCount++;
                },
                onPointerUp: (event) {
                  pointerCount--;
                },
                onPointerCancel: (event) {
                  pointerCount--;
                },
                child: GestureDetector(
                  onScaleStart: (details) {
                    if (pointerCount == 1) {
                      Offset position = Offset(
                        (details.localFocalPoint.dx - canvasOffset.dx) / canvasScale,
                        (details.localFocalPoint.dy - canvasOffset.dy) / canvasScale,
                      );
                      if (selectedImage != null) {
                        double handleSize = 35;
                        Rect handleRect = Rect.fromLTWH(
                          selectedImage!.position.dx + selectedImage!.width - handleSize,
                          selectedImage!.position.dy + selectedImage!.height - handleSize,
                          handleSize,
                          handleSize,
                        );
                        if (handleRect.contains(position)) {
                          resizingImage = true;
                          movingImage = false;
                          imageInteractionStart = position;
                          imageStartWidth = selectedImage!.width;
                          imageStartHeight = selectedImage!.height;
                          return;
                        }
                        Rect imageRect = Rect.fromLTWH(
                          selectedImage!.position.dx,
                          selectedImage!.position.dy,
                          selectedImage!.width,
                          selectedImage!.height,
                        );
                        if (imageRect.contains(position)) {
                          movingImage = true;
                          resizingImage = false;
                          imageInteractionStart = position;
                          imageStartPosition = selectedImage!.position;
                          return;
                        }
                      }
                      for (int i = objects.length - 1; i >= 0; i--) {
                        if (objects[i] is ImageObject && !(objects[i] as ImageObject).finalized) {
                          ImageObject image = objects[i] as ImageObject;
                          Rect imageRect = Rect.fromLTWH(
                            image.position.dx,
                            image.position.dy,
                            image.width,
                            image.height,
                          );
                          if (imageRect.contains(position)) {
                            setState(() {
                              selectedImage = image;
                            });
                            movingImage = true;
                            resizingImage = false;
                            imageInteractionStart = position;
                            imageStartPosition = image.position;
                            return;
                          }
                        }
                      }
                      setState(() {
                        if (selectedImage != null) {
                          selectedImage!.finalized = true;
                        }
                        selectedImage = null;
                      });
                      movingImage = false;
                      resizingImage = false;
                      if (selectedTool == ToolType.brush) {
                        startDrawing(
                          DragStartDetails(
                            localPosition: position,
                          ),
                        );
                      }
                    }
                    if (pointerCount >= 2) {
                      startScale = canvasScale;
                      startOffset = canvasOffset;
                      startFocalPoint = details.focalPoint;
                    }
                  },
                  onScaleUpdate: (details) {
                    if (pointerCount == 1) {
                      Offset position = Offset(
                        (details.localFocalPoint.dx - canvasOffset.dx) / canvasScale,
                        (details.localFocalPoint.dy - canvasOffset.dy) / canvasScale,
                      );
                      if (resizingImage && selectedImage != null) {
                        double dx = position.dx - imageInteractionStart.dx;
                        double ratio = imageStartHeight / imageStartWidth;
                        double newWidth = imageStartWidth + dx;
                        double newHeight = newWidth * ratio;

                        if (newWidth < 50) {
                          newWidth = 50;
                          newHeight = newWidth * ratio;
                        }
                        if (newWidth > canvasWidth - selectedImage!.position.dx) {
                          newWidth = canvasWidth - selectedImage!.position.dx;
                          newHeight = newWidth * ratio;
                        }
                        if (newHeight > canvasHeight - selectedImage!.position.dy) {
                          newHeight = canvasHeight - selectedImage!.position.dy;
                          newWidth = newHeight / ratio;
                        }
                        setState(() {
                          selectedImage!.width = newWidth;
                          selectedImage!.height = newHeight;
                        });
                        return;
                      }
                      if (movingImage && selectedImage != null) {
                        Offset delta = position - imageInteractionStart;
                        double newX = imageStartPosition.dx + delta.dx;
                        double newY =  imageStartPosition.dy + delta.dy;
                        newX = newX.clamp(0, canvasWidth - selectedImage!.width);
                        newY = newY.clamp(0, canvasHeight - selectedImage!.height);

                        setState(() {
                          selectedImage!.position = Offset(newX, newY);
                        });
                        return;
                      }
                      if (selectedTool == ToolType.brush) {
                        whileDrawing(position);
                      }
                    }
                    if (pointerCount >= 2) {
                      setState(() {
                        canvasScale = (startScale * details.scale).clamp(0.1, 5.0);
                        canvasOffset = startOffset + (details.focalPoint - startFocalPoint);
                      });
                    }
                  },
                  onScaleEnd: (details) {
                    if (resizingImage || movingImage) {
                      resizingImage = false;
                      movingImage = false;
                      undoStack.clear();
                      return;
                    }
                    if (currentStroke.isNotEmpty &&
                        selectedTool == ToolType.brush) {
                      stopDrawing(DragEndDetails());
                    }
                  },
                  onTapDown: (details) {
                    if(selectedTool==ToolType.eyedropper) {
                      Offset position = Offset(
                        (details.localPosition.dx - canvasOffset.dx) / canvasScale,
                        (details.localPosition.dy - canvasOffset.dy) / canvasScale,
                      );
                      pickColor(position);
                    }
                  },
                  child: SizedBox.expand(
                    child: Stack(
                      children: [
                        Positioned(
                          left: canvasOffset.dx,
                          top: canvasOffset.dy,
                          child: Transform.scale(
                            alignment: Alignment.topLeft,
                            scale: canvasScale,
                            child: Container(
                              color: Colors.white,
                              child: RepaintBoundary(
                                key: canvasKey,
                                child: SizedBox(
                                  width: canvasWidth,
                                  height: canvasHeight,
                                  child: Container(
                                    color: Colors.white,
                                    child: CustomPaint(
                                      painter: MyPainter(
                                        objects,
                                        currentStroke,
                                        selectedBrush,
                                        selectedImage,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (editingText)
                buildTextEditor(),
            ],
          );
        },  
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  final List<CanvasObject> objects;
  final List<DrawingPoint> currentStroke;
  final BrushType selectedBrush;
  final ImageObject? selectedImage;

  MyPainter(this.objects, this.currentStroke, this.selectedBrush, this.selectedImage);

  void drawBrushStroke(Canvas canvas, BrushStroke stroke) {
    for (int i=0;i<stroke.points.length-1;i++) {
      Paint paint = Paint();
      paint.strokeWidth = stroke.points[i].brushSize;
      paint.color = stroke.points[i].color;
      paint.strokeCap = StrokeCap.round;
      if (stroke.brushType == BrushType.spray) {
        for (Offset sprayPoint in stroke.points[i].sprayPoints) {
          canvas.drawCircle(
            sprayPoint,
            0.5,
            paint,
          );
        }
      }
      else {
        if (stroke.brushType == BrushType.pencil) {
          paint.strokeWidth = stroke.points[i].brushSize * 0.5;
        }
        if (stroke.brushType == BrushType.marker) {
          paint.strokeWidth = stroke.points[i].brushSize * 2;
          paint.color = stroke.points[i].color.withValues(alpha: 0.5);
        }
        if (stroke.brushType == BrushType.highlighter) {
          paint.strokeWidth = stroke.points[i].brushSize * 3;
          paint.color = stroke.points[i].color.withValues(alpha: 0.3);
        }
        if (stroke.brushType == BrushType.eraser) {
          paint.color = Colors.white;
        }
        canvas.drawLine(
          stroke.points[i].point,
          stroke.points[i + 1].point,
          paint,
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (CanvasObject object in objects) {
      if (object is BrushStroke) {
        drawBrushStroke(canvas, object);
      }
      if (object is TextObject) {
        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: object.text,
            style: TextStyle(
              fontSize: object.fontSize,
              fontFamily: object.fontFamily,
              color: object.color,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, object.position);
      }
      if (object is ImageObject) {
        canvas.drawImageRect(
          object.image,
          Rect.fromLTWH(
            0,
            0,
            object.image.width.toDouble(),
            object.image.height.toDouble(),
          ),
          Rect.fromLTWH(
            object.position.dx,
            object.position.dy,
            object.width,
            object.height,
          ),
          Paint(),
        );
      }
    }
    if (currentStroke.isNotEmpty) {
      drawBrushStroke(canvas, BrushStroke(currentStroke, selectedBrush));
    }
    if (selectedImage != null) {
      Paint borderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRect(
        Rect.fromLTWH(
          selectedImage!.position.dx,
          selectedImage!.position.dy,
          selectedImage!.width,
          selectedImage!.height,
        ),
        borderPaint,
      );
      Paint handlePaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(
          selectedImage!.position.dx + selectedImage!.width - 25,
          selectedImage!.position.dy + selectedImage!.height - 25,
          25,
          25,
        ),
        handlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) {
    return true;
  }
} 