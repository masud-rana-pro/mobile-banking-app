import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/api_exception.dart';
import '../../../shared/widgets/feature_flow_widgets.dart';
import '../../../shared/widgets/hold_to_confirm_screen.dart';
import '../../notification/presentation/notification_inbox_screen.dart';
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

enum _LoanStep { form, confirm, result }

class _LoanProduct {
  const _LoanProduct({
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final String label;
  final String subtitle;
  final IconData icon;
}

class _LoanScreenState extends ConsumerState<LoanScreen> {
  static const _loanProducts = [
    _LoanProduct(
      label: 'Personal Loan',
      subtitle: 'Daily needs and emergency support',
      icon: Icons.person_outline,
    ),
    _LoanProduct(
      label: 'Small Business Loan',
      subtitle: 'Shop, merchant, or agent cash flow',
      icon: Icons.storefront_outlined,
    ),
    _LoanProduct(
      label: 'Education Loan',
      subtitle: 'Course, exam, or learning cost',
      icon: Icons.school_outlined,
    ),
    _LoanProduct(
      label: 'Device Loan',
      subtitle: 'Phone or work device purchase',
      icon: Icons.phone_android_outlined,
    ),
  ];

  static const _quickAmounts = [1000, 5000, 10000, 20000, 50000];
  static const _tenureOptions = [1, 3, 6, 12];

  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  _LoanProduct _selectedProduct = _loanProducts.first;
  int _selectedTenureMonths = _tenureOptions[2];
  _LoanStep _step = _LoanStep.form;
  LoanRequestSummary? _submittedRequest;
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

  void _continueToConfirm() {
    final amount = double.tryParse(_amountController.text.trim());
    final purpose = _composedPurpose();

    if (amount == null || amount < 1) {
      _showMessage('Enter a loan amount of at least BDT 1.00.');
      return;
    }

    if (_purposeController.text.trim().isEmpty) {
      _showMessage('Enter a loan purpose.');
      return;
    }

    if (purpose.length > 255) {
      _showMessage('Purpose is too long. Keep it shorter.');
      return;
    }

    setState(() => _step = _LoanStep.confirm);
  }

  Future<void> _submitRequest() async {
    final amount = double.tryParse(_amountController.text.trim());
    final purpose = _composedPurpose();

    if (amount == null ||
        amount < 1 ||
        _purposeController.text.trim().isEmpty) {
      setState(() => _step = _LoanStep.form);
      _showMessage('Enter a valid amount and purpose first.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = await ref.read(loanRepositoryProvider).createRequest(
            amount: amount,
            purpose: purpose,
          );
      _submittedRequest = request;
      ref.read(loanRefreshProvider)();
      ref.read(transactionRefreshProvider)();
      setState(() => _step = _LoanStep.result);
    } catch (error) {
      setState(() => _step = _LoanStep.form);
      _showMessage(_friendlyError(error, fallback: 'Could not submit loan.'));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    setState(() {
      _step = _LoanStep.form;
      _submittedRequest = null;
      _selectedProduct = _loanProducts.first;
      _selectedTenureMonths = _tenureOptions[2];
      _amountController.clear();
      _purposeController.clear();
    });
  }

  String _composedPurpose() {
    final note = _purposeController.text.trim();
    return '${_selectedProduct.label} | Tenure: $_selectedTenureMonths months | $note';
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
    final isPopupStep = _step == _LoanStep.confirm || _step == _LoanStep.result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan'),
        centerTitle: true,
      ),
      body: isPopupStep
          ? _buildPopupBody()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FeatureIntroCard(
                    icon: Icons.account_balance_outlined,
                    title: 'Loan Request',
                    subtitle:
                        'Submit a loan request and track its approval status.',
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

  Widget _buildPopupBody() {
    return switch (_step) {
      _LoanStep.confirm => _confirmStep(),
      _LoanStep.result => _resultStep(),
      _LoanStep.form => const SizedBox.shrink(),
    };
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
            'Choose a loan type, enter the amount, then submit your request for review.',
            style: TextStyle(color: Color(0xFF607D8B)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loan Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF546E7A),
            ),
          ),
          const SizedBox(height: 10),
          _loanProductGrid(),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Loan Amount',
              prefixText: 'Tk ',
              hintText: 'Enter amount',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts
                .map(
                  (amount) => ChoiceChip(
                    label: Text('Tk $amount'),
                    selected: _amountController.text == '$amount',
                    onSelected: (_) {
                      setState(() => _amountController.text = '$amount');
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Repayment Tenure',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF546E7A),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tenureOptions
                .map(
                  (months) => ChoiceChip(
                    label: Text('$months month${months == 1 ? '' : 's'}'),
                    selected: _selectedTenureMonths == months,
                    onSelected: (_) {
                      setState(() => _selectedTenureMonths = months);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _purposeController,
            maxLength: 180,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Purpose',
              hintText: 'Why do you need this loan?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          PrimaryActionButton(
            label: 'Review Request',
            icon: Icons.arrow_forward,
            loading: _isSubmitting,
            onPressed: _continueToConfirm,
          ),
        ],
      ),
    );
  }

  Widget _loanProductGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _loanProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        final product = _loanProducts[index];
        final selected = product.label == _selectedProduct.label;
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _selectedProduct = product),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE4F5F1) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? const Color(0xFF008F7A)
                    : const Color(0xFFE1E7EC),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: selected
                          ? const Color(0xFF008F7A)
                          : const Color(0xFFF1F5F8),
                      child: Icon(
                        product.icon,
                        color:
                            selected ? Colors.white : const Color(0xFF607D8B),
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    if (selected)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF008F7A),
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  product.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  product.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF78909C),
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _confirmStep() {
    final amount =
        double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ??
            '0.00';
    final purpose = _purposeController.text.trim();

    return HoldToConfirmScreen(
      actionName: 'Loan Request',
      accountName: _selectedProduct.label,
      accountNumber: purpose,
      avatarIcon: _selectedProduct.icon,
      isLoading: _isSubmitting,
      onCancel: () => setState(() => _step = _LoanStep.form),
      onConfirmed: _submitRequest,
      details: [
        HoldToConfirmDetail(
          label: 'Requested',
          value: 'Tk $amount',
          mutedValue: 'Subject to review',
        ),
        const HoldToConfirmDetail(label: 'Status', value: 'Pending Review'),
        HoldToConfirmDetail(
          label: 'Tenure',
          value: '$_selectedTenureMonths months',
        ),
        HoldToConfirmDetail(label: 'Purpose', value: purpose),
      ],
    );
  }

  Widget _resultStep() {
    final request = _submittedRequest;
    final amount =
        request?.amount ?? double.tryParse(_amountController.text.trim()) ?? 0;
    final purpose = request?.purpose ?? _purposeController.text.trim();
    final transactionId = request?.transactionReference?.isNotEmpty == true
        ? request!.transactionReference
        : request == null
            ? null
            : 'LOAN-${request.id}';

    return TransactionConfirmationScreen(
      success: true,
      actionName: 'Loan Request',
      message: 'Your loan request was submitted',
      accountName: _selectedProduct.label,
      accountNumber: purpose,
      avatarIcon: _selectedProduct.icon,
      totalText: 'Tk ${amount.toStringAsFixed(2)}',
      transactionId: transactionId,
      time: request?.createdAt,
      typeText: 'Loan Request',
      extraLabel: 'Status',
      extraValue: request?.status ?? 'PENDING',
      chargeText: 'No disbursement yet',
      newBalanceText: 'Unchanged',
      secondaryLabel: 'View Inbox',
      onSecondaryAction: () =>
          context.pushNamed(NotificationInboxScreen.routeName),
      primaryLabel: 'Request Again',
      onPrimaryAction: _resetForm,
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
