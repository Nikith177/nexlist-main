import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/campus_constants.dart';
import '../../../core/theme/app_input_decoration.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/utils/firestore_trace_utils.dart';
import '../../../shared/utils/phone_gate_utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  String? _email;
  String? _campusId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _email = user.email;
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .tracedGet('users/${user.uid} edit profile preload');
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _nameController.text =
              PhoneGateUtils.normalizeName(data['name']) ??
              user.displayName ??
              '';
          _phoneController.text =
              PhoneGateUtils.normalizePhone(data['phone']) ?? '';
          _campusId = data['campus_id'] as String?;
        } else {
          _nameController.text =
              PhoneGateUtils.normalizeName(user.displayName) ?? '';
        }
      }
    } catch (e) {
      // Leave the form on safe defaults if profile preload fails.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final name = PhoneGateUtils.normalizeName(_nameController.text);
        final phone = PhoneGateUtils.normalizePhone(_phoneController.text);
        if (name == null || phone == null) {
          return;
        }
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'phone': phone,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          context.pop(true); // Return true to signal a refresh
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          automaticallyImplyLeading: true,
          centerTitle: false,
          titleSpacing: 0,
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          title: Row(
            children: [
              const SizedBox(width: 8),
              Text(
                'Edit Profile',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: true,
        centerTitle: false,
        titleSpacing: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        title: Row(
          children: [
            const SizedBox(width: 8),
            Text(
              'Edit Profile',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 800;
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 800 : double.infinity,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email (Read Only)
                      const Text('Email', style: AppTypography.bodySmall),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _email ?? '',
                        readOnly: true,
                        style: const TextStyle(color: AppColors.textSecondary),
                        decoration: buildInputDecoration(
                          '',
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          focusColor: Theme.of(context).colorScheme.primary,
                          prefixIcon: Icon(
                            Icons.email,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Email cannot be changed.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name (Editable)
                      const Text('Name', style: AppTypography.bodySmall),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: buildInputDecoration(
                          '',
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          focusColor: Theme.of(context).colorScheme.primary,
                          prefixIcon: Icon(
                            Icons.person,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Phone (Editable)
                      const Text(
                        'Phone Number',
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: buildInputDecoration(
                          '',
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          focusColor: Theme.of(context).colorScheme.primary,
                          prefixIcon: Icon(
                            Icons.phone,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.replaceAll(RegExp(r'[^0-9]'), '').length <
                              10) {
                            return 'Please enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Campus (Read Only)
                      const Text('Campus', style: AppTypography.bodySmall),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: getCampusName(_campusId),
                        readOnly: true,
                        style: const TextStyle(color: AppColors.textSecondary),
                        decoration: buildInputDecoration(
                          '',
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          focusColor: Theme.of(context).colorScheme.primary,
                          prefixIcon: Icon(
                            Icons.school,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Campus selection can be changed from Account Settings.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSaving ? null : _saveProfile,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
