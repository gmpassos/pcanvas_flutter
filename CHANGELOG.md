## 1.1.0

- `PCanvasWidget`:
  - Added `rebuild`.

- sdk: '>=3.0.0 <4.0.0'
- flutter: ">=3.10.0"
- pcanvas: ^1.1.0
- flutter_lints: ^2.0.1

## 1.0.7

- `PCanvasFlutter`:
  - Added `setPixels`.
  - Added support for `clip`.
  - Added support for `transform` (translation).
- Added `PCanvasFactoryFlutter`.
  - `pixelsToPNG` using package `image` instead of an internal Flutter Canvas. 
- `PCanvasWidgetPainter`:
  - `addOpAsync`: to allow operations that need asynchronous resolution.
- Fix GitHub Dart CI badge.
- pcanvas: ^1.0.7
- image: ^4.0.7

* Sync version number with `pcanvas` package...

## 1.0.2

- Added support to stroke/fill circle.

## 1.0.1

- Added support to key events.
- Added linear gradient operations.
- pcanvas: ^1.0.3

## 1.0.0

- Initial version.
