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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          onChanged: (value) {
            widget.onChanged?.call(value);
            if (_selectedContact != null && value != _selectedContact!.number) {
              setState(() => _selectedContact = null);
            }
          },
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        if (_selectedContact != null) ...[
          const SizedBox(height: 10),
          _SelectedContactPreview(selection: _selectedContact!),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openContactPicker,
                icon: const Icon(Icons.contacts_outlined),
                label: Text(widget.contactButtonLabel),
              ),
            ),
            if (widget.onQrPressed != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onQrPressed,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(widget.qrButtonLabel),
                ),
              ),
            ],
          ],
        ),
      ],
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
      final allowed = await FlutterContacts.requestPermission(readonly: true);
      if (!allowed) {
        setState(() {
          _loading = false;
          _errorMessage =
              'Contact permission denied. Allow Contacts permission or type the number manually.';
        });
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
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
              name: contact.displayName.isEmpty
                  ? normalized
                  : contact.displayName,
              number: normalized,
              photo: contact.photoOrThumbnail,
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

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.78,
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
                    'Select from contacts',
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
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search name or number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                          : ListView.separated(
                              itemCount: contacts.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final contact = contacts[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: _ContactAvatar(contact: contact),
                                  title: Text(
                                    contact.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  subtitle: Text(contact.number),
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 16),
                                  onTap: () =>
                                      Navigator.of(context).pop(contact),
                                );
                              },
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

    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return '';
    }
    return hasPlus ? '+$digits' : digits;
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
