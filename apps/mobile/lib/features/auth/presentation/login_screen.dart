import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/app_config.dart';
import '../../../core/constants/app_assets.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routeName = 'login';
  static const routePath = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _otpCode = '';

  bool get _canSendOtp => _phoneController.text.trim().length >= 10;
  bool get _canContinue =>
      _phoneController.text.trim().length >= 10 && _otpCode.length >= 6;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onNumberTap(String value) {
    if (_otpCode.length >= 6) {
      return;
    }

    setState(() => _otpCode += value);
  }

  void _onBackspace() {
    if (_otpCode.isEmpty) {
      return;
    }

    setState(() => _otpCode = _otpCode.substring(0, _otpCode.length - 1));
  }

  String _normalizedPhoneNumber() {
    final digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('880')) {
      return '+$digits';
    }
    if (digits.startsWith('88')) {
      return '+$digits';
    }
    if (digits.startsWith('0')) {
      return '+88$digits';
    }
    return '+880$digits';
  }

  Future<void> _onNextPressed() async {
    final authState = ref.read(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    if (authState.isLoading) {
      return;
    }

    if (!authState.isOtpSent) {
      if (!_canSendOtp) {
        _showMessage('Enter a valid mobile number first.');
        return;
      }
      await controller.sendLoginOtp(_normalizedPhoneNumber());
      return;
    }

    if (!_canContinue) {
      _showMessage('Enter the 6 digit Firebase test OTP.');
      return;
    }

    await controller.verifyLoginOtp(_otpCode);
  }

  void _fillTestOtp() {
    setState(() => _otpCode = '123456');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final nextEnabled = authState.isOtpSent ? _canContinue : _canSendOtp;
    final nextLabel = authState.isOtpSent ? 'Verify & Login' : 'Send OTP';

    ref.listen(authControllerProvider, (previous, next) {
      if (next.isAuthenticated) {
        context.go('/');
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _LoginTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 44, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SmartKashMark(),
                    const SizedBox(height: 44),
                    const Text(
                      'Log in\nto your SmartKash account',
                      style: TextStyle(
                        color: Color(0xFF263238),
                        fontSize: 32,
                        height: 1.16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 44),
                    _PhoneField(
                      controller: _phoneController,
                      enabled: !authState.isLoading && !authState.isOtpSent,
                    ),
                    const SizedBox(height: 28),
                    _OtpPreview(
                      otpCode: _otpCode,
                      enabled: authState.isOtpSent,
                    ),
                    const SizedBox(height: 22),
                    TextButton(
                      onPressed: authState.isLoading ? null : _fillTestOtp,
                      child: const Text('Use Firebase test OTP code'),
                    ),
                    if (authState.infoMessage != null) ...[
                      const SizedBox(height: 12),
                      _AuthMessage(
                        message: authState.infoMessage!,
                        isError: false,
                      ),
                    ],
                    if (authState.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _AuthMessage(
                        message: authState.errorMessage!,
                        isError: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _NextActionBar(
              enabled: nextEnabled && !authState.isLoading,
              isLoading: authState.isLoading,
              label: nextLabel,
              onPressed: _onNextPressed,
            ),
            _NumberPad(
              onNumberTap: _onNumberTap,
              onBackspace: _onBackspace,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginTopBar extends StatelessWidget {
  const _LoginTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 18, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
                return;
              }

              context.go('/');
            },
            icon: const Icon(Icons.arrow_back, color: Color(0xFF008F7A)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF008F7A)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Eng',
              style: TextStyle(
                color: Color(0xFF008F7A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Bangla',
            style: TextStyle(
              color: Color(0xFF263238),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartKashMark extends StatelessWidget {
  const _SmartKashMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            AppAssets.smartKashLogoMark,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        const Flexible(
          child: Text(
            AppConfig.appName,
            style: TextStyle(
              color: Color(0xFF263238),
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.enabled,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        labelText: 'Account Number',
        prefixText: '+88  ',
        hintText: '01XXXXXXXXX',
        border: UnderlineInputBorder(),
      ),
      style: const TextStyle(
        fontSize: 23,
        color: Color(0xFF263238),
        letterSpacing: 0.4,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _OtpPreview extends StatelessWidget {
  const _OtpPreview({
    required this.otpCode,
    required this.enabled,
  });

  final String otpCode;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Firebase Test OTP',
          style: TextStyle(
            color: Color(0xFF607D8B),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE0E6EB)),
                  ),
                ),
                child: Text(
                  otpCode.isEmpty
                      ? enabled
                          ? 'Enter test OTP'
                          : 'Send OTP first'
                      : List.filled(otpCode.length, '*').join(),
                  style: TextStyle(
                    color: otpCode.isEmpty
                        ? const Color(0xFFB0BEC5)
                        : const Color(0xFF263238),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            const Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF008F7A),
              size: 42,
            ),
          ],
        ),
      ],
    );
  }
}

class _NextActionBar extends StatelessWidget {
  const _NextActionBar({
    required this.enabled,
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final bool isLoading;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      child: Container(
        height: 62,
        color: enabled ? const Color(0xFF008F7A) : const Color(0xFF9EA7AD),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          children: [
            Text(
              isLoading ? 'Please wait' : label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: enabled ? 1 : 0.72),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            else
              const Icon(Icons.arrow_forward, color: Colors.white, size: 36),
          ],
        ),
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFB42318) : const Color(0xFF00695C);
    final background =
        isError ? const Color(0xFFFFF1F0) : const Color(0xFFE9F8F4);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({
    required this.onNumberTap,
    required this.onBackspace,
  });

  final ValueChanged<String> onNumberTap;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Container(
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: Column(
        children: [
          for (final row in rows)
            Row(
              children: [
                for (final value in row)
                  Expanded(
                    child: _KeypadButton(
                      label: value,
                      onTap: () => onNumberTap(value),
                    ),
                  ),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: _KeypadIconButton(
                  icon: Icons.close,
                  onTap: onBackspace,
                ),
              ),
              Expanded(
                child: _KeypadButton(
                  label: '0',
                  onTap: () => onNumberTap('0'),
                ),
              ),
              Expanded(
                child: _KeypadIconButton(
                  icon: Icons.keyboard_return,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(48),
      child: SizedBox(
        height: 64,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF455A64),
              fontSize: 34,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _KeypadIconButton extends StatelessWidget {
  const _KeypadIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(48),
      child: SizedBox(
        height: 64,
        child: Center(
          child: Container(
            width: 46,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF455A64),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
