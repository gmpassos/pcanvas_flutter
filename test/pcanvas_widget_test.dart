import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pcanvas_flutter/pcanvas_flutter.dart';

void main() {
  testWidgets('PCanvasWidget test', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(10, 10);
    tester.binding.window.devicePixelRatioTestValue = 3;
    tester.binding.window.paddingTestValue = WindowPadding.zero;

    await tester.pumpWidget(const MyApp());

    var element = find.byType(PCanvasWidget).evaluate().first;

    var pCanvasWidget = element.widget as PCanvasWidget;
    await _pumpFrames(tester, pCanvasWidget);

    var pCanvas = pCanvasWidget.pCanvas;

    await pCanvas.waitLoading();
    await _pumpFrames(tester, pCanvasWidget);

    await _refresh(tester, pCanvas);

    await _pumpFrames(tester, pCanvasWidget);

    var painter = pCanvas.painter as MyCanvasPainter;

    var pixels1 = await _getPixels(tester, pCanvas);

    var c1 = pixels1!.formatColor(PColor.colorGrey);
    expect(pixels1.pixels.every((p) => p == c1), isTrue);

    painter.bgColor = PColor.colorBlue;

    await _refresh(tester, pCanvas);
    await _pumpFrames(tester, pCanvasWidget);

    var pixels2 = await _getPixels(tester, pCanvas);

    var c2 = pixels2!.formatColor(PColor.colorBlue);
    expect(pixels2.pixels.every((p) => p == c2), isTrue);

    painter.gradient = true;

    await pCanvas.refresh();

    var pixels3 = await _getPixels(tester, pCanvas);

    expect(pixels3!.pixelColor(0, 0).maxDistance(painter.bgColor),
        inInclusiveRange(0, 44));

    expect(
        pixels3
            .pixelColor(pixels3.width - 1, pixels3.height - 1)
            .maxDistance(PColor.colorBlack),
        inInclusiveRange(0, 44));
  });
}

Future<PCanvasPixels?> _getPixels(
        WidgetTester tester, PCanvasFlutter pCanvas) =>
    tester.binding.runAsync(() => pCanvas.pixels);

Future<bool?> _refresh(WidgetTester tester, PCanvasFlutter pCanvas) =>
    tester.binding.runAsync(() => pCanvas.refresh());

Future<void> _pumpFrames(WidgetTester tester, PCanvasWidget pCanvasWidget) =>
    tester.pumpFrames(pCanvasWidget, const Duration(milliseconds: 30));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => PCanvasWidget(MyCanvasPainter());
}

class MyCanvasPainter extends PCanvasPainter {
  bool gradient = false;
  PColorRGB bgColor = PColor.colorGrey;

  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    if (pCanvas.width == 0 || pCanvas.height == 0) return false;

    if (gradient) {
      pCanvas.fillTopDownGradient(
          0, 0, pCanvas.width, pCanvas.height, bgColor, PColor.colorBlack);
    } else {
      pCanvas.clear(style: PStyle(color: bgColor));
    }

    return true;
  }
}
