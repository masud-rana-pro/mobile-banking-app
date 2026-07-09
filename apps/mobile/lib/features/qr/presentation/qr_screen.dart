import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../../send_money/presentation/send_money_screen.dart';
import '../domain/qr_payload.dart';

class QrScreen extends ConsumerWidget {
  const QrScreen({super.key});

  static const routeName = 'qr';
  static const routePath = '/qr';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final myNumber = authState.backendToken?.phoneNumber ?? '';
    final payload = QrPayload(mobileNumber: myNumber);
    final fullPayload = payload.fullPayload;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF008F7A).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.qr_code_2,
                      color: Color(0xFF008F7A),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'My QR Payload',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share this code with the sender',
                    style: TextStyle(color: Color(0xFF607D8B), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      fullPayload,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF263238),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: fullPayload));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QR payload copied to clipboard'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR',
                      style: TextStyle(
                          color: Color(0xFF90A4AE),
                          fontWeight: FontWeight.w700)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Enter Sender QR Payload',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paste the QR payload you received',
              style: TextStyle(color: Color(0xFF607D8B), fontSize: 13),
            ),
            const SizedBox(height: 16),
            _QrPasteField(
              onSubmit: (payload) {
                final number = QrPayload.extractMobileNumber(payload);
                if (number == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Invalid QR payload. Must start with SMARTKASH_USER:'),
                    ),
                  );
                  return;
                }

                context.pushNamed(
                  SendMoneyScreen.routeName,
                );
              },
            ),
          ],
        ),
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
      children: [
        TextField(
          controller: _controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Paste QR payload here...',
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
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
            icon: const Icon(Icons.send),
            label: const Text('Send Money to this QR',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
