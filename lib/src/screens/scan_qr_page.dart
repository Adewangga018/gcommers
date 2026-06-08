import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_theme.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> with WidgetsBindingObserver {
  static const Color _bg = AppTheme.navy;
  static const Color _primary = AppTheme.primary;
  static const Color _accent = AppTheme.primary;

  late final MobileScannerController _controller;
  bool _scanned = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_scanned) _controller.start();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_scanned) _controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _controller.stop();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    _scanned = true;
    _controller.stop();
    // Auto-confirm and show success dialog
    _showCompletionDialog(code);
  }

  Future<void> _showCompletionDialog(String code) async {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF1F203A),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF16C38A).withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Color(0xFF16C38A), size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pesanan Dikonfirmasi!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                code,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    '/history',
                    (route) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16C38A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Lanjut ke Riwayat',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleTorch() {
    _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  void _showManualInput() {
    final textController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManualInputSheet(
        controller: textController,
        onConfirm: (code) {
          Navigator.pop(ctx);
          if (code.isNotEmpty) {
            _scanned = true;
            _controller.stop();
            Navigator.of(context).pushReplacementNamed('/received-goods', arguments: code);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'GCommers',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: Icon(
                      _torchOn ? Icons.flash_on : Icons.flash_off_outlined,
                      color: _torchOn ? Colors.amber : Colors.white,
                    ),
                    onPressed: _toggleTorch,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pindai QR Kode',
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Arahkan ke QR pada Surat Jalan',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 20),
            // Camera viewport
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _controller,
                        onDetect: _onDetect,
                        errorBuilder: (context, error, child) {
                          return _CameraErrorView(error: error.errorCode.name);
                        },
                      ),
                      // Corner guides overlay
                      CustomPaint(painter: _CornerPainter(color: _accent)),
                      // Center scan hint
                      // Hint removed for kios role
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _showManualInput,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Masukkan Kode Manual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Camera error view ─────────────────────────────────────────

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1B30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_outlined, color: Colors.white38, size: 56),
          const SizedBox(height: 16),
          const Text(
            'Kamera tidak dapat dibuka',
            style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Pastikan izin kamera telah diberikan',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Scanner corner overlay ────────────────────────────────────

class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 32.0;
    const r = 16.0;

    final corners = [
      // top-left
      () {
        canvas.drawLine(const Offset(r, 2), const Offset(r + len, 2), paint);
        canvas.drawLine(const Offset(2, r), const Offset(2, r + len), paint);
        canvas.drawArc(const Rect.fromLTWH(2, 2, r * 2, r * 2), 3.14159, 1.5708, false, paint);
      },
      // top-right
      () {
        canvas.drawLine(Offset(size.width - r, 2), Offset(size.width - r - len, 2), paint);
        canvas.drawLine(Offset(size.width - 2, r), Offset(size.width - 2, r + len), paint);
        canvas.drawArc(Rect.fromLTWH(size.width - r * 2 - 2, 2, r * 2, r * 2), -1.5708, 1.5708, false, paint);
      },
      // bottom-left
      () {
        canvas.drawLine(Offset(2, size.height - r), Offset(2, size.height - r - len), paint);
        canvas.drawLine(Offset(r, size.height - 2), Offset(r + len, size.height - 2), paint);
        canvas.drawArc(Rect.fromLTWH(2, size.height - r * 2 - 2, r * 2, r * 2), 1.5708, 1.5708, false, paint);
      },
      // bottom-right
      () {
        canvas.drawLine(Offset(size.width - 2, size.height - r), Offset(size.width - 2, size.height - r - len), paint);
        canvas.drawLine(Offset(size.width - r, size.height - 2), Offset(size.width - r - len, size.height - 2), paint);
        canvas.drawArc(Rect.fromLTWH(size.width - r * 2 - 2, size.height - r * 2 - 2, r * 2, r * 2), 0, 1.5708, false, paint);
      },
    ];
    for (final fn in corners) {
      fn();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Manual input bottom sheet ────────────────────────────────

class _ManualInputSheet extends StatelessWidget {
  const _ManualInputSheet({required this.controller, required this.onConfirm});

  final TextEditingController controller;
  final void Function(String code) onConfirm;

  static const Color _primary = Color(0xFF38804B);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A2E1D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Input Kode Surat Jalan',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Masukkan nomor yang tertera pada Surat Jalan',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              cursorColor: _primary,
              decoration: InputDecoration(
                hintText: 'Contoh: SJ-20231024-001',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF243D27),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _primary, width: 2),
                ),
                prefixIcon: const Icon(Icons.qr_code_outlined, color: _primary),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => onConfirm(controller.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Konfirmasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
