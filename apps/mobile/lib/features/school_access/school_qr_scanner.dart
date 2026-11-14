import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../shared/theme/app_theme.dart';
import 'school_location.dart';

class SchoolQrScanner extends StatefulWidget {
  const SchoolQrScanner({
    super.key,
    required this.resolve,
    required this.onAccepted,
    required this.onManual,
  });

  /// Verdadero si el código leído corresponde a un colegio registrado.
  final Future<bool> Function(String code) resolve;
  final VoidCallback onAccepted;
  final VoidCallback onManual;

  @override
  State<SchoolQrScanner> createState() => _SchoolQrScannerState();
}

class _SchoolQrScannerState extends State<SchoolQrScanner>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _leaving = false;
  bool _unknownCode = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_leaving || !_controller.value.hasCameraPermission) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller.start());
    } else {
      unawaited(_controller.stop());
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_leaving || _checking || !mounted) return;
    bool readCode = false;
    for (final Barcode barcode in capture.barcodes) {
      final String? value = barcode.rawValue;
      if (value == null) continue;
      readCode = true;
      // Acepta el código directo o el enlace del cartel; solo se consultan
      // lecturas con forma de código de colegio.
      final String? code = extractSchoolCode(value);
      if (code == null) continue;
      _checking = true;
      final bool known = await widget.resolve(code);
      _checking = false;
      if (!mounted) return;
      if (known) {
        unawaited(_leave(widget.onAccepted));
        return;
      }
    }
    if (readCode && !_unknownCode) setState(() => _unknownCode = true);
  }

  Future<void> _leave(VoidCallback action) async {
    if (_leaving) return;
    _leaving = true;
    await _controller.stop();
    if (mounted) action();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    onPopInvokedWithResult: (didPop, result) {
      if (didPop && !_leaving) {
        _leaving = true;
        unawaited(_controller.stop());
      }
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: SizedBox(
            height: 254,
            child: MobileScanner(
              controller: _controller,
              useAppLifecycleState: false,
              onDetect: _onDetect,
              errorBuilder: (context, error) => ColoredBox(
                color: const Color(0xFF10244A),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      error.errorCode == MobileScannerErrorCode.permissionDenied
                          ? 'Para escanear, permití el acceso a la cámara desde los ajustes de la app.'
                          : 'No pudimos abrir la cámara. Podés escribir el código.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              overlayBuilder: (context, constraints) => const ExcludeSemantics(
                child: Center(
                  child: SizedBox.square(
                    dimension: 140,
                    child: CustomPaint(painter: _ScanCorners()),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_unknownCode) ...<Widget>[
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: const Text(
              'Ese QR no corresponde a un colegio registrado. Probá de nuevo o escribí el código.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => _leave(widget.onManual),
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
          icon: const Icon(Icons.keyboard_alt_outlined),
          label: const Text('Escribir código', textAlign: TextAlign.center),
        ),
      ],
    ),
  );
}

class _ScanCorners extends CustomPainter {
  const _ScanCorners();

  @override
  void paint(Canvas canvas, Size size) {
    const double inset = 2;
    const double length = 22;
    final double right = size.width - inset;
    final double bottom = size.height - inset;
    final Path corners = Path()
      ..moveTo(inset, inset + length)
      ..lineTo(inset, inset)
      ..lineTo(inset + length, inset)
      ..moveTo(right - length, inset)
      ..lineTo(right, inset)
      ..lineTo(right, inset + length)
      ..moveTo(inset, bottom - length)
      ..lineTo(inset, bottom)
      ..lineTo(inset + length, bottom)
      ..moveTo(right - length, bottom)
      ..lineTo(right, bottom)
      ..lineTo(right, bottom - length);
    canvas.drawPath(
      corners,
      Paint()
        ..color = CureandoTheme.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_ScanCorners oldDelegate) => false;
}
