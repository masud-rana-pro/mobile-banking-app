import 'package:flutter/material.dart';

class NotificationInboxScreen extends StatelessWidget {
  const NotificationInboxScreen({super.key});

  static const routeName = 'notification-inbox';
  static const routePath = '/notifications';

  static const _events = [
    _NotificationEvent(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Add Money updates',
      description: 'Approval or rejection alerts from admin decisions.',
      color: Color(0xFF0E9F6E),
    ),
    _NotificationEvent(
      icon: Icons.send_to_mobile_outlined,
      title: 'Send Money alerts',
      description: 'Successful transfer alerts for sender and receiver.',
      color: Color(0xFF1D7ED6),
    ),
    _NotificationEvent(
      icon: Icons.shopping_bag_outlined,
      title: 'Merchant payments',
      description: 'Payment completion alerts for customer and merchant.',
      color: Color(0xFFE08B2D),
    ),
    _NotificationEvent(
      icon: Icons.phone_android_outlined,
      title: 'Recharge and savings',
      description: 'Demo recharge and savings deposit confirmations.',
      color: Color(0xFF7A4CC2),
    ),
    _NotificationEvent(
      icon: Icons.account_balance_outlined,
      title: 'Loan status',
      description: 'Loan request approval or rejection alerts.',
      color: Color(0xFF795548),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const _InboxSummaryCard(),
          const SizedBox(height: 22),
          const Text(
            'Important alerts',
            style: TextStyle(
              color: Color(0xFF263238),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ..._events.map((event) => _NotificationEventTile(event: event)),
          const SizedBox(height: 18),
          const _LocalTestingNote(),
        ],
      ),
    );
  }
}

class _InboxSummaryCard extends StatelessWidget {
  const _InboxSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFE8DD)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_active_outlined,
              color: Color(0xFF008F7A), size: 34),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction alerts only',
                  style: TextStyle(
                    color: Color(0xFF263238),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'SmartKash MVP keeps notifications focused on important money and status events. Local FCM delivery may be limited until deployment.',
                  style: TextStyle(
                    color: Color(0xFF4F646B),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

class _NotificationEvent {
  const _NotificationEvent({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}

class _NotificationEventTile extends StatelessWidget {
  const _NotificationEventTile({required this.event});

  final _NotificationEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(event.icon, color: event.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Color(0xFF263238),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.description,
                  style: const TextStyle(
                    color: Color(0xFF607D8B),
                    height: 1.3,
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

class _LocalTestingNote extends StatelessWidget {
  const _LocalTestingNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFECB3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFFE08B2D)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This screen is the MVP inbox placeholder. Backend already sends important FCM alerts when enabled, but notification history storage is future scope.',
              style: TextStyle(
                color: Color(0xFF5D4037),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
