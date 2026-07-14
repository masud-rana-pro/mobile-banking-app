import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../wallet/providers/wallet_providers.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  static const routeName = 'account';
  static const routePath = '/account';

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  String? _serviceMessage;
  bool _serviceMessageIsError = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final walletAsync = ref.watch(walletSummaryProvider);
    final displayName = authState.fullName?.trim().isNotEmpty == true
        ? authState.fullName!.trim()
        : 'SmartKash User';
    final phoneNumber = authState.backendToken?.phoneNumber ?? '';
    final localPhoneNumber = _toLocalMobileNumber(phoneNumber);
    final avatarUrl = authState.avatarUrl?.trim() ?? '';
    final role = authState.role ?? authState.backendToken?.role ?? 'CUSTOMER';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeaderCard(
              displayName: displayName,
              phoneNumber: phoneNumber,
              role: role,
              avatarUrl: avatarUrl,
              onEdit: () => _openProfileEditSheet(
                displayName: displayName,
                email: authState.email ?? '',
                avatarUrl: avatarUrl,
              ),
            ),
            const SizedBox(height: 14),
            walletAsync.when(
              data: (wallet) => _AccountSummaryCard(
                walletValue: wallet.balanceFormatted,
                emailValue: _displayEmail(authState.email),
                pinValue: authState.pinSet == true ? 'Configured' : 'Not set',
              ),
              loading: () => _AccountSummaryCard(
                walletValue: 'Loading...',
                emailValue: _displayEmail(authState.email),
                pinValue: authState.pinSet == true ? 'Configured' : 'Not set',
              ),
              error: (error, stack) => _AccountSummaryCard(
                walletValue: 'Unavailable',
                emailValue: _displayEmail(authState.email),
                pinValue: authState.pinSet == true ? 'Configured' : 'Not set',
              ),
            ),
            if (_serviceMessage != null) ...[
              const SizedBox(height: 12),
              _StatusBanner(
                message: _serviceMessage!,
                isError: _serviceMessageIsError,
              ),
            ],
            const SizedBox(height: 22),
            const Text(
              'Business accounts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a separate service role when this mobile number should work as a merchant or cash-out agent.',
              style: TextStyle(
                color: Color(0xFF607D8B),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _ServiceActionButtons(
              role: role,
              onCreateMerchant: () => _openMerchantSheet(
                displayName: displayName,
                localPhoneNumber: localPhoneNumber,
              ),
              onCreateAgent: () => _openAgentSheet(
                displayName: displayName,
                localPhoneNumber: localPhoneNumber,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProfileEditSheet({
    required String displayName,
    required String email,
    required String avatarUrl,
  }) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfileEditSheet(
        initialFullName: displayName,
        initialEmail: email,
        avatarUrl: avatarUrl,
      ),
    );

    if (message != null && mounted) {
      setState(() {
        _serviceMessage = message;
        _serviceMessageIsError = false;
      });
    }
  }

  Future<void> _openMerchantSheet({
    required String displayName,
    required String localPhoneNumber,
  }) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ServiceAccountSheet(
        title: 'Create Merchant',
        subtitle: 'This number will receive Merchant Payment.',
        icon: Icons.storefront,
        primaryColor: const Color(0xFF008F7A),
        path: '/api/merchants/me',
        successMessage:
            'Merchant account created. Use this number for Payment from another customer account.',
        fields: [
          _ServiceFieldConfig(
            keyName: 'businessName',
            label: 'Business name',
            initialValue: '$displayName Shop',
          ),
          _ServiceFieldConfig(
            keyName: 'merchantNumber',
            label: 'Merchant mobile number',
            initialValue: localPhoneNumber,
            keyboardType: TextInputType.phone,
            digitsOnly: true,
          ),
          const _ServiceFieldConfig(
            keyName: 'businessType',
            label: 'Business type',
            initialValue: 'Retail',
          ),
        ],
      ),
    );

    if (message != null && mounted) {
      setState(() {
        _serviceMessage = message;
        _serviceMessageIsError = false;
      });
    }
  }

  Future<void> _openAgentSheet({
    required String displayName,
    required String localPhoneNumber,
  }) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ServiceAccountSheet(
        title: 'Create Agent',
        subtitle: 'This number will receive Cash Out from customers.',
        icon: Icons.support_agent,
        primaryColor: const Color(0xFF008F7A),
        path: '/api/agents/me',
        successMessage:
            'Agent account created. Use this number for Cash Out from another customer account.',
        fields: [
          _ServiceFieldConfig(
            keyName: 'businessName',
            label: 'Agent point name',
            initialValue: '$displayName Agent Point',
          ),
          _ServiceFieldConfig(
            keyName: 'agentNumber',
            label: 'Agent mobile number',
            initialValue: localPhoneNumber,
            keyboardType: TextInputType.phone,
          ),
          const _ServiceFieldConfig(
            keyName: 'location',
            label: 'Location (optional)',
            initialValue: 'Local area',
            optional: true,
          ),
        ],
      ),
    );

    if (message != null && mounted) {
      setState(() {
        _serviceMessage = message;
        _serviceMessageIsError = false;
      });
    }
  }

  String _displayEmail(String? email) {
    return email?.trim().isNotEmpty == true ? email!.trim() : 'Not added';
  }

  String _toLocalMobileNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('8801') && digits.length == 13) {
      return '0${digits.substring(3)}';
    }
    if (digits.startsWith('1') && digits.length == 10) {
      return '0$digits';
    }
    return digits;
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.displayName,
    required this.phoneNumber,
    required this.role,
    required this.avatarUrl,
    required this.onEdit,
  });

  final String displayName;
  final String phoneNumber;
  final String role;
  final String avatarUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF008F7A),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24008F7A),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _ProfileAvatar(
            displayName: displayName,
            avatarUrl: avatarUrl,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phoneNumber,
                  style: const TextStyle(
                    color: Color(0xFFE0F2F1),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      color: Color(0xFF008F7A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: onEdit,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF008F7A),
            ),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.displayName,
    required this.avatarUrl,
    this.selectedImageBytes,
  });

  final String displayName;
  final String avatarUrl;
  final Uint8List? selectedImageBytes;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.trim().isEmpty
        ? 'S'
        : displayName.trim().substring(0, 1).toUpperCase();
    final imageProvider = selectedImageBytes != null
        ? MemoryImage(selectedImageBytes!)
        : avatarUrl.isEmpty
            ? null
            : NetworkImage(avatarUrl) as ImageProvider;

    return CircleAvatar(
      radius: 38,
      backgroundColor: const Color(0xFFE0F2F1),
      foregroundColor: const Color(0xFF008F7A),
      backgroundImage: imageProvider,
      onBackgroundImageError: imageProvider == null ? null : (_, __) {},
      child: imageProvider == null
          ? Text(
              initial,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
    );
  }
}

class _AccountSummaryCard extends StatelessWidget {
  const _AccountSummaryCard({
    required this.walletValue,
    required this.emailValue,
    required this.pinValue,
  });

  final String walletValue;
  final String emailValue;
  final String pinValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Column(
        children: [
          _AccountInfoTile(
            icon: Icons.account_balance_wallet,
            label: 'Wallet',
            value: walletValue,
          ),
          const Divider(height: 18),
          _AccountInfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: emailValue,
          ),
          const Divider(height: 18),
          _AccountInfoTile(
            icon: Icons.pin_outlined,
            label: 'PIN',
            value: pinValue,
          ),
        ],
      ),
    );
  }
}

class _ServiceActionButtons extends StatelessWidget {
  const _ServiceActionButtons({
    required this.role,
    required this.onCreateMerchant,
    required this.onCreateAgent,
  });

  final String role;
  final VoidCallback onCreateMerchant;
  final VoidCallback onCreateAgent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButtonCard(
            title: 'Create Merchant',
            subtitle: role == 'MERCHANT'
                ? 'Already merchant'
                : role == 'AGENT'
                    ? 'Use another number'
                    : 'Receive payments',
            icon: Icons.storefront,
            enabled: role == 'CUSTOMER',
            onTap: onCreateMerchant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButtonCard(
            title: 'Create Agent',
            subtitle: role == 'AGENT'
                ? 'Already agent'
                : role == 'MERCHANT'
                    ? 'Use another number'
                    : 'Cash Out point',
            icon: Icons.support_agent,
            enabled: role == 'CUSTOMER',
            onTap: onCreateAgent,
          ),
        ),
      ],
    );
  }
}

class _ActionButtonCard extends StatelessWidget {
  const _ActionButtonCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled ? const Color(0xFFB2DFDB) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color:
                  enabled ? const Color(0xFF008F7A) : const Color(0xFF90A4AE),
              size: 30,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color:
                    enabled ? const Color(0xFF263238) : const Color(0xFF78909C),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF607D8B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileEditSheet extends ConsumerStatefulWidget {
  const _ProfileEditSheet({
    required this.initialFullName,
    required this.initialEmail,
    required this.avatarUrl,
  });

  final String initialFullName;
  final String initialEmail;
  final String avatarUrl;

  @override
  ConsumerState<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<_ProfileEditSheet> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  final _imagePicker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.initialFullName);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 85,
    );

    if (pickedImage == null) {
      return;
    }

    final bytes = await pickedImage.readAsBytes();
    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageName = pickedImage.name;
    });
  }

  Future<void> _saveProfile() async {
    if (_fullNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Full name is required.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).completeProfile(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            avatarImageBytes: _selectedImageBytes,
            avatarFileName: _selectedImageName,
          );
      final nextState = ref.read(authControllerProvider);
      if (nextState.errorMessage != null) {
        setState(() {
          _errorMessage = nextState.errorMessage;
        });
        return;
      }
      if (mounted) {
        Navigator.of(context).pop('Profile updated successfully.');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return _BottomSheetShell(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 14),
            const Text(
              'Edit account information',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: _ProfileAvatar(
                displayName: _fullNameController.text,
                avatarUrl: widget.avatarUrl,
                selectedImageBytes: _selectedImageBytes,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: _loading ? null : _pickProfileImage,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(
                  _selectedImageName == null
                      ? 'Change profile image'
                      : 'Image selected',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ServiceTextField(
              controller: _fullNameController,
              label: 'Full name',
              textInputAction: TextInputAction.next,
            ),
            _ServiceTextField(
              controller: _emailController,
              label: 'Email (optional)',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 4),
              _StatusBanner(message: _errorMessage!, isError: true),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _saveProfile,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceAccountSheet extends ConsumerStatefulWidget {
  const _ServiceAccountSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.path,
    required this.successMessage,
    required this.fields,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final String path;
  final String successMessage;
  final List<_ServiceFieldConfig> fields;

  @override
  ConsumerState<_ServiceAccountSheet> createState() =>
      _ServiceAccountSheetState();
}

class _ServiceAccountSheetState extends ConsumerState<_ServiceAccountSheet> {
  late final Map<String, TextEditingController> _controllers;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.fields)
        field.keyName: TextEditingController(text: field.initialValue),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final data = <String, dynamic>{};
    for (final field in widget.fields) {
      final value = _controllers[field.keyName]!.text.trim();
      if (!field.optional && value.isEmpty) {
        setState(() {
          _errorMessage = '${field.label} is required.';
        });
        return;
      }
      if (value.isEmpty) {
        continue;
      }
      data[field.keyName] =
          field.digitsOnly ? value.replaceAll(RegExp(r'[^0-9]'), '') : value;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(apiClientProvider).post<Map<String, dynamic>>(
            widget.path,
            data: data,
          );
      await ref.read(authControllerProvider.notifier).refreshCurrentUser();
      if (mounted) {
        Navigator.of(context).pop(widget.successMessage);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyError(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _friendlyError(Object error) {
    if (error is ApiException) {
      if (error.errors.isNotEmpty) {
        return error.errors.first;
      }
      return error.message;
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return _BottomSheetShell(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF607D8B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            for (final field in widget.fields)
              _ServiceTextField(
                controller: _controllers[field.keyName]!,
                label: field.label,
                keyboardType: field.keyboardType,
                textInputAction: field == widget.fields.last
                    ? TextInputAction.done
                    : TextInputAction.next,
              ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 4),
              _StatusBanner(message: _errorMessage!, isError: true),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                label: Text(widget.title),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetShell extends StatelessWidget {
  const _BottomSheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SingleChildScrollView(child: child),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E7EC),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ServiceFieldConfig {
  const _ServiceFieldConfig({
    required this.keyName,
    required this.label,
    required this.initialValue,
    this.keyboardType,
    this.optional = false,
    this.digitsOnly = false,
  });

  final String keyName;
  final String label;
  final String initialValue;
  final TextInputType? keyboardType;
  final bool optional;
  final bool digitsOnly;
}

class _ServiceTextField extends StatelessWidget {
  const _ServiceTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFEBEE) : const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? const Color(0xFFB71C1C) : const Color(0xFF00695C),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AccountInfoTile extends StatelessWidget {
  const _AccountInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF008F7A)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF607D8B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Color(0xFF263238),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
