import 'package:flutter/material.dart';
import 'package:pcanvas_flutter/pcanvas_flutter.dart';

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

    return true;
  }

  int rectX = 10;
  int rectY = 10;
  PColor rectColor = PColor.colorRed.copyWith(alpha: 0.30);

  @override
  bool paint(PCanvas pCanvas) {
    // Clear the canvas with `colorGrey`:
    pCanvas.clear(style: PStyle(color: PColor.colorGrey));

    // Draw an image fitting the target area:
    pCanvas.drawImageFitted(img1, 0, 0, pCanvas.width ~/ 2, pCanvas.height);

    // Draw an image centered at `area` with scale `0.3`:
    pCanvas.centered(
      area: PRectangle(0, 0, pCanvas.width ~/ 2, pCanvas.height * 0.50),
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
      area: PRectangle(0, 0, pCanvas.width ~/ 2, pCanvas.height * 0.30),
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
  }
}
