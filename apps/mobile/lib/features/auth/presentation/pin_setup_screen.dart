import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../profile/presentation/profile_completion_screen.dart';
import '../providers/auth_providers.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  static const routeName = 'pin-setup';
  static const routePath = '/pin-setup';

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;

  String get _activeValue => _isConfirmStep ? _confirmPin : _pin;
  bool get _canContinue => _activeValue.length == 5;

  void _onNumberTap(String value) {
    if (_activeValue.length >= 5) {
      return;
    }

    setState(() {
      if (_isConfirmStep) {
        _confirmPin += value;
      } else {
        _pin += value;
      }
    });
  }

  void _onBackspace() {
    if (_activeValue.isEmpty) {
      return;
    }

    setState(() {
      if (_isConfirmStep) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _onContinue() async {
    final authState = ref.read(authControllerProvider);
    if (authState.isLoading) {
      return;
    }

    if (!_isConfirmStep) {
      if (_pin.length != 5) {
        _showMessage('Enter a 5 digit PIN.');
        return;
      }

      setState(() => _isConfirmStep = true);
      return;
    }

    if (_confirmPin.length != 5) {
      _showMessage('Confirm your 5 digit PIN.');
      return;
    }

    await ref.read(authControllerProvider.notifier).setPin(
          pin: _pin,
          confirmPin: _confirmPin,
        );
  }

  void _resetPin() {
    setState(() {
      _pin = '';
      _confirmPin = '';
      _isConfirmStep = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final title = _isConfirmStep ? 'Confirm your PIN' : 'Set your PIN';
    final subtitle = _isConfirmStep
        ? 'Re-enter the 5 digit PIN to protect money actions.'
        : 'Create a 5 digit PIN for SmartKash transactions.';

    ref.listen(authControllerProvider, (previous, next) {
      if (next.pinSet == true) {
        context.goNamed(ProfileCompletionScreen.routeName);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _PinSetupTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 44, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PinSetupMark(),
                    const SizedBox(height: 42),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        fontSize: 31,
                        height: 1.12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF607D8B),
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 42),
                    _PinDots(value: _activeValue),
                    const SizedBox(height: 22),
                    TextButton(
                      onPressed: authState.isLoading ? null : _resetPin,
                      child: const Text('Start again'),
                    ),
                    if (authState.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _PinMessage(
                        message: authState.errorMessage!,
                        isError: true,
                      ),
                    ],
                    if (authState.infoMessage != null) ...[
                      const SizedBox(height: 12),
                      _PinMessage(
                        message: authState.infoMessage!,
                        isError: false,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _PinActionBar(
              enabled: _canContinue && !authState.isLoading,
              isLoading: authState.isLoading,
              label: _isConfirmStep ? 'Save PIN' : 'Next',
              onPressed: _onContinue,
            ),
            _PinNumberPad(
              onNumberTap: _onNumberTap,
              onBackspace: _onBackspace,
            ),
          ],
        ),
      ),
    );
  }
}

class _PinSetupTopBar extends StatelessWidget {
  const _PinSetupTopBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Text(
            'SmartKash Security',
            style: TextStyle(
              color: Color(0xFF263238),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          Spacer(),
          Icon(Icons.lock_outline, color: Color(0xFF008F7A)),
        ],
      ),
    );
  }
}

class _PinSetupMark extends StatelessWidget {
  const _PinSetupMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            AppAssets.smartKashLogoMark,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Your PIN stays private. SmartKash stores only a backend hash.',
            style: TextStyle(
              color: Color(0xFF455A64),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) {
          final filled = index < value.length;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: filled ? const Color(0xFF008F7A) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    filled ? const Color(0xFF008F7A) : const Color(0xFFB0BEC5),
                width: 2,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PinActionBar extends StatelessWidget {
  const _PinActionBar({
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

class _PinMessage extends StatelessWidget {
  const _PinMessage({
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

class _PinNumberPad extends StatelessWidget {
  const _PinNumberPad({
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
                    child: _PinKeypadButton(
                      label: value,
                      onTap: () => onNumberTap(value),
                    ),
                  ),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: _PinKeypadIconButton(
                  icon: Icons.close,
                  onTap: onBackspace,
                ),
              ),
              Expanded(
                child: _PinKeypadButton(
                  label: '0',
                  onTap: () => onNumberTap('0'),
                ),
              ),
              Expanded(
                child: _PinKeypadIconButton(
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

class _PinKeypadButton extends StatelessWidget {
  const _PinKeypadButton({required this.label, required this.onTap});

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

class _PinKeypadIconButton extends StatelessWidget {
  const _PinKeypadIconButton({required this.icon, required this.onTap});

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
