import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../auth/providers/auth_providers.dart';
import '../../payment/presentation/merchant_payment_screen.dart';
import '../../send_money/presentation/send_money_screen.dart';
import '../domain/qr_payload.dart';

class QrScreen extends ConsumerStatefulWidget {
  const QrScreen({
    this.initialTab = 0,
    super.key,
  });

  static const routeName = 'qr';
  static const routePath = '/qr';

  final int initialTab;

  @override
  ConsumerState<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends ConsumerState<QrScreen> {
  final _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _hasNavigatedFromScan = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handlePayload(String rawPayload) {
    final payload = QrPayload.parse(rawPayload);
    if (payload == null) {
      _showMessage(
        'Invalid SmartKash QR. Use SMARTKASH_USER or SMARTKASH_MERCHANT QR.',
      );
      return;
    }

    if (payload.type == QrPayloadType.user) {
      context.goNamed(
        SendMoneyScreen.routeName,
        queryParameters: {'qrPayload': payload.fullPayload},
      );
      return;
    }

    context.goNamed(
      MerchantPaymentScreen.routeName,
      queryParameters: {'merchantNumber': payload.value},
    );
  }

  void _handleScan(BarcodeCapture capture) {
    if (_hasNavigatedFromScan) {
      return;
    }

    String? rawValue;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        rawValue = value;
        break;
      }
    }

    if (rawValue == null) {
      return;
    }

    final payload = QrPayload.parse(rawValue);
    if (payload == null) {
      _showMessage('This is not a valid SmartKash QR.');
      return;
    }

    setState(() => _hasNavigatedFromScan = true);
    _handlePayload(rawValue);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final myNumber = authState.backendToken?.phoneNumber ?? '';
    final myPayload = myNumber.isEmpty
        ? null
        : QrPayload.user(mobileNumber: myNumber).fullPayload;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab == 1 ? 1 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('QR'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Toggle flash',
              onPressed: _scannerController.toggleTorch,
              icon: const Icon(Icons.flash_on_rounded),
            ),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF008F7A),
            indicatorColor: Color(0xFF008F7A),
            tabs: [
              Tab(icon: Icon(Icons.qr_code_2_rounded), text: 'My QR'),
              Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan QR'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MyQrTab(payload: myPayload),
            _ScanQrTab(
              controller: _scannerController,
              onDetect: _handleScan,
              onSubmit: _handlePayload,
            ),
          ],
        ),
      ),
    );
  }
}

class _MyQrTab extends StatelessWidget {
  const _MyQrTab({required this.payload});

  final String? payload;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (payload == null)
          const _EmptyQrCard()
        else
          _MyQrCard(payload: payload!),
        const SizedBox(height: 18),
        const _InfoCard(
          icon: Icons.send_to_mobile_rounded,
          title: 'Receive money with QR',
          message:
              'Share this QR with another SmartKash user. They can scan it and send money to your account.',
        ),
      ],
    );
  }
}

class _ScanQrTab extends StatelessWidget {
  const _ScanQrTab({
    required this.controller,
    required this.onDetect,
    required this.onSubmit,
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture capture) onDetect;
  final void Function(String payload) onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ScannerCard(
          controller: controller,
          onDetect: onDetect,
        ),
        const SizedBox(height: 18),
        const _InfoCard(
          icon: Icons.send_to_mobile_rounded,
          title: 'Send Money QR',
          message:
              'Scan a SMARTKASH_USER QR to open Send Money with receiver selected.',
        ),
        const SizedBox(height: 12),
        const _InfoCard(
          icon: Icons.storefront_rounded,
          title: 'Merchant Payment QR',
          message:
              'Scan a SMARTKASH_MERCHANT QR to open Payment with merchant selected.',
        ),
        const SizedBox(height: 18),
        _QrPasteField(onSubmit: onSubmit),
      ],
    );
  }
}

class _EmptyQrCard extends StatelessWidget {
  const _EmptyQrCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFEF6C00), size: 42),
          SizedBox(height: 10),
          Text(
            'Login first to generate your SmartKash QR.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF263238),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerCard extends StatelessWidget {
  const _ScannerCard({
    required this.controller,
    required this.onDetect,
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture capture) onDetect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF102A2A),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: onDetect,
          ),
          CustomPaint(painter: _ScannerFramePainter()),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Place a SmartKash QR inside the frame',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyQrCard extends StatelessWidget {
  const _MyQrCard({required this.payload});

  final String payload;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'My SmartKash QR',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Another user can scan this to send you money',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF607D8B), fontSize: 13),
          ),
          const SizedBox(height: 16),
          QrImageView(
            data: payload,
            version: QrVersions.auto,
            size: 190,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 10),
          SelectableText(
            payload,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: payload));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR payload copied')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy payload'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF008F7A)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF607D8B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPasteField extends StatefulWidget {
  const _QrPasteField({required this.onSubmit});

  final void Function(String payload) onSubmit;

  @override
  State<_QrPasteField> createState() => _QrPasteFieldState();
}

class _QrPasteFieldState extends State<_QrPasteField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paste QR payload',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'SMARTKASH_USER:+880... or SMARTKASH_MERCHANT:...',
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              final text = _controller.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paste a QR payload first')),
                );
                return;
              }
              widget.onSubmit(text);
            },
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text(
              'Continue with QR',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008F7A),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00BFA5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.68,
      height: size.width * 0.68,
    );
    const corner = 34.0;

    canvas.drawLine(
        rect.topLeft, rect.topLeft + const Offset(corner, 0), paint);
    canvas.drawLine(
        rect.topLeft, rect.topLeft + const Offset(0, corner), paint);
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(-corner, 0),
      paint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(0, corner),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(corner, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(0, -corner),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(-corner, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(0, -corner),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
