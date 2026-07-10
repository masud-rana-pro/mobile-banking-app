import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/providers/auth_providers.dart';
import '../../home/presentation/home_screen.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  static const routeName = 'profile-completion';
  static const routePath = '/profile-completion';

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _imagePicker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authControllerProvider);
    _fullNameController.text = authState.fullName ?? '';
    _emailController.text = authState.email ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    await ref.read(authControllerProvider.notifier).completeProfile(
          fullName: _fullNameController.text,
          email: _emailController.text,
          avatarImageBytes: _selectedImageBytes,
          avatarFileName: _selectedImageName,
        );
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.profileComplete == true && !next.needsPinSetup) {
        context.goNamed(HomeScreen.routeName);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: _ProfileAvatarPreview(
                selectedImageBytes: _selectedImageBytes,
                avatarUrl: authState.avatarUrl,
                fallbackText: _fullNameController.text,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton.icon(
                onPressed: authState.isLoading ? null : _pickProfileImage,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(
                  _selectedImageName == null
                      ? 'Choose Profile Image'
                      : 'Change Profile Image',
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Register your SmartKash profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your name and optional profile image. The backend will save the image and keep a unique image reference in PostgreSQL.',
              style: TextStyle(color: Color(0xFF607D8B), height: 1.4),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _fullNameController,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Md. Masud Rana',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                hintText: 'you@example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            if (authState.errorMessage != null)
              _ProfileMessage(
                message: authState.errorMessage!,
                isError: true,
              ),
            if (authState.infoMessage != null)
              _ProfileMessage(
                message: authState.infoMessage!,
                isError: false,
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008F7A),
                  foregroundColor: Colors.white,
                ),
                child: authState.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Save & Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
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

class _ProfileAvatarPreview extends StatelessWidget {
  const _ProfileAvatarPreview({
    required this.selectedImageBytes,
    required this.avatarUrl,
    required this.fallbackText,
  });

  final Uint8List? selectedImageBytes;
  final String? avatarUrl;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    final initial = fallbackText.trim().isEmpty
        ? 'S'
        : fallbackText.trim().substring(0, 1).toUpperCase();

    final existingAvatarUrl = avatarUrl?.trim() ?? '';
    final imageProvider = selectedImageBytes != null
        ? MemoryImage(selectedImageBytes!)
        : existingAvatarUrl.isEmpty
            ? null
            : NetworkImage(existingAvatarUrl) as ImageProvider;

    return CircleAvatar(
      radius: 56,
      backgroundColor: const Color(0xFFE0F2F1),
      foregroundColor: const Color(0xFF008F7A),
      backgroundImage: imageProvider,
      onBackgroundImageError: imageProvider == null ? null : (_, __) {},
      child: imageProvider == null
          ? Text(
              initial,
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({
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
      margin: const EdgeInsets.only(bottom: 10),
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
