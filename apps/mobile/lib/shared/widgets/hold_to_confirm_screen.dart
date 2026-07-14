import 'dart:async';

import 'package:flutter/material.dart';

class HoldToConfirmDetail {
  const HoldToConfirmDetail({
    required this.label,
    required this.value,
    this.mutedValue,
  });

  final String label;
  final String value;
  final String? mutedValue;
}

class HoldToConfirmScreen extends StatefulWidget {
  const HoldToConfirmScreen({
    super.key,
    required this.actionName,
    required this.accountName,
    required this.accountNumber,
    required this.details,
    required this.onCancel,
    required this.onConfirmed,
    this.avatarUrl,
    this.avatarIcon = Icons.person_outline,
    this.isLoading = false,
  });

  final String actionName;
  final String accountName;
  final String accountNumber;
  final String? avatarUrl;
  final IconData avatarIcon;
  final List<HoldToConfirmDetail> details;
  final VoidCallback onCancel;
  final VoidCallback onConfirmed;
  final bool isLoading;

  @override
  State<HoldToConfirmScreen> createState() => _HoldToConfirmScreenState();
}

class _HoldToConfirmScreenState extends State<HoldToConfirmScreen> {
  static const _holdDuration = Duration(milliseconds: 900);
  static const _tick = Duration(milliseconds: 30);
  Timer? _timer;
  double _progress = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startHold() {
    if (widget.isLoading) {
      return;
    }
    _timer?.cancel();
    setState(() => _progress = 0);
    final startedAt = DateTime.now();
    _timer = Timer.periodic(_tick, (timer) {
      final elapsed = DateTime.now().difference(startedAt);
      final nextProgress =
          elapsed.inMilliseconds / _holdDuration.inMilliseconds;
      if (nextProgress >= 1) {
        timer.cancel();
        setState(() => _progress = 1);
        widget.onConfirmed();
        return;
      }
      setState(() => _progress = nextProgress);
    });
  }

  void _cancelHold() {
    _timer?.cancel();
    if (mounted && _progress < 1) {
      setState(() => _progress = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: const Color(0x99003B46),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: Material(
              color: Colors.white,
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
                    margin: const EdgeInsets.only(top: 10, bottom: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7EEE8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    color: const Color(0xFF008F7A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Confirm to '),
                                    TextSpan(
                                      text: widget.actionName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton.filledTonal(
                              onPressed:
                                  widget.isLoading ? null : widget.onCancel,
                              icon: const Icon(Icons.close_rounded),
                              color: const Color(0xFF00695C),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFE9F8F4),
                                disabledBackgroundColor:
                                    const Color(0xFFF1F5F9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 34),
                        Row(
                          children: [
                            _Avatar(
                              imageUrl: widget.avatarUrl,
                              icon: widget.avatarIcon,
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.accountName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF263238),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.accountNumber,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF455A64),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 34),
                        _DetailsGrid(details: widget.details),
                      ],
                    ),
                  ),
                  _HoldFooter(
                    actionName: widget.actionName,
                    progress: _progress,
                    isLoading: widget.isLoading,
                    onLongPressStart: _startHold,
                    onLongPressEnd: _cancelHold,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.imageUrl,
    required this.icon,
  });

  final String? imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final safeUrl = imageUrl?.trim() ?? '';
    return CircleAvatar(
      radius: 34,
      backgroundColor: const Color(0xFFF1F5F9),
      child: safeUrl.isEmpty
          ? Icon(icon, color: const Color(0xFF008F7A), size: 34)
          : ClipOval(
              child: Image.network(
                safeUrl,
                width: 68,
                height: 68,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  icon,
                  color: const Color(0xFF008F7A),
                  size: 34,
                ),
              ),
            ),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.details});

  final List<HoldToConfirmDetail> details;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < details.length; i += 2)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _DetailCell(detail: details[i])),
                  Container(width: 1, color: const Color(0xFFE9EDF2)),
                  Expanded(
                    child: i + 1 < details.length
                        ? _DetailCell(detail: details[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailCell extends StatelessWidget {
  const _DetailCell({required this.detail});

  final HoldToConfirmDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE9EDF2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            detail.label,
            style: const TextStyle(
              color: Color(0xFF78909C),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail.value,
            style: const TextStyle(
              color: Color(0xFF263238),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (detail.mutedValue != null) ...[
            const SizedBox(height: 6),
            Text(
              detail.mutedValue!,
              style: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HoldFooter extends StatelessWidget {
  const _HoldFooter({
    required this.actionName,
    required this.progress,
    required this.isLoading,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  final String actionName;
  final double progress;
  final bool isLoading;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => onLongPressEnd(),
      onLongPressCancel: onLongPressEnd,
      child: SizedBox(
        height: 132,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FooterArcPainter(progress: progress),
              ),
            ),
            Positioned(
              top: 28,
              child: Icon(
                Icons.verified_rounded,
                color: Colors.white.withValues(alpha: 0.95),
                size: 40,
              ),
            ),
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        'Tap and hold to $actionName',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
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
}

class _FooterArcPainter extends CustomPainter {
  const _FooterArcPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final safeProgress = progress.clamp(0.0, 1.0);
    final basePaint = Paint()
      ..color = const Color(0xFF008F7A)
      ..style = PaintingStyle.fill;
    final progressPaint = Paint()
      ..color = const Color(0xFF00695C)
      ..style = PaintingStyle.fill;
    final lineBasePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final lineProgressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.26)
      ..quadraticBezierTo(
        size.width / 2,
        -size.height * 0.18,
        size.width,
        size.height * 0.26,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, basePaint);

    if (safeProgress > 0) {
      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(0, 0, size.width * safeProgress, size.height),
      );
      canvas.drawPath(path, progressPaint);
      canvas.restore();
    }

    final topLinePath = Path()
      ..moveTo(0, size.height * 0.26)
      ..quadraticBezierTo(
        size.width / 2,
        -size.height * 0.18,
        size.width,
        size.height * 0.26,
      );
    canvas.drawPath(topLinePath, lineBasePaint);

    if (safeProgress > 0) {
      final metric = topLinePath.computeMetrics().first;
      final progressPath = metric.extractPath(
        0,
        metric.length * safeProgress,
      );
      canvas.drawPath(progressPath, lineProgressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FooterArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
