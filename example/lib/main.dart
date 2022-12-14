import 'package:flutter/material.dart';
import 'package:pcanvas_flutter/pcanvas_flutter.dart';
import 'package:collection/collection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PCanvas - Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: Scaffold(
        appBar: AppBar(title: const Text('PCanvas - Flutter')),
        body: PCanvasWidget(MyCanvasPainter()),
      ),
    );
  }
}

/// The [PCanvas] painter implementation.
class MyCanvasPainter extends PCanvasPainter {
  late PCanvasImage img1;
  late PCanvasImage img2;

  @override
  Future<bool> loadResources(PCanvas pCanvas) async {
    var img1URL = 'https://i.postimg.cc/k5TnC1H9/land-scape-1.jpg';
    var img2URL = 'https://i.postimg.cc/L5sFmw5R/canvas-icon.png';

    pCanvas.log('** Loading images...');

    img1 = pCanvas.createCanvasImage(img1URL);
    img2 = pCanvas.createCanvasImage(img2URL);

    var images = [img1, img2];

    await images.loadAll();

    for (var img in images) {
      pCanvas.log('-- Loaded image: $img');
    }

    pCanvas.log('** Loaded images!');

    {
      var panel = PCanvasPanel2D(
          height: 100,
          width: 200,
          pos: const Point(100, 100),
          zIndex: 999999,
          style: PStyle(color: PColor.colorWhite.copyWith(alpha: 0.50)));

      panel.addElement(PRectangleElement(
          style: PColor.colorRed.toStyle(),
          pos: const Point(10, 20),
          width: 20,
          height: 10));

      var panel2 = PCanvasPanel2D(
          height: 50,
          width: 100,
          pos: const Point(20, 10),
          style: PStyle(color: PColor.colorGrey.copyWith(alpha: 0.50)));

      panel2.addElement(PRectangleElement(
          style: PColor.colorBlue.toStyle(),
          pos: const Point(5, 10),
          width: 10,
          height: 5));

      panel.addElement(panel2);

      pCanvas.addElement(panel);
    }

    return true;
  }

  int rectX = 10;
  int rectY = 10;
  PColor rectColor = PColor.colorRed.copyWith(alpha: 0.30);
  String textExtra = '';

  @override
  bool paint(PCanvas pCanvas) {
    // Clear the canvas with `colorGrey`:
    pCanvas.clear(style: PStyle(color: PColor.colorGrey));

    var canvasWidth = pCanvas.width;
    var canvasHeight = pCanvas.height;

    var canvasWidthHalf = canvasWidth ~/ 2;
    var canvasHeightHalf = canvasHeight ~/ 2;

    // Draw an image fitting the target area:
    pCanvas.drawImageFitted(img1, 0, 0, canvasWidthHalf, canvasHeight);

    // Draw an image centered at `area` with scale `0.3`:
    pCanvas.centered(
      area: PRectangle(0, 0, canvasWidthHalf, canvasHeight * 0.50),
      dimension: img2.dimension,
      scale: 0.3,
      (pc, p, sz) => pc.drawImageScaled(img2, p.x, p.y, sz.width, sz.height),
    );

    // Fill a rectangle at ($rectX,$rectY):
    pCanvas.fillRect(rectX, rectY, 20, 20, PStyle(color: rectColor));

    // Fill a rectangle at (40,10):
    pCanvas.fillRect(40, 10, 20, 20, PStyle(color: PColor.colorGreen));

    var fontPR = PFont('Arial', 24);
    var textPR = 'devicePixelRatio: ${pCanvas.devicePixelRatio}';
    if (textExtra.isNotEmpty) {
      textPR += '\n$textExtra';
    }

    // Measure `text`:
    var m = pCanvas.measureText(textPR, fontPR);

    // Draw `text` at (10,55):
    pCanvas.drawText(textPR, 10, 55, fontPR, PStyle(color: PColor.colorBlack));

    // Stroke a rectangle around the `text`:
    pCanvas.strokeRect(10 - 2, 55 - 2, m.actualWidth + 4, m.actualHeight + 4,
        PStyle(color: PColor.colorYellow));

    var fontHello = PFont('Arial', 48);
    var textHello = 'Hello World!';

    // Draw a text and a shadow at the center of `area`:
    pCanvas.centered(
      area: PRectangle(0, 0, canvasWidthHalf, canvasHeight * 0.30),
      dimension: pCanvas.measureText(textHello, fontHello),
      (pc, p, sz) {
        pc.drawText(textHello, p.x + 4, p.y + 4, fontHello,
            PStyle(color: PColorRGBA(0, 0, 0, 0.30)));
        pc.drawText(
            textHello, p.x, p.y, fontHello, PStyle(color: PColor.colorBlue));
      },
    );

    var path = [100, 10, const Point(130, 25), 100, 40];

    // Stroke a `path`:
    pCanvas.strokePath(path, PStyle(color: PColor.colorRed, size: 3),
        closePath: true);

    pCanvas.fillRightLeftGradient(canvasWidthHalf, 0, canvasWidthHalf,
        canvasHeight, PColorRGB(0, 32, 94), PColor.colorBlack);

    // Fill a circle:
    pCanvas.fillCircle(canvasWidthHalf + (canvasWidthHalf ~/ 2),
        canvasHeightHalf, 20, PStyle(color: PColor.colorGreen));

    return true;
  }

  /// Receives canvas clicks:
  @override
  void onClick(PCanvasEvent event) {
    rectColor = rectColor.copyWith(r: 0, b: 255);

    rectX += 10;
    rectY += 10;

    // Force a refresh of the canvas:
    refresh();

    pCanvas?.log(event);
  }

  int _stepCount = 0;

  @override
  void onKeyDown(PCanvasKeyEvent event) {
    var pCanvas = this.pCanvas!;

    var s = event.code?.toLowerCase() == 'enter' ? '\n' : (event.key ?? '');

    textExtra += s;

    var keyCode = event.code?.toLowerCase() ?? '';
    var key = event.key?.toLowerCase() ?? '';

    var step = 0;

    if (keyCode.contains('right') || key == 'd') {
      if (_stepCount <= 0) {
        _stepCount = 1;
      } else {
        _stepCount++;
      }

      step = _stepCount.clamp(1, 30);
    } else if (keyCode.contains('left') || key == 'a') {
      if (_stepCount >= 0) {
        _stepCount = -1;
      } else {
        _stepCount--;
      }

      step = _stepCount.clamp(-30, -1);
    }

    {
      var rectElem1 = pCanvas
          .selectElementByType<PCanvasPanel2D>()
          .firstOrNull
          ?.selectElementByType<PRectangleElement>()
          .firstOrNull;

      var rectElem2 = pCanvas
          .selectElementByType<PCanvasPanel2D>()
          .firstOrNull
          ?.selectElementByType<PCanvasPanel2D>()
          .firstOrNull
          ?.selectElementByType<PRectangleElement>()
          .firstOrNull;

      rectElem1?.position = rectElem1.position.incrementX(step);
      rectElem2?.position = rectElem2.position.incrementX(step ~/ 2);

      refresh();
    }

    refresh();

    pCanvas.log(event);
  }
}
