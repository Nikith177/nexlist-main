import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_input_decoration.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import 'firestore_trace_utils.dart';
import 'navigation_trace_utils.dart';
import 'seller_identity_utils.dart';

class IdentityProfile {
  final String name;
  final String phone;

  const IdentityProfile({required this.name, required this.phone});
}

class PhoneGateUtils {
  static final Set<String> _claimPromptHandledUsers = <String>{};

  @Deprecated('Use ensureIdentity instead.')
  static Future<String?> ensurePhoneNumber(
    BuildContext context, {
    bool interactive = true,
  }) async {
    final identity = await ensureIdentity(context, interactive: interactive);
    return identity?.phone;
  }

  static Future<bool> ensureUserReadyForAction(
    BuildContext context, {
    bool promptClaim = true,
  }) async {
    final identity = await ensureIdentity(context, interactive: true);
    if (identity == null) {
      return false;
    }

    if (promptClaim) {
      await checkAndPromptClaim(context, identity: identity);
    }

    return true;
  }

  static Future<void> checkAndPromptClaim(
    BuildContext context, {
    IdentityProfile? identity,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _claimPromptHandledUsers.contains(user.uid)) {
      return;
    }

    final resolvedIdentity =
        identity ?? await ensureIdentity(context, interactive: false);
    if (resolvedIdentity == null) {
      return;
    }

    final phone = normalizePhone(resolvedIdentity.phone);
    if (phone == null || phone.isEmpty) {
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('listings')
          .where('contactPhone', isEqualTo: phone)
          .tracedGet('listings by contactPhone=$phone claim prompt');

      final claimable = query.docs.where((doc) {
        final data = doc.data();
        return SellerIdentityUtils.resolveSellerId(data) != user.uid;
      }).toList();

      if (claimable.isEmpty) {
        _claimPromptHandledUsers.add(user.uid);
        return;
      }

      if (!context.mounted) {
        return;
      }

      _claimPromptHandledUsers.add(user.uid);
      final shouldClaim = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Claim your listings'),
          content: Text(
            'You have ${claimable.length} listings posted using your number.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Claim'),
            ),
          ],
        ),
      );

      if (shouldClaim != true) {
        return;
      }

      await claimListings(user.uid, claimable, userName: resolvedIdentity.name);
      if (!context.mounted) {
        return;
      }
      _showSnackBar(context, 'Listings claimed successfully');
    } catch (e) {
      _claimPromptHandledUsers.remove(user.uid);
      if (!context.mounted) {
        return;
      }
      _showSnackBar(context, 'Failed to check claimable listings');
    }
  }

  static Future<void> claimListings(
    String uid,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required String userName,
  }) async {
    if (docs.isEmpty) {
      return;
    }

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in docs) {
      final data = doc.data();
      final updates = <String, dynamic>{
        'sellerId': uid,
        'user_name': userName,
        'contactPhone': FieldValue.delete(),
        'contactName': FieldValue.delete(),
        'seller_id': FieldValue.delete(),
        'isProxy': false,
      };

      if (data.containsKey('created_by_name')) {
        updates['created_by_name'] = userName;
      }

      batch.update(doc.reference, updates);
    }

    await batch.commit();
  }

  static Future<IdentityProfile?> ensureIdentity(
    BuildContext context, {
    bool interactive = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        context.tracedPush('/login');
      }
      return null;
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    while (context.mounted) {
      String? existingName;
      String? existingPhone;

      try {
        final doc = await docRef.tracedGet('users/${user.uid} ensureIdentity');
        existingName = normalizeName(doc.data()?['name']);
        existingPhone = normalizePhone(doc.data()?['phone']);
      } catch (e) {
        existingName = normalizeName(user.displayName);
        existingPhone = null;
        if (!interactive) {
          return null;
        }
        if (!context.mounted) {
          return null;
        }
        _showSnackBar(context, 'Failed to load profile: $e');
      }

      if (existingName != null && existingPhone != null) {
        return IdentityProfile(name: existingName, phone: existingPhone);
      }

      if (!interactive || !context.mounted) {
        return null;
      }

      final result = await showModalBottomSheet<IdentityProfile>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => _PhoneGateSheet(
          docRef: docRef,
          initialName: existingName ?? normalizeName(user.displayName) ?? '',
          initialPhone: existingPhone ?? '',
        ),
      );

      if (result != null) {
        return result;
      }
    }

    return null;
  }

  static String? normalizeName(dynamic rawName) {
    final text = rawName?.toString();
    if (text == null) {
      return null;
    }

    final name = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (name.isEmpty) {
      return null;
    }

    return name;
  }

  static String? normalizePhone(dynamic rawPhone) {
    final text = rawPhone?.toString();
    if (text == null) {
      return null;
    }

    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return null;
    }

    final phone = digits.substring(digits.length - 10);
    if (phone.length != 10) {
      return null;
    }

    return phone;
  }

  static String? normalizePhoneForWhatsApp(dynamic rawPhone) {
    final phone = normalizePhone(rawPhone);
    if (phone == null) {
      return null;
    }

    return '91$phone';
  }

  static void _showSnackBar(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PhoneGateSheet extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> docRef;
  final String initialName;
  final String initialPhone;

  const _PhoneGateSheet({
    required this.docRef,
    required this.initialName,
    required this.initialPhone,
  });

  @override
  State<_PhoneGateSheet> createState() => _PhoneGateSheetState();
}

class _PhoneGateSheetState extends State<_PhoneGateSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController.text = widget.initialPhone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _savePhone() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate() || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final name = PhoneGateUtils.normalizeName(_nameController.text);
    final phone = PhoneGateUtils.normalizePhone(_phoneController.text);
    if (name == null || phone == null) {
      setState(() {
        _isSaving = false;
      });
      return;
    }

    try {
      await widget.docRef.set({
        'name': name,
        'phone': phone,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pop(IdentityProfile(name: name, phone: phone));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save phone: $e')));
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Material(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Complete your profile to continue',
                      style: AppTypography.h3,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your name and WhatsApp number before entering Nexlist.',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      autofocus: widget.initialName.isEmpty,
                      decoration: buildInputDecoration(
                        'Your full name',
                        fillColor: AppColors.background,
                        focusColor: AppColors.primary,
                      ),
                      validator: (value) {
                        if (PhoneGateUtils.normalizeName(value) == null) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autofocus: widget.initialName.isNotEmpty,
                      decoration: buildInputDecoration(
                        'e.g. 9876543210',
                        fillColor: AppColors.background,
                        focusColor: AppColors.primary,
                        prefixText: '+91 ',
                      ),
                      validator: (value) {
                        if (PhoneGateUtils.normalizePhone(value) == null) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePhone,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Continue',
                                style: AppTypography.buttonText.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
