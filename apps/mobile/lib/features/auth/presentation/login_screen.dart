import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/app_config.dart';
import '../../../core/constants/app_assets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = 'login';
  static const routePath = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _otpCode = '';

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

  @override
  Widget build(BuildContext context) {
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
                    _PhoneField(controller: _phoneController),
                    const SizedBox(height: 28),
                    _OtpPreview(otpCode: _otpCode),
                    const SizedBox(height: 22),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Use Firebase test OTP code'),
                    ),
                  ],
                ),
              ),
            ),
            _NextActionBar(enabled: _canContinue),
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
  const _PhoneField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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
  const _OtpPreview({required this.otpCode});

  final String otpCode;

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
                      ? 'Enter test OTP'
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
  const _NextActionBar({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      color: enabled ? const Color(0xFF008F7A) : const Color(0xFF9EA7AD),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          Text(
            'Next',
            style: TextStyle(
              color: Colors.white.withValues(alpha: enabled ? 1 : 0.72),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward, color: Colors.white, size: 36),
        ],
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
