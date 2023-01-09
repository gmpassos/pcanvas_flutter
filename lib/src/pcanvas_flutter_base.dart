import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pcanvas/pcanvas.dart';
// ignore: implementation_imports
import 'package:pcanvas/src/pcanvas_bitmap_extension.dart';

/// A [PCanvas] Flutter [Widget].
// ignore: must_be_immutable
class PCanvasWidget extends StatefulWidget {
  final PCanvasPainter _painter;

  final ValueChanged<RawKeyEvent>? onKey;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCallback? onTap;
  final GestureTapCancelCallback? onTapCancel;

  PCanvasWidget(
    this._painter, {
    super.key,
    this.onKey,
    this.onTapDown,
    this.onTapUp,
    this.onTap,
    this.onTapCancel,
  });

  /// The [PCanvas] of this widget.
  late final PCanvasFlutter pCanvas = PCanvasFlutter._(_painter);

  _PCanvasWidgetState? _state;

  @override
  // ignore: no_logic_in_create_state
  State<PCanvasWidget> createState() {
    var state = _state;
    if (state == null) {
      return _state = _PCanvasWidgetState(this, pCanvas);
    } else {
      return _state = state.copy();
    }
  }

  /// Refreshes the [PCanvas] of this widget.
  void refresh() => _state?.refresh();
}

class _PCanvasWidgetState extends State<PCanvasWidget> {
  final PCanvasWidget _widget;
  final PCanvasFlutter _pCanvasFlutter;

  _PCanvasWidgetState(this._widget, this._pCanvasFlutter) {
    _pCanvasFlutter._setup();
    _initialize();
  }

  _PCanvasWidgetState._copy(_PCanvasWidgetState prevState)
      : _widget = prevState._widget,
        _pCanvasFlutter = prevState._pCanvasFlutter,
        _lastOnTapUpEvent = prevState._lastOnTapUpEvent,
        _focusNode = prevState._focusNode;

  PCanvas get pCanvas => _pCanvasFlutter;

  _PCanvasWidgetState copy() => _PCanvasWidgetState._copy(this);

  late final FocusNode _focusNode;

  void _initialize() {
    _focusNode = FocusNode(debugLabel: 'PCanvas:key');

    var canvas = _pCanvasFlutter;
    var painter = canvas.painter;

    var ret = painter.callLoadResources(canvas);

    if (ret is Future<bool>) {
      ret.then((_) => canvas.callPainter());
    } else {
      canvas.callPainter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        var width = constraints.widthConstraints().maxWidth;
        var height = constraints.heightConstraints().maxHeight;

        _pCanvasFlutter._widgetPainter
            ._setElementDimension(width.toInt(), height.toInt());

        refresh();

        return SizedBox(
          width: width,
          height: height,
          child: RawKeyboardListener(
              focusNode: _focusNode,
              onKey: _onKey,
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTap: _onTap,
                onTapCancel: _onTapCancel,
                child: CustomPaint(
                    painter: _pCanvasFlutter._widgetPainter, willChange: true),
              )),
        );
      },
    );
  }

  void refresh() => _pCanvasFlutter.refresh();

  void _onKey(RawKeyEvent keyEvent) {
    String type;

    if (keyEvent is RawKeyDownEvent) {
      type = 'onKeyDown';
    } else if (keyEvent is RawKeyUpEvent) {
      type = 'onKeyUp';
    } else {
      type = 'onKey';
    }

    var event = PCanvasKeyEvent(
        type,
        keyEvent.logicalKey.keyId,
        keyEvent.logicalKey.keyLabel,
        keyEvent.character,
        keyEvent.isControlPressed,
        keyEvent.isAltPressed,
        keyEvent.isShiftPressed,
        keyEvent.isMetaPressed);

    if (type == 'onKeyDown') {
      _widget._painter.onKeyDown(event);
    } else if (type == 'onKeyUp') {
      _widget._painter.onKeyUp(event);
    } else {
      _widget._painter.onKey(event);
    }

    var f = _widget.onKey;
    if (f != null) {
      f(keyEvent);
    }
  }

  void _onTapDown(TapDownDetails details) {
    _focusNode.requestFocus();

    var event = PCanvasClickEvent(
        'onTapDown', details.localPosition.dx, details.localPosition.dy);
    _widget._painter.onClickDown(event);

    var f = _widget.onTapDown;
    if (f != null) {
      f(details);
    }
  }

  PCanvasClickEvent? _lastOnTapUpEvent;

  void _onTapUp(TapUpDetails details) {
    var event = _lastOnTapUpEvent = PCanvasClickEvent(
        'onTapUp', details.localPosition.dx, details.localPosition.dy);
    _widget._painter.onClickUp(event);

    var f = _widget.onTapUp;
    if (f != null) {
      f(details);
    }
  }

  void _onTap() {
    var event = _lastOnTapUpEvent;
    if (event != null) {
      _widget._painter.onClick(event);
    }

    var f = _widget.onTap;
    if (f != null) {
      f();
    }
  }

  void _onTapCancel() {
    var f = _widget.onTapCancel;
    if (f != null) {
      f();
    }
  }
}

typedef _PaintOperation = void Function(Canvas canvas, Size size);

class _PCanvasWidgetPainter extends CustomPainter {
  final ValueNotifier<int> _renderCount;

  num width = 0;
  num height = 0;

  num elementWidth = 0;
  num elementHeight = 0;

  _PCanvasWidgetPainter._(this._renderCount) : super(repaint: _renderCount);

  _PCanvasWidgetPainter() : this._(ValueNotifier<int>(0));

  bool _setElementDimension(int elementWidth, int elementHeight) {
    if (this.elementWidth != elementWidth ||
        this.elementHeight != elementHeight) {
      this.elementWidth = elementWidth;
      this.elementHeight = elementHeight;
      _updateDimension();
      repaint();
      return true;
    } else {
      return false;
    }
  }

  void _updateDimension() {
    width = elementWidth * _pixelRatio;
    height = elementHeight * _pixelRatio;
  }

  num _pixelRatio = 1;

  num get pixelRatio => _pixelRatio;

  bool setPixelRatio(num pr) {
    if (_pixelRatio != pr) {
      _pixelRatio = pr;
      _updateDimension();
      return true;
    }

    return false;
  }

  Future<bool>? _requestedRepaint;

  Future<bool> requestRepaint() {
    if (_operationsAsyncSz > 0) {
      return Future.value(false);
    }

    var requestedRepaint = _requestedRepaint;
    if (requestedRepaint != null) return requestedRepaint;
    return _requestedRepaint = Future.microtask(repaint);
  }

  bool repaint() {
    if (_operationsAsyncSz > 0) {
      return false;
    }

    _renderCount.value++;
    return true;
  }

  final List<_PaintOperation> _operations = <_PaintOperation>[];
  int _operationsSz = 0;

  void addOp(_PaintOperation op) {
    if (_operationsSz == _operations.length) {
      _operations.add(op);
      ++_operationsSz;
    } else {
      _operations[_operationsSz++] = op;
    }

    requestRepaint();
  }

  final List<Future<_PaintOperation>> _operationsAsync =
      <Future<_PaintOperation>>[];
  int _operationsAsyncSz = 0;

  Future<bool> addOpAsync(Future<_PaintOperation> opAsync,
      {String? opType,
      Duration timeout = const Duration(seconds: 30),
      _PaintOperation? opTimeout}) {
    if (_operationsSz == _operations.length) {
      _operationsAsync.add(opAsync);
      ++_operationsAsyncSz;
    } else {
      _operationsAsync[_operationsAsyncSz++] = opAsync;
    }

    _PaintOperation? resolvedF;

    var resolveFuture = opAsync.then((f) {
      resolvedF = f;
      _removeOperationAsyncFuture(opAsync);
      requestRepaint();
      return true;
    }).timeout(timeout, onTimeout: () {
      resolvedF = opTimeout ?? (canvas, size) {};
      _removeOperationAsyncFuture(opAsync);
      requestRepaint();
      return false;
    });

    addOp((canvas, size) {
      var f = resolvedF;
      if (f == null) {
        throw StateError(
            "Unresolved async operator function: ${opType ?? '?'}");
      }
      f(canvas, size);
    });

    return resolveFuture;
  }

  void _removeOperationAsyncFuture(Future<_PaintOperation> future) {
    if (!_operationsAsync.remove(future)) {
      throw StateError("Async operation future not found in stack!");
    }
    --_operationsAsyncSz;
  }

  void clearOps() {
    _operationsSz = 0;

    if (_operationsAsyncSz > 0) {
      debugPrint(
          '** Warning: cleaning operations with unresolved async operations in stack: $_operationsAsyncSz');
    }
  }

  void _clearCanvas(Canvas canvas, Size size) {
    var paint = Paint()..color = Colors.white;

    canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_operationsAsyncSz > 0) {
      debugPrint(
          '** Warning: painting with unresolved async operations in stack: $_operationsAsyncSz');
      return;
    }

    canvas.transform(Matrix4.identity().storage);

    canvas.save();

    _clearCanvas(canvas, size);

    final sz = _operationsSz;
    for (var i = 0; i < sz; ++i) {
      var op = _operations[i];
      op(canvas, size);
    }

    canvas.restore();

    _requestedRepaint = null;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

extension PStyleExtension on PStyle {
  Paint get asPaintFill {
    var p = Paint()..style = PaintingStyle.fill;
    _setColor(p);
    return p;
  }

  Paint toPaintStroke({num pixelRatio = 1}) {
    var p = Paint()..style = PaintingStyle.stroke;
    _setColor(p);
    _setStrokeWidth(p, pixelRatio);
    return p;
  }

  void _setColor(Paint p) {
    var color = this.color;
    if (color != null) p.color = color.asColor;
  }

  void _setStrokeWidth(ui.Paint p, num pixelRatio) {
    var size = this.size;
    if (size != null) {
      p.strokeWidth = size / pixelRatio;
    }
  }
}

class PCanvasFactoryFlutter extends PCanvasFactory {
  static final PCanvasFactoryFlutter instance = PCanvasFactoryFlutter._();

  PCanvasFactoryFlutter._() : super.impl();

  @override
  PCanvas createPCanvas(int width, int height, PCanvasPainter painter,
      {PCanvasPixels? initialPixels}) {
    return PCanvasFlutter._(painter);
  }

  @override
  Uint8List pixelsToPNG(PCanvasPixels pixels) => pixels.pixelsToImagePNG();
}

/// A [PCanvas] Flutter implementation.
class PCanvasFlutter extends PCanvas {
  @override
  final PCanvasPainter painter;

  final _PCanvasWidgetPainter _widgetPainter = _PCanvasWidgetPainter();

  @override
  num get width => _widgetPainter.width;

  @override
  num get height => _widgetPainter.height;

  PCanvasFlutter._(this.painter) : super.impl();

  @override
  num get elementWidth => _widgetPainter.elementWidth;

  @override
  num get elementHeight => _widgetPainter.elementHeight;

  @override
  num get devicePixelRatio => ui.window.devicePixelRatio;

  @override
  num get pixelRatio => _widgetPainter.pixelRatio;

  @override
  set pixelRatio(num pr) {
    if (_widgetPainter.setPixelRatio(pr)) {
      refresh();
    }
  }

  @override
  void checkDimension() {}

  @override
  void log(Object? o) {
    if (o != null) {
      debugPrint('$o');
    }
  }

  void _setup() {
    painter.setup(this);
    _widgetPainter.setPixelRatio(devicePixelRatio);
  }

  @override
  FutureOr<bool> waitLoading() => painter.waitLoading();

  @override
  Future<bool> requestRepaint() => _widgetPainter.requestRepaint();

  @override
  void onPrePaint() {
    _widgetPainter.clearOps();
  }

  @override
  void onPosPaint() {
    _widgetPainter.repaint();
  }

  @override
  void setPixels(PCanvasPixels pixels,
      {int x = 0, int y = 0, int? width, int? height}) {
    var w = width ?? this.width;
    if (x + w > this.width) w = this.width - x;

    var h = height ?? this.height;
    if (y + h > this.height) h = this.height - y;

    if (w <= 0 || h <= 0) return;

    if (x > 0 || y > 0 || w != pixels.width || h != pixels.height) {
      pixels = pixels.copyRect(x, y, w.toInt(), h.toInt())!;
    }

    ui.PixelFormat pixelFormat;

    if (pixels is PCanvasPixelsRGBA) {
      pixelFormat = ui.PixelFormat.rgba8888;
    } else if (pixels is PCanvasPixelsARGB) {
      pixelFormat = ui.PixelFormat.bgra8888;
    } else {
      pixels = pixels.toPCanvasPixelsARGB();
      pixelFormat = ui.PixelFormat.bgra8888;
    }

    var pixelsData = pixels.pixels;
    var pixelsDataBuffer = pixelsData.buffer;

    var bytes = pixelsDataBuffer.asUint8List(
        pixelsData.offsetInBytes, pixelsData.lengthInBytes);

    Completer<ui.Image> imageCompelter = Completer<ui.Image>();

    ui.decodeImageFromPixels(bytes, w.toInt(), h.toInt(), pixelFormat,
        (image) => imageCompelter.complete(image));

    var opAsync =
        imageCompelter.future.then((image) => _opDrawImageAsync(image, x, y));

    _widgetPainter.addOpAsync(opAsync);
  }

  _PaintOperation _opDrawImageAsync(ui.Image image, int x, int y) =>
      (canvas, size) =>
          canvas.drawImage(image, Offset(x.toDouble(), y.toDouble()), Paint());

  @override
  PCanvasStateExtra? get stateExtra => null;

  PRectangle? _clip;

  @override
  PRectangle? get clip => _clip;

  void _setClipGlobal(ui.Rect clipRect) {
    _widgetPainter.addOp((canvas, size) {
      canvas.restore();

      canvas.transform(Matrix4.identity().storage);

      canvas.save();
      canvas.clipRect(clipRect);
    });
  }

  @override
  set clip(PRectangle? clip) {
    if (clip == null) {
      if (_clip != null) {
        final widthD = canvasXD(width);
        final heightD = canvasYD(height);

        final rect = Rect.fromLTWH(0, 0, widthD, heightD);

        _setClipGlobal(rect);
        _clip = null;
      }
    } else {
      if (_clip != clip) {
        final xd = canvasXD(clip.x);
        final yd = canvasYD(clip.y);

        final widthD = canvasXD(clip.width);
        final heightD = canvasYD(clip.height);

        final rect = Rect.fromLTWH(xd, yd, widthD, heightD);

        _setClipGlobal(rect);
        _clip = clip;
      }
    }
  }

  @override
  get canvasNative => throw UnimplementedError();

  @override
  num canvasX(num x) => x / pixelRatio;

  @override
  num canvasY(num y) => y / pixelRatio;

  @override
  double canvasXD(num x) => x / pixelRatio;

  @override
  double canvasYD(num y) => y / pixelRatio;

  @override
  Point canvasPoint(Point p) {
    final pr = pixelRatio;
    return Point(p.x / pr, p.y / pr);
  }

  @override
  void clearRect(num x, num y, num width, num height, {PStyle? style}) {
    var xd = transform.xD(x);
    var yd = transform.yD(y);

    xd = canvasXD(xd);
    yd = canvasYD(yd);

    final widthD = canvasXD(width);
    final heightD = canvasYD(height);

    var paint = style?.asPaintFill;

    _widgetPainter.addOp((canvas, size) {
      paint ??= Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white;

      var rect = Rect.fromLTWH(xd, yd, widthD, heightD);
      canvas.drawRect(rect, paint!);
    });
  }

  int _imageIdCount = 0;

  @override
  PCanvasImage createCanvasImage(Object source, {int? width, int? height}) {
    var id = ++_imageIdCount;

    var src = source;

    if (source is String) {
      if (source.startsWith('http://') || source.startsWith('https://')) {
        source = NetworkImage(source);
      }
    }

    if (source is ImageProvider) {
      var imageConfig = const ImageConfiguration();
      var imageStream = source.resolve(imageConfig);

      var completer = Completer<ui.Image>();

      imageStream.addListener(ImageStreamListener((imageInfo, _) {
        completer.complete(imageInfo.image);
      }, onError: (e, s) {
        completer.completeError(e, s);
      }));

      return _PCanvasImageFlutterAsync('img_$id', completer.future, '$src');
    } else if (source is ui.Image) {
      return _PCanvasImageFlutterSync('img_$id', source, '[image]');
    } else if (source is Uint8List) {
      var imageFuture = decodeImageFromList(source);
      return _PCanvasImageFlutterAsync(
          'img_$id', imageFuture, '[bytes:${source.length}]');
    }

    throw ArgumentError("Can't handle image source: $source");
  }

  @override
  void drawImage(PCanvasImage image, num x, num y) {
    checkImageLoaded(image);

    if (image is! _PCanvasImageFlutter) {
      throw ArgumentError(
          "Can't handle image type `${image.runtimeType}`: $image");
    }

    var xd = transform.xD(x);
    var yd = transform.yD(y);

    xd = canvasXD(xd);
    yd = canvasYD(yd);

    final offset = Offset(xd, yd);

    _widgetPainter.addOp((canvas, size) {
      var paint = Paint();
      canvas.drawImage(image.flutterImage, offset, paint);
    });
  }

  @override
  void drawImageScaled(
      PCanvasImage image, num x, num y, num width, num height) {
    checkImageLoaded(image);

    if (image is! _PCanvasImageFlutter) {
      throw ArgumentError(
          "Can't handle image type `${image.runtimeType}`: $image");
    }

    var xd = transform.xD(x);
    var yd = transform.yD(y);

    xd = canvasXD(xd);
    yd = canvasYD(yd);

    final widthD = canvasXD(width);
    final heightD = canvasYD(height);

    final rect1 =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final rect2 = Rect.fromLTWH(xd, yd, widthD, heightD);

    _widgetPainter.addOp((canvas, size) {
      var paint = Paint();
      canvas.drawImageRect(image.flutterImage, rect1, rect2, paint);
    });
  }

  @override
  void drawImageArea(PCanvasImage image, int srcX, int srcY, int srcWidth,
      int srcHeight, num dstX, num dstY, num dstWidth, num dstHeight) {
    checkImageLoaded(image);

    if (image is! _PCanvasImageFlutter) {
      throw ArgumentError(
          "Can't handle image type `${image.runtimeType}`: $image");
    }

    var dstXD = transform.xD(dstX);
    var dstYD = transform.yD(dstY);

    dstXD = canvasXD(dstXD);
    dstYD = canvasYD(dstYD);

    final dstWidthD = canvasXD(dstWidth);
    final dstHeightD = canvasYD(dstHeight);

    final rect1 = Rect.fromLTWH(srcX.toDouble(), srcY.toDouble(),
        srcWidth.toDouble(), srcHeight.toDouble());
    final rect2 = Rect.fromLTWH(dstXD, dstYD, dstWidthD, dstHeightD);

    _widgetPainter.addOp((canvas, size) {
      var paint = Paint();
      canvas.drawImageRect(image.flutterImage, rect1, rect2, paint);
    });
  }

  @override
  void fillRect(num x, num y, num width, num height, PStyle style) {
    var xd = transform.xD(x);
    var yd = transform.yD(y);

    xd = canvasXD(xd);
    yd = canvasYD(yd);

    final widthD = canvasXD(width);
    final heightD = canvasYD(height);

    final rect = Rect.fromLTWH(xd, yd, widthD, heightD);
    final paint = style.asPaintFill;

    _widgetPainter.addOp((canvas, size) {
      canvas.drawRect(rect, paint);
    });
  }

  @override
  void strokeCircle(num x, num y, num radius, PStyle style,
      {num startAngle = 0, num endAngle = 360}) {
    var xd = transform.xD(x);
    var yd = transform.yD(y);

    xd = canvasXD(xd);
    yd = canvasYD(yd);

    var radiusD2 = canvasXD(radius) * 2;

    final rect = Rect.fromLTWH(xd, yd, radiusD2, radiusD2);
    final paint = style.toPaintStroke(pixelRatio: pixelRatio);

    _widgetPainter.addOp((canvas, size) {
      canvas.drawArc(
          rect, startAngle.toDouble(), endAngle.toDouble(), false, paint);
    });
  }

  @override
  void fillCircle(num x, num y, num radius, PStyle style,
      {num startAngle = 0, num endAngle = 360}) {
    var xd = transform.xD(x);
    var yd = transform.yD(y);

    xd = canvasXD(xd);
    yd = canvasYD(yd);

    var radiusD2 = canvasXD(radius) * 2;

    final rect = Rect.fromLTWH(xd, yd, radiusD2, radiusD2);
    final paint = style.asPaintFill;

    _widgetPainter.addOp((canvas, size) {
      canvas.drawArc(
          rect, startAngle.toDouble(), endAngle.toDouble(), false, paint);
    });
  }

  @override
  void fillTopDownGradient(
      num x, num y, num width, num height, PColor colorFrom, PColor colorTo) {
    var xd = transform.xD(x);
    var yd = transform.yD(y);

    xd = canvasXD(xd);
    yd = canvasYD(yd);

    final widthD = canvasXD(width);
    final heightD = canvasYD(height);

    final rect = Rect.fromLTWH(xd, yd, widthD, heightD);

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(xd, yd),
        Offset(xd, (yd + heightD)),
        [colorFrom.asColor, colorTo.asColor],
      );

    _widgetPainter.addOp((canvas, size) {
      canvas.drawRect(rect, paint);
    });
  }

  @override
  void fillLeftRightGradient(
      num x, num y, num width, num height, PColor colorFrom, PColor colorTo) {
    var xd = transform.xD(x);
    var yd = transform.yD(y);

    xd = canvasXD(xd);
    yd = canvasYD(yd);

    final widthD = canvasXD(width);
    final heightD = canvasYD(height);

    final rect = Rect.fromLTWH(xd, yd, widthD, heightD);

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(xd, yd),
        Offset((xd + widthD), yd),
        [colorFrom.asColor, colorTo.asColor],
      );

    _widgetPainter.addOp((canvas, size) {
      canvas.drawRect(rect, paint);
    });
  }

  @override
  void strokeRect(num x, num y, num width, num height, PStyle style) {
    var xd = transform.xD(x);
    var yd = transform.yD(y);

    xd = canvasXD(xd);
    yd = canvasYD(yd);

    final widthD = canvasXD(width);
    final heightD = canvasYD(height);

    final rect = Rect.fromLTWH(xd, yd, widthD, heightD);
    final paint = style.toPaintStroke(pixelRatio: pixelRatio);

    _widgetPainter.addOp((canvas, size) {
      canvas.drawRect(rect, paint);
    });
  }

  @override
  void fillPath(List path, PStyle style, {bool closePath = false}) {
    var fullPath = _buildFullPath(path, closePath);
    final paint = style.asPaintFill;

    _widgetPainter.addOp((canvas, size) {
      canvas.drawPath(fullPath, paint);
    });
  }

  @override
  void strokePath(List path, PStyle style, {bool closePath = false}) {
    var fullPath = _buildFullPath(path, closePath);
    final paint = style.toPaintStroke(pixelRatio: pixelRatio);

    _widgetPainter.addOp((canvas, size) {
      canvas.drawPath(fullPath, paint);
    });
  }

  ui.Path _buildFullPath(List<dynamic> path, bool closePath) {
    var fullPath = Path();

    Point? closePoint;

    if (path is List<num>) {
      for (var i = 0; i < path.length; i += 2) {
        var x = path[i];
        var y = path[i + 1];

        var xd = transform.xD(x);
        var yd = transform.yD(y);

        xd = canvasXD(xd);
        yd = canvasYD(yd);

        if (i == 0) {
          fullPath.moveTo(xd, yd);
          closePoint = Point(xd, yd);
        } else {
          fullPath.lineTo(xd, yd);
        }
      }
    } else if (path is List<Point>) {
      var i = 0;
      for (var p in path) {
        p = transform.point(p);
        p = canvasPoint(p);

        if (i == 0) {
          fullPath.moveTo(p.x.toDouble(), p.y.toDouble());
          closePoint = p;
        } else {
          fullPath.lineTo(p.x.toDouble(), p.y.toDouble());
        }
        ++i;
      }
    } else {
      for (var i = 0; i < path.length; i++) {
        var e = path[i];
        if (e is num) {
          var x = e;
          var y = path[++i];

          var xd = transform.xD(x);
          var yd = transform.yD(y);

          xd = canvasXD(xd);
          yd = canvasYD(yd);

          if (i == 1) {
            fullPath.moveTo(xd, yd);
            closePoint = Point(xd, yd);
          } else {
            fullPath.lineTo(xd, yd);
          }
        } else if (e is Point) {
          e = transform.point(e);
          e = canvasPoint(e);

          if (i == 0) {
            fullPath.moveTo(e.x.toDouble(), e.y.toDouble());
            closePoint = e;
          } else {
            fullPath.lineTo(e.x.toDouble(), e.y.toDouble());
          }
        } else {
          throw ArgumentError(
              "Can't stroke path point of type: ${e.runtimeType}");
        }
      }
    }

    if (closePath && closePoint != null) {
      var p = closePoint;
      fullPath.lineTo(p.x.toDouble(), p.y.toDouble());
    }

    return fullPath;
  }

  @override
  PTextMetric measureText(String text, PFont font) {
    var textStyle = font.toTextStyle();
    var textSpan = TextSpan(text: text, style: textStyle);

    final textPainterBlock =
        TextPainter(text: textSpan, textDirection: TextDirection.ltr)
          ..layout(minWidth: 0, maxWidth: double.infinity);

    var sizeBlock = textPainterBlock.size;

    return PTextMetric(sizeBlock.width, sizeBlock.height);
  }

  @override
  void drawText(String text, num x, num y, PFont font, PStyle style) {
    var xd = transform.xD(x);
    var yd = transform.yD(y);

    xd = canvasXD(xd);
    yd = canvasYD(yd);

    final textStyle =
        font.toTextStyle(color: style.color, pixelRatio: pixelRatio);
    final textSpan = TextSpan(text: text, style: textStyle);

    final textPainter =
        TextPainter(text: textSpan, textDirection: TextDirection.ltr)
          ..layout(minWidth: 0, maxWidth: double.infinity);

    _widgetPainter.addOp((canvas, size) {
      textPainter.paint(canvas, Offset(xd, yd));
    });
  }

  Future<ui.Image> toImage() async {
    var w = _widgetPainter.elementWidth;
    var h = _widgetPainter.elementHeight;
    var wInt = w.toInt();
    var hInt = h.toInt();
    var wD = w.toDouble();
    var hD = h.toDouble();

    var recorder = ui.PictureRecorder();

    var canvas = Canvas(recorder, Rect.fromLTWH(0, 0, wD, hD));
    _widgetPainter.paint(canvas, Size(wD, hD));

    var picture = recorder.endRecording();

    var image = await picture.toImage(wInt, hInt);
    return image;
  }

  @override
  Future<PCanvasPixels> get pixels async {
    final image = await toImage();

    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);

    var data = byteData!.buffer
        .asUint32List(byteData.offsetInBytes, byteData.lengthInBytes ~/ 4);

    return PCanvasPixelsABGR.fromPixels(image.width, image.height, data);
  }

  @override
  Future<Uint8List> toPNG() async {
    final image = await toImage();

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    var data = byteData!.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);

    return data;
  }

  @override
  String toString() {
    return 'PCanvasFlutter[${width}x$height]$info';
  }
}

abstract class _PCanvasImageFlutter extends PCanvasImage {
  ui.Image get flutterImage;
}

class _PCanvasImageFlutterSync extends _PCanvasImageFlutter {
  @override
  final String id;

  final ui.Image image;

  @override
  final String src;

  _PCanvasImageFlutterSync(this.id, this.image, this.src);

  @override
  String get type => 'flutter:sync';

  @override
  ui.Image get flutterImage => image;

  @override
  int get width => image.width;

  @override
  int get height => image.height;

  @override
  bool get isLoaded => true;

  @override
  FutureOr<bool> load() => true;
}

class _PCanvasImageFlutterAsync extends _PCanvasImageFlutter {
  @override
  final String id;

  Future<ui.Image>? _imageFuture;

  ui.Image? _image;

  @override
  final String src;

  _PCanvasImageFlutterAsync(this.id, this._imageFuture, this.src) {
    _imageFuture!.then((img) {
      _image = img;
      _imageFuture = null;
    });
  }

  @override
  String get type => 'flutter:async';

  @override
  ui.Image get flutterImage => _image!;

  @override
  int get width => _image?.width ?? 0;

  @override
  int get height => _image?.height ?? 0;

  @override
  bool get isLoaded => _image != null;

  Future<bool>? _loading;

  @override
  FutureOr<bool> load() {
    if (_image != null) return true;

    var imageFuture = _imageFuture;
    if (imageFuture == null) return true;

    return _loading ??= imageFuture.then((_) {
      _loading = null;
      return true;
    });
  }

  @override
  String toString() {
    return '_PCanvasImageFlutterAsync{id: $id, loaded: $isLoaded}@${_image ?? ''}';
  }
}

extension PFontExtension on PFont {
  TextStyle toTextStyle({PColor? color, num pixelRatio = 1}) {
    var fontSize = size / pixelRatio;
    var fontFamily = family;
    var fontFamilyFallback = familyFallback ?? 'sans-serif';
    var fontWeight = bold ? FontWeight.bold : FontWeight.normal;
    var fontStyle = italic ? FontStyle.italic : FontStyle.normal;
    var fontColor = color?.asColor ?? Colors.black;

    return TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: [fontFamilyFallback],
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: fontColor);
  }
}

extension PColorExtension on PColor {
  Color get asColor {
    var c = this;
    if (c is PColorRGBA) {
      return Color.fromRGBO(c.r, c.g, c.b, c.alpha);
    } else if (c is PColorRGB) {
      return Color.fromARGB(255, c.r, c.g, c.b);
    } else {
      throw StateError("Can't convert Color type `${c.runtimeType}`: $c");
    }
  }
}

extension PRectangleFlutterExtension on PRectangle {
  ui.Rect get asUIRect {
    var r = ui.Rect.fromLTWH(
        x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble());
    return r;
  }
}
