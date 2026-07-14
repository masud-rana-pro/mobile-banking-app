import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../shared/widgets/feature_flow_widgets.dart';
import '../../../shared/widgets/hold_to_confirm_screen.dart';
import '../../auth/providers/auth_providers.dart';
import '../../transaction/providers/transaction_providers.dart';
import '../../wallet/providers/wallet_providers.dart';
import '../domain/savings_deposit_result.dart';
import '../domain/savings_goal.dart';
import '../providers/savings_providers.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  static const routeName = 'savings';
  static const routePath = '/savings';

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _targetDateController = TextEditingController();
  final _depositAmountController = TextEditingController();
  final _pinController = TextEditingController();
  final _noteController = TextEditingController();

  SavingsGoal? _selectedGoal;
  SavingsDepositResult? _depositResult;
  String? _depositIdempotencyKey;
  bool _isCreating = false;
  bool _isDepositing = false;
  bool _isDepositAmountStep = false;
  bool _isDepositPinStep = false;
  bool _isDepositConfirming = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(savingsRefreshProvider)());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _targetDateController.dispose();
    _depositAmountController.dispose();
    _pinController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _createGoal() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_targetAmountController.text.trim());
    final targetDateText = _targetDateController.text.trim();
    final targetDate =
        targetDateText.isEmpty ? null : DateTime.tryParse(targetDateText);

    if (name.isEmpty) {
      _showMessage('Enter a savings goal name.');
      return;
    }

    if (amount == null || amount < 1) {
      _showMessage('Enter a target amount of at least BDT 1.00.');
      return;
    }

    if (targetDateText.isNotEmpty && targetDate == null) {
      _showMessage('Use target date format YYYY-MM-DD.');
      return;
    }

    setState(() => _isCreating = true);

    try {
      await ref.read(savingsRepositoryProvider).createGoal(
            name: name,
            targetAmount: amount,
            targetDate: targetDate,
          );
      _nameController.clear();
      _targetAmountController.clear();
      _targetDateController.clear();
      ref.read(savingsRefreshProvider)();
      _showMessage('Savings goal created.');
    } catch (error) {
      _showMessage(_friendlyError(error, fallback: 'Could not create goal.'));
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _depositToGoal() async {
    final goal = _selectedGoal;
    final amount = double.tryParse(_depositAmountController.text.trim());
    final pin = _pinController.text.trim();

    if (goal == null) {
      _showMessage('Select a savings goal first.');
      return;
    }

    if (amount == null || amount < 1) {
      _showMessage('Enter a deposit amount of at least BDT 1.00.');
      return;
    }

    if (pin.length != 5) {
      _showMessage('Enter your 5-digit PIN.');
      return;
    }

    setState(() => _isDepositing = true);

    try {
      final repository = ref.read(savingsRepositoryProvider);
      final result = await repository.deposit(
        goalId: goal.id,
        amount: amount,
        pin: pin,
        idempotencyKey: _depositIdempotencyKey ??=
            repository.createIdempotencyKey(),
        note: _noteController.text.trim(),
      );
      ref.read(walletRefreshProvider)();
      ref.read(savingsRefreshProvider)();
      ref.read(transactionRefreshProvider)();
      _pinController.clear();
      _noteController.clear();
      _depositResult = result;
      _depositIdempotencyKey = null;
      _isDepositAmountStep = false;
      _isDepositPinStep = false;
      _isDepositConfirming = false;
    } catch (error) {
      _showMessage(_friendlyError(error, fallback: 'Could not deposit.'));
    } finally {
      setState(() => _isDepositing = false);
    }
  }

  void _continueDepositToPin() {
    final goal = _selectedGoal;
    final amount = double.tryParse(_depositAmountController.text.trim());

    if (goal == null) {
      _showMessage('Select a savings goal first.');
      return;
    }

    if (amount == null || amount < 1) {
      _showMessage('Enter a deposit amount of at least BDT 1.00.');
      return;
    }

    setState(() => _isDepositPinStep = true);
  }

  void _continueDepositToAmount() {
    if (_selectedGoal == null) {
      _showMessage('Select a savings goal first.');
      return;
    }

    setState(() => _isDepositAmountStep = true);
  }

  void _continueDepositToConfirm() {
    final pin = _pinController.text.trim();

    if (pin.length != 5) {
      _showMessage('Enter your 5-digit PIN.');
      return;
    }

    setState(() {
      _depositIdempotencyKey ??=
          ref.read(savingsRepositoryProvider).createIdempotencyKey();
      _isDepositPinStep = false;
      _isDepositConfirming = true;
    });
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
    final goalsAsync = ref.watch(savingsGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings'),
        centerTitle: true,
      ),
      bottomNavigationBar: _isDepositPinStep
          ? SafeArea(
              top: false,
              child: PinConfirmKeypadBar(
                pinController: _pinController,
                loading: _isDepositing,
                canConfirm: !_isDepositing,
                onConfirm: _continueDepositToConfirm,
              ),
            )
          : null,
      body: _isDepositConfirming
          ? _depositConfirmStep()
          : _depositResult != null
              ? _depositResultStep()
              : _isDepositPinStep
                  ? _depositPinStep()
                  : _isDepositAmountStep
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _depositAmountStep(),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FeatureIntroCard(
                                icon: Icons.savings_outlined,
                                title: 'Goal Savings',
                                subtitle:
                                    'Create goals and deposit from your SmartKash wallet. Every deposit appears in Inbox transactions.',
                              ),
                              const SizedBox(height: 22),
                              _createGoalCard(),
                              const SizedBox(height: 28),
                              const Text(
                                'My Goals',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF263238),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _goalsList(goalsAsync),
                              const SizedBox(height: 28),
                              _depositCard(goalsAsync),
                            ],
                          ),
                        ),
    );
  }

  Widget _depositPinStep() {
    final goal = _selectedGoal!;
    final amount = double.tryParse(_depositAmountController.text.trim())
            ?.toStringAsFixed(2) ??
        '0.00';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      child: PinEntryPanel(
        pinController: _pinController,
        actionTitle: 'Savings Deposit',
        amountText: '৳$amount',
        totalText: '৳$amount',
        typeLabel: 'Goal',
        secondaryTypeLabel: 'Auto Save',
        loading: _isDepositing,
        onConfirm: _continueDepositToConfirm,
        onBackToAmount: () => setState(() {
          _isDepositPinStep = false;
          _isDepositAmountStep = true;
        }),
        showInlineKeypad: false,
        recipient: AmountRecipientCard(
          label: 'Savings Goal',
          title: goal.name,
          subtitle: 'Target ৳${goal.targetAmount.toStringAsFixed(2)}',
          fallbackIcon: Icons.savings_outlined,
        ),
      ),
    );
  }

  Widget _depositResultStep() {
    final result = _depositResult!;
    final avatarUrl = ref.watch(authControllerProvider).avatarUrl?.trim();

    return TransactionConfirmationScreen(
      success: result.success,
      actionName: 'Savings Deposit',
      message:
          result.message.isEmpty ? 'Savings deposit completed' : result.message,
      accountName: result.goal.name,
      accountNumber: 'Target ৳${result.goal.targetAmount.toStringAsFixed(2)}',
      avatarUrl: avatarUrl,
      avatarIcon: Icons.savings_outlined,
      totalText: '৳${result.amount.toStringAsFixed(2)}',
      transactionId: result.transactionReference,
      newBalanceText: result.walletBalanceAfter == null
          ? null
          : '৳${result.walletBalanceAfter!.toStringAsFixed(2)}',
      time: result.createdAt,
      typeText: 'Goal Savings',
      extraLabel: 'Goal',
      extraValue: result.goal.name,
      secondaryLabel: 'View Goals',
      onSecondaryAction: () {
        setState(() {
          _depositResult = null;
          _depositAmountController.clear();
        });
      },
      primaryLabel: 'Back to Savings',
      onPrimaryAction: () {
        setState(() {
          _depositResult = null;
          _depositAmountController.clear();
        });
      },
    );
  }

  Widget _depositConfirmStep() {
    final goal = _selectedGoal!;
    final amount = double.tryParse(_depositAmountController.text.trim())
            ?.toStringAsFixed(2) ??
        '0.00';

    return HoldToConfirmScreen(
      actionName: 'Savings Deposit',
      accountName: goal.name,
      accountNumber: 'Target Tk ${goal.targetAmount.toStringAsFixed(2)}',
      avatarIcon: Icons.savings_outlined,
      isLoading: _isDepositing,
      onCancel: () => setState(() => _isDepositConfirming = false),
      onConfirmed: _depositToGoal,
      details: [
        HoldToConfirmDetail(
            label: 'Total', value: 'Tk $amount', mutedValue: '+ No charge'),
        const HoldToConfirmDetail(label: 'Type', value: 'Goal Savings'),
        HoldToConfirmDetail(label: 'Goal', value: goal.name),
        const HoldToConfirmDetail(label: 'Reference', value: 'SmartKash'),
      ],
    );
  }

  Widget _createGoalCard() {
    return FeatureSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Goal',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set a target and save gradually from your wallet.',
            style: TextStyle(color: Color(0xFF607D8B)),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Goal Name',
              hintText: 'New phone, laptop, emergency fund',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _targetAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Target Amount (BDT)',
              prefixText: 'BDT ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _targetDateController,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              labelText: 'Target Date (optional)',
              hintText: 'YYYY-MM-DD',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          PrimaryActionButton(
            label: 'Create Goal',
            loading: _isCreating,
            onPressed: _isCreating ? null : _createGoal,
          ),
        ],
      ),
    );
  }

  Widget _goalsList(AsyncValue<List<SavingsGoal>> goalsAsync) {
    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No savings goals yet',
                style: TextStyle(color: Color(0xFF90A4AE)),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: goals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final goal = goals[index];
            return _goalTile(goal);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text(
        _friendlyError(error, fallback: 'Could not load savings goals.'),
        style: const TextStyle(color: Color(0xFFC62828)),
      ),
    );
  }

  Widget _goalTile(SavingsGoal goal) {
    final selected = _selectedGoal?.id == goal.id;

    return InkWell(
      onTap: () => setState(() {
        _selectedGoal = goal;
        _depositIdempotencyKey = null;
      }),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF008F7A) : const Color(0xFFE9EDF2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.savings_outlined, color: Color(0xFF008F7A)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    goal.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  goal.status,
                  style: const TextStyle(
                    color: Color(0xFF607D8B),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: const Color(0xFFE9EDF2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF008F7A)),
            ),
            const SizedBox(height: 8),
            Text(
              'BDT ${goal.currentAmount.toStringAsFixed(2)} of BDT ${goal.targetAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF455A64),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (goal.targetDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Target: ${goal.targetDate!.toIso8601String().substring(0, 10)}',
                style: const TextStyle(color: Color(0xFF607D8B)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _depositCard(AsyncValue<List<SavingsGoal>> goalsAsync) {
    final goals = goalsAsync.valueOrNull ?? const <SavingsGoal>[];
    final activeGoals = goals.where((goal) => goal.status == 'ACTIVE').toList();
    final selectedValue =
        activeGoals.any((goal) => goal.id == _selectedGoal?.id)
            ? _selectedGoal!.id
            : null;

    return FeatureSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deposit to Goal',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Deposits debit your wallet and update goal progress.',
            style: TextStyle(color: Color(0xFF607D8B)),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<int>(
            initialValue: selectedValue,
            decoration: const InputDecoration(
              labelText: 'Savings Goal',
              border: OutlineInputBorder(),
            ),
            items: activeGoals
                .map(
                  (goal) => DropdownMenuItem<int>(
                    value: goal.id,
                    child: Text(goal.name),
                  ),
                )
                .toList(),
            onChanged: (id) {
              SavingsGoal? goal;
              for (final item in activeGoals) {
                if (item.id == id) {
                  goal = item;
                  break;
                }
              }
              setState(() {
                _selectedGoal = goal;
                _depositResult = null;
                _depositIdempotencyKey = null;
                _isDepositAmountStep = false;
                _isDepositPinStep = false;
                _isDepositConfirming = false;
              });
            },
          ),
          const SizedBox(height: 18),
          PrimaryActionButton(
            label: 'Next: Enter Amount',
            loading: _isDepositing,
            onPressed: activeGoals.isEmpty || _isDepositing
                ? null
                : _continueDepositToAmount,
          ),
        ],
      ),
    );
  }

  Widget _depositAmountStep() {
    final goal = _selectedGoal!;
    final balanceText = ref.watch(walletSummaryProvider).maybeWhen(
          data: (wallet) => '৳${wallet.balance.toStringAsFixed(2)}',
          orElse: () => null,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmountRecipientCard(
          label: 'Savings Goal',
          title: goal.name,
          subtitle: 'Target Tk ${goal.targetAmount.toStringAsFixed(2)}',
          fallbackIcon: Icons.savings_outlined,
        ),
        const SizedBox(height: 18),
        AmountEntryPanel(
          controller: _depositAmountController,
          tabs: const ['Amount', 'Goal', 'Reward'],
          presets: const [100, 500, 1000],
          availableBalanceText: balanceText,
          sourceLabel: 'Wallet',
          proceedLabel: 'Proceed',
          showProceed: false,
          onProceed: null,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _noteController,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        TextButton.icon(
          onPressed: _isDepositing
              ? null
              : () => setState(() => _isDepositAmountStep = false),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Change Goal'),
        ),
        const SizedBox(height: 12),
        PrimaryActionButton(
          label: 'Next: Enter PIN',
          loading: _isDepositing,
          onPressed: _isDepositing ? null : _continueDepositToPin,
        ),
      ],
    );
  }
}
