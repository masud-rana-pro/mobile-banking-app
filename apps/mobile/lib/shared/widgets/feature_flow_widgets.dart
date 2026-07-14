import 'package:flutter/material.dart';

class FeatureIntroCard extends StatelessWidget {
  const FeatureIntroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD7EEE8)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF008F7A),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF263238),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF607D8B),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class ProfileImageAvatar extends StatelessWidget {
  const ProfileImageAvatar({
    super.key,
    required this.imageUrl,
    required this.fallbackIcon,
    this.radius = 24,
    this.backgroundColor = const Color(0xFFE9F8F4),
    this.iconColor = const Color(0xFF008F7A),
  });

  final String? imageUrl;
  final IconData fallbackIcon;
  final double radius;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final safeUrl = imageUrl?.trim() ?? '';
    if (safeUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Icon(fallbackIcon, color: iconColor, size: radius),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: Image.network(
          safeUrl,
          key: ValueKey(safeUrl),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            fallbackIcon,
            color: iconColor,
            size: radius,
          ),
        ),
      ),
    );
  }
}

class FeatureSectionCard extends StatelessWidget {
  const FeatureSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF008F7A),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF8ABDB4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(icon, size: 22),
                ],
              ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class AmountRecipientCard extends StatelessWidget {
  const AmountRecipientCard({
    super.key,
    required this.label,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.fallbackIcon = Icons.person,
    this.trailing,
  });

  final String label;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData fallbackIcon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF607D8B),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ProfileImageAvatar(
                imageUrl: imageUrl,
                fallbackIcon: fallbackIcon,
                radius: 28,
                backgroundColor: const Color(0xFFF3F7F8),
                iconColor: const Color(0xFF008F7A),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF455A64),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class AmountEntryPanel extends StatefulWidget {
  const AmountEntryPanel({
    super.key,
    required this.controller,
    required this.proceedLabel,
    required this.onProceed,
    this.loading = false,
    this.tabs = const ['Amount'],
    this.presets = const [100, 500, 1000],
    this.availableBalanceText,
    this.sourceLabel = 'SmartKash',
    this.secondarySourceLabel = 'Pay Later',
    this.showPromo = true,
    this.showProceed = true,
  });

  final TextEditingController controller;
  final String proceedLabel;
  final VoidCallback? onProceed;
  final bool loading;
  final List<String> tabs;
  final List<num> presets;
  final String? availableBalanceText;
  final String sourceLabel;
  final String secondarySourceLabel;
  final bool showPromo;
  final bool showProceed;

  @override
  State<AmountEntryPanel> createState() => _AmountEntryPanelState();
}

class _AmountEntryPanelState extends State<AmountEntryPanel> {
  static const _accent = Color(0xFF008F7A);
  static const _muted = Color(0xFF607D8B);
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant AmountEntryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountText = widget.controller.text.trim();
    final hasAmount = amountText.isNotEmpty;
    final canProceed = widget.onProceed != null && hasAmount && !widget.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tabs(),
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 82,
                child: Column(
                  children: [
                    for (final amount in widget.presets.take(4)) ...[
                      _presetChip(amount),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      controller: widget.controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '৳0',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 44,
                          fontWeight: FontWeight.w300,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text.rich(
                      TextSpan(
                        text: 'Available Balance: ',
                        style: const TextStyle(
                          color: Color(0xFF455A64),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: widget.availableBalanceText ?? 'Unavailable',
                            style: const TextStyle(
                              color: Color(0xFF263238),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Source',
                      style: TextStyle(
                        color: Color(0xFF607D8B),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'See All',
                    style: TextStyle(
                      color: Color(0xFF008F7A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _sourceChip(widget.sourceLabel, selected: true),
                  _sourceChip(widget.secondarySourceLabel, selected: false),
                ],
              ),
              if (widget.showPromo) ...[
                const SizedBox(height: 22),
                const Row(
                  children: [
                    Icon(
                      Icons.local_offer,
                      color: Color(0xFF008F7A),
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Coupon / Promo Code',
                      style: TextStyle(
                        color: Color(0xFF008F7A),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF008F7A),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (widget.showProceed) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: canProceed ? widget.onProceed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                disabledBackgroundColor: const Color(0xFF9E9E9E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: widget.loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      children: [
                        Text(
                          widget.proceedLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward, size: 32),
                      ],
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _tabs() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < widget.tabs.length; index++)
              InkWell(
                onTap: () => setState(() => _selectedTab = index),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _selectedTab == index
                            ? _accent
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    widget.tabs[index],
                    style: TextStyle(
                      color: _selectedTab == index ? _accent : _muted,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(num amount) {
    final label =
        amount % 1 == 0 ? amount.toInt().toString() : amount.toStringAsFixed(2);

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        widget.controller.text = label;
        widget.controller.selection = TextSelection.collapsed(
          offset: widget.controller.text.length,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE0E6EA)),
        ),
        alignment: Alignment.center,
        child: Text(
          '৳$label',
          style: const TextStyle(
            color: Color(0xFF455A64),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _sourceChip(String label, {required bool selected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? _accent : const Color(0xFFE0E6EA),
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? _accent : _muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            selected ? Icons.check_circle : Icons.schedule,
            color: selected ? _accent : _muted,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class PinEntryPanel extends StatelessWidget {
  const PinEntryPanel({
    super.key,
    required this.pinController,
    required this.actionTitle,
    required this.amountText,
    required this.totalText,
    required this.onConfirm,
    this.loading = false,
    this.chargeText = '+ No charge',
    this.typeLabel = 'Prepaid',
    this.secondaryTypeLabel = 'Postpaid',
    this.showTypeSelector = true,
    this.onBackToAmount,
    this.recipient,
    this.showInlineKeypad = true,
  });

  final TextEditingController pinController;
  final String actionTitle;
  final String amountText;
  final String totalText;
  final String chargeText;
  final String typeLabel;
  final String secondaryTypeLabel;
  final bool showTypeSelector;
  final bool loading;
  final VoidCallback? onConfirm;
  final VoidCallback? onBackToAmount;
  final Widget? recipient;
  final bool showInlineKeypad;

  static const _accent = Color(0xFF008F7A);
  static const _muted = Color(0xFF607D8B);

  @override
  Widget build(BuildContext context) {
    final canConfirm = onConfirm != null && !loading;

    return Semantics(
      label: 'PIN confirmation for $actionTitle',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recipient != null) ...[
            recipient!,
            const SizedBox(height: 8),
          ],
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: Row(
              children: [
                Expanded(
                    child: _SummaryColumn(label: 'Amount', value: amountText)),
                Expanded(
                  child: _SummaryColumn(
                    label: 'Charge',
                    value: chargeText,
                    mutedValue: true,
                  ),
                ),
                Expanded(
                  child: _SummaryColumn(
                    label: 'Total',
                    value: totalText,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ),
          if (showTypeSelector) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Type',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    children: [
                      _TypeChip(label: typeLabel, selected: true),
                      _TypeChip(label: secondaryTypeLabel, selected: false),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Row(
              children: [
                const Icon(Icons.lock, color: _accent, size: 28),
                const SizedBox(width: 18),
                Expanded(
                  child: TextField(
                    controller: pinController,
                    readOnly: true,
                    showCursor: false,
                    enableInteractiveSelection: false,
                    obscureText: true,
                    maxLength: 5,
                    keyboardType: TextInputType.none,
                    textAlign: TextAlign.center,
                    onTap: FocusScope.of(context).unfocus,
                    decoration: const InputDecoration(
                      hintText: 'Enter PIN',
                      counterText: '',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF263238),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                const Icon(Icons.fingerprint, color: _accent, size: 36),
              ],
            ),
          ),
          if (onBackToAmount != null)
            TextButton(
              onPressed: onBackToAmount,
              child: const Text('Change Amount'),
            ),
          if (showInlineKeypad)
            PinConfirmKeypadBar(
              pinController: pinController,
              loading: loading,
              canConfirm: canConfirm,
              onConfirm: onConfirm,
            ),
        ],
      ),
    );
  }
}

class PinConfirmKeypadBar extends StatefulWidget {
  const PinConfirmKeypadBar({
    super.key,
    required this.pinController,
    required this.loading,
    required this.canConfirm,
    required this.onConfirm,
  });

  final TextEditingController pinController;
  final bool loading;
  final bool canConfirm;
  final VoidCallback? onConfirm;

  @override
  State<PinConfirmKeypadBar> createState() => _PinConfirmKeypadBarState();
}

class _PinConfirmKeypadBarState extends State<PinConfirmKeypadBar> {
  void _appendDigit(String value) {
    if (widget.pinController.text.length >= 5 || widget.loading) {
      return;
    }
    widget.pinController.text = '${widget.pinController.text}$value';
    setState(() {});
  }

  void _backspace() {
    if (widget.pinController.text.isEmpty || widget.loading) {
      return;
    }
    widget.pinController.text = widget.pinController.text.substring(
      0,
      widget.pinController.text.length - 1,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _PinConfirmKeypad(
      loading: widget.loading,
      canConfirm: widget.canConfirm,
      onConfirm: widget.onConfirm,
      onNumberTap: _appendDigit,
      onBackspace: _backspace,
    );
  }
}

class _PinConfirmKeypad extends StatelessWidget {
  const _PinConfirmKeypad({
    required this.loading,
    required this.canConfirm,
    required this.onConfirm,
    required this.onNumberTap,
    required this.onBackspace,
  });

  final bool loading;
  final bool canConfirm;
  final VoidCallback? onConfirm;
  final ValueChanged<String> onNumberTap;
  final VoidCallback onBackspace;

  static const _accent = Color(0xFF008F7A);

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Container(
      color: const Color(0xFFF5F7FA),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: canConfirm ? onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                disabledBackgroundColor: const Color(0xFF9E9E9E),
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                elevation: 0,
              ),
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      children: [
                        const Text(
                          'Confirm PIN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward, size: 32),
                      ],
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
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
                        onTap: canConfirm ? (onConfirm ?? () {}) : () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        height: 62,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF455A64),
              fontSize: 32,
              fontWeight: FontWeight.w700,
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
        height: 62,
        child: Center(
          child: Container(
            width: 46,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF455A64),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 23),
          ),
        ),
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.value,
    this.alignEnd = false,
    this.mutedValue = false,
  });

  final String label;
  final String value;
  final bool alignEnd;
  final bool mutedValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF607D8B),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: TextStyle(
            color:
                mutedValue ? const Color(0xFF9E9E9E) : const Color(0xFF263238),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE9F8F4) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: selected ? const Color(0xFF008F7A) : const Color(0xFFE0E6EA),
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF008F7A) : const Color(0xFF455A64),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class TransactionConfirmationScreen extends StatelessWidget {
  const TransactionConfirmationScreen({
    super.key,
    required this.success,
    required this.actionName,
    required this.message,
    required this.accountName,
    required this.accountNumber,
    required this.totalText,
    required this.onPrimaryAction,
    required this.primaryLabel,
    this.transactionId,
    this.newBalanceText,
    this.time,
    this.typeText,
    this.extraLabel = 'Reference',
    this.extraValue = 'SmartKash',
    this.chargeText = '+ No charge',
    this.avatarUrl,
    this.avatarIcon = Icons.person_outline,
    this.onSecondaryAction,
    this.secondaryLabel,
  });

  final bool success;
  final String actionName;
  final String message;
  final String accountName;
  final String accountNumber;
  final String totalText;
  final String? transactionId;
  final String? newBalanceText;
  final DateTime? time;
  final String? typeText;
  final String extraLabel;
  final String extraValue;
  final String chargeText;
  final String? avatarUrl;
  final IconData avatarIcon;
  final VoidCallback onPrimaryAction;
  final String primaryLabel;
  final VoidCallback? onSecondaryAction;
  final String? secondaryLabel;

  static const _accent = Color(0xFF008F7A);
  static const _danger = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    final statusColor = success ? _accent : _danger;
    final completedAt = time ?? DateTime.now();
    final bodyHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).top -
        kToolbarHeight;
    final sheetHeight = bodyHeight.clamp(560.0, 900.0).toDouble();

    return SizedBox(
      height: sheetHeight,
      child: ColoredBox(
        color: const Color(0x99003B46),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.94,
              child: Material(
                color: const Color(0xFFF5F7FA),
                elevation: 18,
                shadowColor: Colors.black.withValues(alpha: 0.24),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 5,
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7EEE8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                        child: Column(
                          children: [
                            Icon(
                              success
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              color: statusColor,
                              size: 64,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              message.isEmpty
                                  ? success
                                      ? 'Your $actionName is successful'
                                      : '$actionName failed'
                                  : message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 22),
                            AmountRecipientCard(
                              label: 'Account',
                              title: accountName,
                              subtitle: accountNumber,
                              imageUrl: avatarUrl,
                              fallbackIcon: avatarIcon,
                            ),
                            const SizedBox(height: 8),
                            _ReceiptGrid(
                              items: [
                                _ReceiptGridItem(
                                  'Time',
                                  _formatShortDate(completedAt),
                                ),
                                _ReceiptGridItem(
                                  'Transaction ID',
                                  transactionId?.isNotEmpty == true
                                      ? transactionId!
                                      : 'N/A',
                                  copyable: transactionId?.isNotEmpty == true,
                                ),
                                _ReceiptGridItem(
                                    'Total', '$totalText\n$chargeText'),
                                _ReceiptGridItem(
                                  'New Balance',
                                  newBalanceText ?? 'Hidden',
                                ),
                                _ReceiptGridItem(
                                    'Type', typeText ?? actionName),
                                _ReceiptGridItem(extraLabel, extraValue),
                              ],
                            ),
                            const SizedBox(height: 18),
                            OutlinedButton.icon(
                              onPressed: onSecondaryAction,
                              icon: const Icon(Icons.history),
                              label: Text(secondaryLabel ?? 'View Inbox'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _accent,
                                disabledForegroundColor:
                                    const Color(0xFF90A4AE),
                                side: const BorderSide(color: _accent),
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            const Icon(
                              Icons.star,
                              color: Color(0xFF008F7A),
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You have earned',
                              style: TextStyle(
                                color: Color(0xFF607D8B),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'SmartKash Reward Points',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF263238),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                      child: PrimaryActionButton(
                        label: primaryLabel,
                        icon: Icons.arrow_forward,
                        onPressed: onPrimaryAction,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatShortDate(DateTime date) {
    final hour = _hour12(date);
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'pm' : 'am';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = (date.year % 100).toString().padLeft(2, '0');
    return '$hour:${minute}$suffix $day/$month/$year';
  }

  static String _hour12(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return hour.toString().padLeft(2, '0');
  }
}

class _ReceiptGrid extends StatelessWidget {
  const _ReceiptGrid({required this.items});

  final List<_ReceiptGridItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index += 2)
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(child: _ReceiptGridCell(item: items[index])),
                  Container(width: 1, color: const Color(0xFFE9EDF2)),
                  Expanded(
                    child: _ReceiptGridCell(
                      item: index + 1 < items.length
                          ? items[index + 1]
                          : const _ReceiptGridItem('', ''),
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

class _ReceiptGridCell extends StatelessWidget {
  const _ReceiptGridCell({required this.item});

  final _ReceiptGridItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE9EDF2))),
      ),
      child: item.label.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: Color(0xFF607D8B),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.value,
                        style: const TextStyle(
                          color: Color(0xFF263238),
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (item.copyable) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.copy,
                        color: Color(0xFF008F7A),
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ],
            ),
    );
  }
}

class _ReceiptGridItem {
  const _ReceiptGridItem(this.label, this.value, {this.copyable = false});

  final String label;
  final String value;
  final bool copyable;
}

class ReceiptSummaryCard extends StatelessWidget {
  const ReceiptSummaryCard({
    super.key,
    required this.rows,
  });

  final List<ReceiptSummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    return FeatureSectionCard(
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      row.label,
                      style: const TextStyle(
                        color: Color(0xFF607D8B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: Text(
                      row.value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: row.valueColor ?? const Color(0xFF263238),
                        fontWeight: FontWeight.w900,
                      ),
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

class ReceiptSummaryRow {
  const ReceiptSummaryRow(
    this.label,
    this.value, {
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
}
