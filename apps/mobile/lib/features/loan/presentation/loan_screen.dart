import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../shared/widgets/feature_flow_widgets.dart';
import '../../transaction/providers/transaction_providers.dart';
import '../domain/loan_request_summary.dart';
import '../providers/loan_providers.dart';

class LoanScreen extends ConsumerStatefulWidget {
  const LoanScreen({super.key});

  static const routeName = 'loan';
  static const routePath = '/loan';

  @override
  ConsumerState<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends ConsumerState<LoanScreen> {
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(loanRefreshProvider)());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final amount = double.tryParse(_amountController.text.trim());
    final purpose = _purposeController.text.trim();

    if (amount == null || amount < 1) {
      _showMessage('Enter a loan amount of at least BDT 1.00.');
      return;
    }

    if (purpose.isEmpty) {
      _showMessage('Enter a loan purpose.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(loanRepositoryProvider).createRequest(
            amount: amount,
            purpose: purpose,
          );
      _amountController.clear();
      _purposeController.clear();
      ref.read(loanRefreshProvider)();
      ref.read(transactionRefreshProvider)();
      _showMessage('Loan request submitted for admin review.');
    } catch (error) {
      _showMessage(_friendlyError(error, fallback: 'Could not submit loan.'));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  String _friendlyError(Object error, {required String fallback}) {
    if (error is ApiException) {
      final details = error.errors.isEmpty ? '' : ' ${error.errors.join(' ')}';
      return '${error.message}$details';
    }
    return fallback;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(loanRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FeatureIntroCard(
              icon: Icons.account_balance_outlined,
              title: 'Loan Request',
              subtitle:
                  'Submit a demo loan request and track the status. Wallet credit and repayment are future scope.',
            ),
            const SizedBox(height: 22),
            _requestCard(),
            const SizedBox(height: 28),
            const Text(
              'My Loan Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 12),
            _requestList(requestsAsync),
          ],
        ),
      ),
    );
  }

  Widget _requestCard() {
    return FeatureSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request Loan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'MVP Phase 1 only tracks request status. No disbursement or repayment is implemented.',
            style: TextStyle(color: Color(0xFF607D8B)),
          ),
          const SizedBox(height: 18),
          AmountEntryPanel(
            controller: _amountController,
            tabs: const ['Amount', 'Purpose', 'Status'],
            presets: const [1000, 5000, 10000],
            availableBalanceText: 'Loan request only',
            sourceLabel: 'MVP Request',
            secondarySourceLabel: 'Disbursement later',
            showPromo: false,
            showProceed: false,
            proceedLabel: 'Proceed',
            onProceed: null,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _purposeController,
            maxLength: 255,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Purpose',
              hintText: 'Business, education, emergency, device purchase',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          PrimaryActionButton(
            label: 'Submit Request',
            icon: Icons.check,
            loading: _isSubmitting,
            onPressed: _submitRequest,
          ),
        ],
      ),
    );
  }

  Widget _requestList(AsyncValue<List<LoanRequestSummary>> requestsAsync) {
    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No loan requests yet',
                style: TextStyle(color: Color(0xFF90A4AE)),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _requestTile(requests[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text(
        _friendlyError(error, fallback: 'Could not load loan requests.'),
        style: const TextStyle(color: Color(0xFFC62828)),
      ),
    );
  }

  Widget _requestTile(LoanRequestSummary request) {
    final statusColor = switch (request.status) {
      'APPROVED' => const Color(0xFF2E7D32),
      'REJECTED' => const Color(0xFFC62828),
      _ => const Color(0xFFE08B2D),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.12),
            child: Icon(Icons.account_balance, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BDT ${request.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.purpose,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF607D8B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(
                label: request.status,
                color: statusColor,
              ),
              if (request.reviewedAt != null) ...[
                const SizedBox(height: 4),
                const Text(
                  'Reviewed',
                  style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
