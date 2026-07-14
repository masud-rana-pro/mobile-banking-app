import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactNumberInput extends StatefulWidget {
  const ContactNumberInput({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.contactButtonLabel,
    required this.qrButtonLabel,
    this.onChanged,
    this.onQrPressed,
    this.onProceed,
    this.proceedButtonLabel = 'Proceed',
    this.loading = false,
    this.keyboardType = TextInputType.phone,
    super.key,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final String contactButtonLabel;
  final String qrButtonLabel;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onQrPressed;
  final VoidCallback? onProceed;
  final String proceedButtonLabel;
  final bool loading;
  final TextInputType keyboardType;

  @override
  State<ContactNumberInput> createState() => _ContactNumberInputState();
}

class _ContactNumberInputState extends State<ContactNumberInput> {
  ContactNumberSelection? _selectedContact;

  Future<void> _openContactPicker() async {
    final selected = await showModalBottomSheet<ContactNumberSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ContactPickerSheet(),
    );

    if (selected == null || !mounted) {
      return;
    }

    widget.controller.text = selected.number;
    widget.onChanged?.call(selected.number);
    setState(() => _selectedContact = selected);
  }

  void _appendDigit(String value) {
    if (widget.loading) {
      return;
    }
    widget.controller.text = '${widget.controller.text}$value';
    widget.onChanged?.call(widget.controller.text);
    if (_selectedContact != null &&
        widget.controller.text != _selectedContact!.number) {
      _selectedContact = null;
    }
    setState(() {});
  }

  void _backspace() {
    if (widget.loading || widget.controller.text.isEmpty) {
      return;
    }
    widget.controller.text = widget.controller.text.substring(
      0,
      widget.controller.text.length - 1,
    );
    widget.onChanged?.call(widget.controller.text);
    if (_selectedContact != null &&
        widget.controller.text != _selectedContact!.number) {
      _selectedContact = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canProceed = widget.onProceed != null &&
        widget.controller.text.trim().isNotEmpty &&
        !widget.loading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE7EA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.search, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  readOnly: true,
                  showCursor: true,
                  enableInteractiveSelection: false,
                  keyboardType: TextInputType.none,
                  onTap: FocusScope.of(context).unfocus,
                  onChanged: (value) {
                    widget.onChanged?.call(value);
                    if (_selectedContact != null &&
                        value != _selectedContact!.number) {
                      setState(() => _selectedContact = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: widget.labelText,
                    hintText: widget.hintText,
                    border: InputBorder.none,
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  style: const TextStyle(
                    color: Color(0xFF263238),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (widget.onQrPressed != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: widget.qrButtonLabel,
                  onPressed: widget.onQrPressed,
                  icon: Icon(
                    Icons.qr_code_scanner,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        if (_selectedContact != null) ...[
          const SizedBox(height: 10),
          _SelectedContactPreview(selection: _selectedContact!),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _openContactPicker,
          icon: const Icon(Icons.contacts_outlined),
          label: Text(widget.contactButtonLabel),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(color: theme.colorScheme.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (widget.onProceed != null) ...[
          const SizedBox(height: 12),
          _NumberProceedKeypad(
            label: widget.proceedButtonLabel,
            loading: widget.loading,
            canProceed: canProceed,
            onProceed: widget.onProceed,
            onNumberTap: _appendDigit,
            onBackspace: _backspace,
          ),
        ],
      ],
    );
  }
}

class _NumberProceedKeypad extends StatelessWidget {
  const _NumberProceedKeypad({
    required this.label,
    required this.loading,
    required this.canProceed,
    required this.onProceed,
    required this.onNumberTap,
    required this.onBackspace,
  });

  final String label;
  final bool loading;
  final bool canProceed;
  final VoidCallback? onProceed;
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: canProceed ? onProceed : null,
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
                          Text(
                            label,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Column(
                children: [
                  for (final row in rows)
                    Row(
                      children: [
                        for (final value in row)
                          Expanded(
                            child: _NumberKeypadButton(
                              label: value,
                              onTap: () => onNumberTap(value),
                            ),
                          ),
                      ],
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _NumberKeypadIconButton(
                          icon: Icons.close,
                          onTap: onBackspace,
                        ),
                      ),
                      Expanded(
                        child: _NumberKeypadButton(
                          label: '0',
                          onTap: () => onNumberTap('0'),
                        ),
                      ),
                      Expanded(
                        child: _NumberKeypadIconButton(
                          icon: Icons.keyboard_return,
                          onTap: canProceed ? (onProceed ?? () {}) : () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberKeypadButton extends StatelessWidget {
  const _NumberKeypadButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(48),
      child: SizedBox(
        height: 56,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF455A64),
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberKeypadIconButton extends StatelessWidget {
  const _NumberKeypadIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(48),
      child: SizedBox(
        height: 56,
        child: Center(
          child: Container(
            width: 44,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF455A64),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class ContactNumberSelection {
  const ContactNumberSelection({
    required this.name,
    required this.number,
    this.photo,
  });

  final String name;
  final String number;
  final Uint8List? photo;
}

class _ContactPickerSheet extends StatefulWidget {
  const _ContactPickerSheet();

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  final _searchController = TextEditingController();
  List<ContactNumberSelection> _contacts = const [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final permission = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
      final allowed = permission == PermissionStatus.granted ||
          permission == PermissionStatus.limited;
      if (!allowed) {
        setState(() {
          _loading = false;
          _errorMessage =
              'Contact permission denied. Allow Contacts permission or type the number manually.';
        });
        return;
      }

      final contacts = await FlutterContacts.getAll(
        properties: {
          ContactProperty.phone,
          ContactProperty.photoThumbnail,
        },
      );
      final selections = <ContactNumberSelection>[];
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalized = _normalizePhone(phone.number);
          if (normalized.isEmpty) {
            continue;
          }
          selections.add(
            ContactNumberSelection(
              name: (contact.displayName ?? '').isEmpty
                  ? normalized
                  : contact.displayName!,
              number: normalized,
              photo: contact.photo?.thumbnail,
            ),
          );
        }
      }
      selections.sort(
        (left, right) =>
            left.name.toLowerCase().compareTo(right.name.toLowerCase()),
      );
      setState(() {
        _contacts = selections;
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _loading = false;
        _errorMessage = 'Could not load contacts: $error';
      });
    }
  }

  List<ContactNumberSelection> get _filteredContacts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _contacts;
    }
    return _contacts.where((contact) {
      return contact.name.toLowerCase().contains(query) ||
          contact.number.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final contacts = _filteredContacts;
    final recentContacts = _contacts.take(3).toList();
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 14, 18, bottomInset + 18),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7EC),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select contact',
                    style: TextStyle(
                      color: Color(0xFF263238),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _loadContacts,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDE7EA)),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon:
                      Icon(Icons.search, color: theme.colorScheme.primary),
                  hintText: 'Enter name or number',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _ContactPickerMessage(
                          icon: Icons.lock_outline,
                          message: _errorMessage!,
                        )
                      : contacts.isEmpty
                          ? const _ContactPickerMessage(
                              icon: Icons.search_off,
                              message: 'No matching contacts found.',
                            )
                          : ListView(
                              children: [
                                if (_searchController.text.trim().isEmpty &&
                                    recentContacts.isNotEmpty) ...[
                                  const _ContactSectionTitle('Recent'),
                                  for (final contact in recentContacts)
                                    _ContactPickerTile(
                                      contact: contact,
                                      starred: true,
                                      onTap: () =>
                                          Navigator.of(context).pop(contact),
                                    ),
                                  const SizedBox(height: 16),
                                  const Divider(height: 1),
                                  const SizedBox(height: 16),
                                ],
                                const _ContactSectionTitle('All contacts'),
                                for (final contact in contacts)
                                  _ContactPickerTile(
                                    contact: contact,
                                    onTap: () =>
                                        Navigator.of(context).pop(contact),
                                  ),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizePhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return '';
    }

    if (digits.startsWith('8801') && digits.length == 13) {
      return '0${digits.substring(3)}';
    }

    if (digits.startsWith('01') && digits.length == 11) {
      return digits;
    }

    if (digits.startsWith('1') && digits.length == 10) {
      return '0$digits';
    }

    return digits;
  }
}

class _ContactSectionTitle extends StatelessWidget {
  const _ContactSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF607D8B),
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ContactPickerTile extends StatelessWidget {
  const _ContactPickerTile({
    required this.contact,
    required this.onTap,
    this.starred = false,
  });

  final ContactNumberSelection contact;
  final VoidCallback onTap;
  final bool starred;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          _ContactAvatar(contact: contact, radius: 27),
          if (starred)
            const Positioned(
              right: -2,
              top: -2,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Color(0xFF008F7A),
                child: Icon(Icons.star, color: Colors.white, size: 13),
              ),
            ),
        ],
      ),
      title: Text(
        contact.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF263238),
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          contact.number,
          style: const TextStyle(
            color: Color(0xFF607D8B),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF90A4AE)),
      onTap: onTap,
    );
  }
}

class _SelectedContactPreview extends StatelessWidget {
  const _SelectedContactPreview({required this.selection});

  final ContactNumberSelection selection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ContactAvatar(contact: selection, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selection.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF263238),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  selection.number,
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
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({
    required this.contact,
    this.radius = 22,
  });

  final ContactNumberSelection contact;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE0F2F1),
      foregroundColor: const Color(0xFF008F7A),
      backgroundImage:
          contact.photo == null ? null : MemoryImage(contact.photo!),
      child: contact.photo == null
          ? Text(
              contact.name.isEmpty
                  ? '?'
                  : contact.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900),
            )
          : null,
    );
  }
}

class _ContactPickerMessage extends StatelessWidget {
  const _ContactPickerMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: const Color(0xFFB42318)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF607D8B),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
