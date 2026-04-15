import 'dart:io';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/app_input_decoration.dart';
import '../../../core/theme/typography.dart';
import '../../../core/constants/campus_hostels.dart';
import '../../../config/listing_categories.dart';
import '../../../config/marketplace_config.dart';
import '../../../shared/utils/listing_category_utils.dart';
import '../../../shared/utils/listing_condition_utils.dart';
import '../../../shared/utils/phone_gate_utils.dart';
import '../../../shared/utils/firestore_trace_utils.dart';
import '../../../shared/utils/navigation_trace_utils.dart';

class PostListingScreen extends StatefulWidget {
  final String? initialType;

  const PostListingScreen({super.key, this.initialType});

  @override
  State<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends State<PostListingScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationDetailController =
      TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  String? _selectedType;
  String _selectedCategory = ListingCategories.getSellCategories().first;
  String? _selectedCondition;
  String _selectedRentalPriceUnit = 'day';
  String _selectedServicePricingType = 'fixed';
  String _locationType = 'hostel';
  String? _selectedHostel;
  String? _campusId;
  bool _isUrgent = false;
  bool _allowNegotiation = true;
  bool _isLoading = false;
  bool _showPostingSuccess = false;
  bool _isAdmin = false;
  bool _isFree = false;
  bool _isPosting = false;
  String _postingStatusText = 'Posting...';

  static const Set<String> _allowedTypes = {
    'sell',
    'rent',
    'service',
    'request',
  };

  XFile? _selectedImage;
  Uint8List? _selectedImagePreviewBytes;
  final ImagePicker _picker = ImagePicker();

  bool get _isPostingOverlayVisible => _isLoading || _showPostingSuccess;
  List<String> get _availableHostels => campusHostels[_campusId] ?? const [];
  ThemeData get _theme => Theme.of(context);
  Color get _scaffoldBackgroundColor => _theme.scaffoldBackgroundColor;
  Color get _surfaceColor => _theme.colorScheme.surface;
  Color get _onSurfaceColor => _theme.colorScheme.onSurface;
  Color get _onSurfaceMuted => _onSurfaceColor.withValues(alpha: 0.72);
  Color get _onSurfaceHint => _onSurfaceColor.withValues(alpha: 0.58);
  Color get _dividerColor => _theme.dividerColor;

  @override
  void initState() {
    super.initState();
    _loadCampusId();
    _applyInitialType();
  }

  void _applyInitialType() {
    final normalized = _normalizeType(widget.initialType);
    if (normalized == null) return;
    _setSelectedType(normalized, notify: false);
  }

  String? _normalizeType(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    return _allowedTypes.contains(normalized) ? normalized : null;
  }

  void _setSelectedType(String typeValue, {bool notify = true}) {
    void apply() {
      _selectedType = typeValue;
      _selectedCategory = _defaultCategoryForType(typeValue);
      _selectedCondition = null;
      _isFree = false;
      _titleController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _contactNameController.clear();
      _contactPhoneController.clear();
      _selectedImage = null;
      _selectedImagePreviewBytes = null;
      _isUrgent = false;
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
  }

  void _clearSelectedTypeSelection() {
    setState(() {
      _selectedType = null;
      _isFree = false;
      _priceController.clear();
    });
  }

  void _setFreeSale(bool value) {
    setState(() {
      _isFree = value;
      if (value) {
        _allowNegotiation = false;
      }
      _priceController.text = value ? '0' : '';
    });
  }

  String _defaultCategoryForType(String? type) {
    if (type == null) {
      return ListingCategories.defaultCategoryForType('sell');
    }
    return ListingCategories.defaultCategoryForType(type);
  }

  bool _typeUsesCategories(String? type) {
    if (type == null) {
      return false;
    }
    return ListingCategories.typeUsesCategories(type);
  }

  bool _typeUsesCondition(String? type) {
    return type == 'sell' || type == 'rent';
  }

  String _routeForPostedType() {
    switch (_selectedType) {
      case 'service':
        return '/services';
      case 'request':
        return '/requests';
      case 'sell':
      case 'rent':
      default:
        return '/home';
    }
  }

  SnackBar _buildFailureSnackBar(BuildContext context, String message) {
    final bottomInset = MediaQuery.of(context).padding.bottom + 24;

    return SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomInset),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
      content: Text(message),
    );
  }

  void _showFailureSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(_buildFailureSnackBar(context, message));
  }

  String _formatImageUploadError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
        case 'unauthorized':
          return 'Image upload was rejected. Please sign in again and try again.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'Network is unavailable while uploading the image. Please try again.';
        default:
          final message = error.message?.trim();
          if (message != null && message.isNotEmpty) {
            return 'Image upload failed: $message';
          }
          return 'Image upload failed: ${error.code}';
      }
    }

    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }

    return 'Image upload failed. Please try again.';
  }

  String _formatPostError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Post was rejected. Please sign in again and verify all required fields.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'Network is unavailable while posting. Please try again.';
        default:
          final message = error.message?.trim();
          if (message != null && message.isNotEmpty) {
            return 'Post failed: $message';
          }
          return 'Post failed: ${error.code}';
      }
    }

    return 'Post failed. Please try again.';
  }

  String _imageExtensionFromPath(String path) {
    final normalized = path.trim().toLowerCase();
    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == normalized.length - 1) {
      return 'jpg';
    }

    final extension = normalized.substring(dotIndex + 1);
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'heic':
      case 'heif':
        return extension;
      default:
        return 'jpg';
    }
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _loadCampusId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .tracedGet('users/${user.uid} post listing campus preload');

      if (!mounted) return;

      final campusId = (userDoc.data()?['campus_id'] as String?)?.trim();
      final isAdmin = userDoc.data()?['isAdmin'] == true;
      final hostels = campusHostels[campusId] ?? const <String>[];

      setState(() {
        _campusId = campusId;
        _isAdmin = isAdmin;
        if (_locationType == 'hostel') {
          _selectedHostel = hostels.isEmpty ? null : hostels.first;
        }
      });
    } catch (e, stack) {
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stack');
      // Keep the form usable; submit-time validation still checks campus data.
    }
  }

  Map<String, dynamic> _buildLocationPayload() {
    final locationDetail = _locationDetailController.text.trim();

    switch (_locationType) {
      case 'hostel':
        return {
          'location_type': 'hostel',
          if (_selectedHostel?.trim().isNotEmpty ?? false)
            'location_tag': _selectedHostel!.trim(),
          if (locationDetail.isNotEmpty) 'location_detail': locationDetail,
        };
      case 'campus':
        return {
          'location_type': 'campus',
          if (locationDetail.isNotEmpty) 'location_detail': locationDetail,
        };
      case 'anywhere':
        return {'location_type': 'anywhere'};
      case 'online':
        return {'location_type': 'online'};
      default:
        return {'location_type': 'anywhere'};
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationDetailController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 1280,
      );
      if (image != null) {
        final previewBytes = kIsWeb ? await image.readAsBytes() : null;
        if (!mounted) return;
        setState(() {
          _selectedImage = image;
          _selectedImagePreviewBytes = previewBytes;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $error')));
      }
    }
  }

  Future<String> uploadImage(XFile image, String userId) async {
    const maxFileSizeBytes = 5 * 1024 * 1024;
    final extensionSource = kIsWeb ? image.name : image.path;
    final extension = _imageExtensionFromPath(extensionSource);
    final contentType = _contentTypeForExtension(extension);
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final imageRef = FirebaseStorage.instance.ref().child(
      'listings/$userId/$timestamp.$extension',
    );

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Selected image is empty');
      }
      if (bytes.lengthInBytes > maxFileSizeBytes) {
        throw Exception(
          'Image is still larger than 5MB after optimization. Please choose a smaller image.',
        );
      }

      try {
        await imageRef.putData(
          bytes,
          SettableMetadata(contentType: contentType),
        );
        final downloadUrl = await imageRef.getDownloadURL();
        return downloadUrl;
      } catch (e, stack) {
        debugPrint('ERROR: $e');
        debugPrint('STACK: $stack');
        rethrow;
      }
    }

    final file = File(image.path);
    final exists = await file.exists();
    if (!exists) {
      throw Exception('Selected image file was not found');
    }

    final fileSize = await file.length();
    if (fileSize > maxFileSizeBytes) {
      throw Exception(
        'Image is still larger than 5MB after optimization. Please choose a smaller image.',
      );
    }

    try {
      await imageRef.putFile(file, SettableMetadata(contentType: contentType));
      final downloadUrl = await imageRef.getDownloadURL();
      return downloadUrl;
    } catch (e, stack) {
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stack');
      rethrow;
    }
  }

  Future<void> _createListing() async {
    if (kIsWeb) {
      final isOnline = html.window.navigator.onLine ?? true;
      if (!isOnline) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No internet connection')),
          );
        }
        return;
      }
    }

    if (_isPostingOverlayVisible || _isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Please login to post')));
        }
        return;
      }

      final sellerId = user.uid.trim();
      if (sellerId.isEmpty) {
        _showFailureSnackBar(
          'Unable to determine your account. Please sign in again.',
        );
        return;
      }

      if (_selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a listing type')),
        );
        return;
      }

      final priceText = _priceController.text.trim();
      final parsedPrice = priceText.isEmpty ? null : double.tryParse(priceText);
      final isFreeSale = _selectedType == 'sell' && _isFree;
      final resolvedPrice = isFreeSale ? 0.0 : parsedPrice;
      final allowNegotiation =
          (_selectedType == 'sell' || _selectedType == 'rent') &&
              resolvedPrice != 0
          ? _allowNegotiation
          : false;

      if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
        return;
      }

      if (((_selectedType == 'sell' && !isFreeSale) ||
              _selectedType == 'rent') &&
          (parsedPrice == null || parsedPrice <= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid price greater than 0'),
          ),
        );
        return;
      }

      if (!isFreeSale &&
          priceText.isNotEmpty &&
          (parsedPrice == null || parsedPrice <= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid amount greater than 0'),
          ),
        );
        return;
      }

      if (_typeUsesCondition(_selectedType) &&
          ListingConditionUtils.normalizeCondition(_selectedCondition) ==
              null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a condition')),
        );
        return;
      }

      if (_locationType == 'hostel' &&
          (_selectedHostel == null || _selectedHostel!.trim().isEmpty)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a hostel')));
        return;
      }

      if (_locationType == 'campus' &&
          _locationDetailController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a campus location')),
        );
        return;
      }

      final rawContactName = _contactNameController.text.trim();
      final rawContactPhone = _contactPhoneController.text.trim();
      final normalizedContactName = rawContactName.isEmpty
          ? null
          : PhoneGateUtils.normalizeName(rawContactName);
      final normalizedContactPhone = rawContactPhone.isEmpty
          ? null
          : PhoneGateUtils.normalizePhone(rawContactPhone);

      if (_isAdmin &&
          rawContactPhone.isNotEmpty &&
          normalizedContactPhone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact phone must be a valid 10-digit number'),
          ),
        );
        return;
      }

      final isReady = await PhoneGateUtils.ensureUserReadyForAction(context);
      if (!isReady || !mounted) {
        return;
      }

      late final Map<String, dynamic> resolvedProfileData;
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .tracedGet('users/${user.uid} post listing submit profile');
        if (!userDoc.exists) {
          _showFailureSnackBar(
            'Your user profile was not found. Please sign in again.',
          );
          return;
        }

        final profileData = userDoc.data();
        if (profileData == null) {
          _showFailureSnackBar(
            'Your user profile is unavailable. Please sign in again.',
          );
          return;
        }
        resolvedProfileData = profileData;
      } catch (error) {
        _showFailureSnackBar(_formatPostError(error));
        return;
      }

      final campusId = (resolvedProfileData['campus_id'] as String?)?.trim();
      final isAdmin = resolvedProfileData['isAdmin'] == true;
      if (campusId == null || campusId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Campus not available. Sign in again.'),
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      final existingName = PhoneGateUtils.normalizeName(
        resolvedProfileData['name'],
      );
      final existingPhone = PhoneGateUtils.normalizePhone(
        resolvedProfileData['phone'],
      );
      if (existingName == null || existingPhone == null) {
        _showFailureSnackBar('Complete your profile before posting.');
        return;
      }

      setState(() {
        _isLoading = true;
        _showPostingSuccess = false;
        _postingStatusText = 'Posting...';
      });

      String? imageUrl;
      String successRoute = '';

      try {
        if (_selectedImage != null) {
          if (mounted) {
            setState(() {
              _postingStatusText = 'Uploading image...';
            });
          }

          imageUrl = await uploadImage(
            _selectedImage!,
            sellerId,
          ).timeout(const Duration(seconds: 60));
        }

        final userName = existingName;
        final imagePayload = imageUrl == null
            ? const <String, Object>{}
            : <String, Object>{'imageUrl': imageUrl};
        final listingImageUrls = imageUrl == null
            ? const <String>[]
            : <String>[imageUrl];

        final docRef = FirebaseFirestore.instance.collection('listings').doc();

        if (mounted) {
          setState(() {
            _postingStatusText = 'Posting...';
          });
        }

        await docRef
            .set({
              'title': _titleController.text.trim(),
              'price': resolvedPrice ?? 0.0,
              'createdAt': FieldValue.serverTimestamp(),
              'status': 'available',
              ...imagePayload,
              'imageUrls': listingImageUrls,
              'sellerId': sellerId,
              'user_name': userName,
              'currency': 'INR',
              'description': _descriptionController.text.trim(),
              ..._buildLocationPayload(),
              'type': _selectedType,
              'is_urgent': (_selectedType == 'request') ? _isUrgent : false,
              'allow_negotiation': allowNegotiation,
              'campus_id': campusId,
              if (isAdmin && normalizedContactName != null)
                'contactName': normalizedContactName,
              if (isAdmin && normalizedContactPhone != null)
                'contactPhone': normalizedContactPhone,
              if (_typeUsesCategories(_selectedType))
                'category': ListingCategoryUtils.normalizeCategoryForWrite(
                  _selectedCategory,
                  type: _selectedType!,
                ),
              if (_typeUsesCondition(_selectedType))
                'condition': ListingConditionUtils.normalizeCondition(
                  _selectedCondition,
                ),
              if (_selectedType == 'rent')
                'rental_price_unit': _selectedRentalPriceUnit,
              if (_selectedType == 'service')
                'pricing_type': _selectedServicePricingType,
            })
            .timeout(const Duration(seconds: 15));
        successRoute = _routeForPostedType();
      } catch (error) {
        if (imageUrl != null) {
          try {
            await FirebaseStorage.instance.refFromURL(imageUrl).delete();
          } catch (e, stack) {
            debugPrint('ERROR: $e');
            debugPrint('STACK: $stack');
          }
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        if (_selectedImage != null && imageUrl == null) {
          _showFailureSnackBar(_formatImageUploadError(error));
        } else {
          _showFailureSnackBar(_formatPostError(error));
        }
        return;
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _showPostingSuccess = true;
      });

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      context.tracedGo(successRoute);
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isPostingOverlayVisible && _selectedType == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _isPostingOverlayVisible) {
          return;
        }
        if (_selectedType != null) {
          _clearSelectedTypeSelection();
        }
      },
      child: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isPostingOverlayVisible,
            child: Scaffold(
              backgroundColor: _scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: _scaffoldBackgroundColor,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: _onSurfaceColor),
                  onPressed: _isPostingOverlayVisible
                      ? null
                      : () {
                          if (_selectedType != null) {
                            _clearSelectedTypeSelection();
                          } else {
                            context.pop();
                          }
                        },
                ),
                title: Text(
                  'Create Listing',
                  style: AppTypography.h2.copyWith(color: _onSurfaceColor),
                ),
                centerTitle: true,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Progress Bar
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            if (_selectedType == null) ...[
                              Center(
                                child: Text(
                                  'What would you like to do?',
                                  style: AppTypography.h2.copyWith(
                                    color: _onSurfaceColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  'Choose the type of listing you want to create',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: _onSurfaceMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.3,
                                children: [
                                  _buildTypeCard(
                                    Icons.inventory_2,
                                    'Sell Item',
                                    'sell',
                                  ),
                                  _buildTypeCard(
                                    Icons.vpn_key,
                                    'Rent Item',
                                    'rent',
                                  ),
                                  _buildTypeCard(
                                    Icons.build,
                                    'Offer Service',
                                    'service',
                                  ),
                                  _buildTypeCard(
                                    Icons.search,
                                    'Request Item',
                                    'request',
                                  ),
                                ],
                              ),
                            ] else ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedType == 'sell'
                                          ? 'Sell an Item'
                                          : _selectedType == 'rent'
                                          ? 'Rent an Item'
                                          : _selectedType == 'service'
                                          ? 'Offer a Service'
                                          : 'Make a Request',
                                      style: AppTypography.h3.copyWith(
                                        color: _onSurfaceColor,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _isPostingOverlayVisible
                                        ? null
                                        : _clearSelectedTypeSelection,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Change Type'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_selectedType == 'sell') _buildSellForm(),
                              if (_selectedType == 'rent') _buildRentForm(),
                              if (_selectedType == 'service')
                                _buildServiceForm(),
                              if (_selectedType == 'request')
                                _buildRequestForm(),
                            ],

                            if (_selectedType != null) ...[
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      (_isPostingOverlayVisible ||
                                          _isPosting ||
                                          _selectedType == null)
                                      ? null
                                      : _createListing,
                                  child: _isPosting
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Posting...',
                                              style: AppTypography.buttonText
                                                  .copyWith(
                                                    color: Colors.white,
                                                  ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'Post Listing',
                                          style: AppTypography.buttonText
                                              .copyWith(color: Colors.white),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 48),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isPostingOverlayVisible,
              child: AnimatedOpacity(
                opacity: _isPostingOverlayVisible ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  color: _scaffoldBackgroundColor.withValues(alpha: 0.96),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Column(
                        key: ValueKey(_showPostingSuccess),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _showPostingSuccess
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 52,
                                )
                              : const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: AppColors.primary,
                                  ),
                                ),
                          const SizedBox(height: 16),
                          Text(
                            _showPostingSuccess
                                ? 'Posted successfully'
                                : _postingStatusText,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _onSurfaceColor,
                              decoration: TextDecoration.none,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(IconData icon, String title, String typeValue) {
    bool isSelected = _selectedType == typeValue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _setSelectedType(typeValue);
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : _dividerColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _onSurfaceColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    Widget? labelTrailing,
    String? hint,
    String? prefix,
    IconData? prefixIcon,
    int maxLines = 1,
    TextEditingController? controller,
    TextInputType? keyboardType,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.label.copyWith(color: _onSurfaceMuted),
              ),
            ),
            if (labelTrailing != null) ...[
              const SizedBox(width: 12),
              labelTrailing,
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          enabled: enabled,
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          keyboardType: keyboardType,
          style: AppTypography.bodyLarge.copyWith(
            color: enabled ? _onSurfaceColor : _onSurfaceMuted,
          ),
          cursorColor: AppColors.primary,
          decoration: buildInputDecoration(
            hint ?? '',
            fillColor: enabled ? _surfaceColor : _scaffoldBackgroundColor,
            focusColor: AppColors.primary,
            hintStyle: AppTypography.bodyMedium.copyWith(color: _onSurfaceHint),
            prefixText: prefix,
            prefixStyle: AppTypography.bodyLarge.copyWith(
              color: enabled ? _onSurfaceColor : _onSurfaceMuted,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: _onSurfaceHint)
                : null,
            counterStyle: AppTypography.bodySmall.copyWith(
              color: _onSurfaceHint,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalePriceField() {
    return _buildTextField(
      label: 'Price',
      labelTrailing: _buildFreeToggle(),
      hint: 'e.g. 1500',
      prefix: '₹ ',
      controller: _priceController,
      keyboardType: TextInputType.number,
      enabled: !_isFree,
    );
  }

  Widget _buildFreeToggle() {
    return InkWell(
      onTap: () => _setFreeSale(!_isFree),
      borderRadius: BorderRadius.circular(999),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: _isFree,
            onChanged: (value) => _setFreeSale(value ?? false),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(
            'Mark as Free 🎁',
            style: AppTypography.bodySmall.copyWith(
              color: _onSurfaceColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminContactOverrideSection() {
    if (!_isAdmin) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Contact Override',
          style: AppTypography.h3.copyWith(color: _onSurfaceColor),
        ),
        const SizedBox(height: 8),
        Text(
          'Optional. If filled, buyers will see this contact and use this number instead of the seller profile.',
          style: AppTypography.bodySmall.copyWith(color: _onSurfaceMuted),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Contact Name (Optional)',
          hint: 'Enter contact name',
          controller: _contactNameController,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Contact Phone (Optional)',
          hint: 'Enter 10-digit phone number',
          controller: _contactPhoneController,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildAddPhotoBox() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _dividerColor, style: BorderStyle.none),
          ),
          child: _selectedImage == null
              ? CustomPaint(
                  painter: _DottedBorderPainter(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, color: AppColors.primary),
                      const SizedBox(height: 4),
                      Text(
                        'Add Photos',
                        style: AppTypography.bodySmall.copyWith(
                          color: _onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                      ? (_selectedImagePreviewBytes != null &&
                                _selectedImagePreviewBytes!.isNotEmpty
                            ? Image.memory(
                                _selectedImagePreviewBytes!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : _buildPhotoPlaceholder())
                      : Image.file(
                          File(_selectedImage!.path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                ),
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: _scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.image, color: AppColors.border, size: 32),
      ),
    );
  }

  Widget _buildSellForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Title',
          hint: 'e.g. Study table',
          controller: _titleController,
        ),
        const SizedBox(height: 16),
        _buildSalePriceField(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildConditionDropdown()),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCategoryDropdown(
                ListingCategories.getSellCategories(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Photos & Description',
          style: AppTypography.h3.copyWith(color: _onSurfaceColor),
        ),
        const SizedBox(height: 16),
        _buildPhotoRow(),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Description',
          hint:
              'Describe your item in detail (brand, usage time, any issues...)',
          maxLines: 4,
          controller: _descriptionController,
        ),
        const SizedBox(height: 32),
        _buildLocationSection(),
        const SizedBox(height: 32),
        _buildAdminContactOverrideSection(),
        if (_isAdmin) const SizedBox(height: 32),
        if (!_isFree) ...[
          Text(
            'Options',
            style: AppTypography.h3.copyWith(color: _onSurfaceColor),
          ),
          const SizedBox(height: 16),
          _buildOptionsBox(showNegotiation: true, showUrgent: false),
        ],
      ],
    );
  }

  Widget _buildRentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Title',
          hint: 'e.g. Room cooler for rent',
          controller: _titleController,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Price',
                prefix: '₹ ',
                controller: _priceController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildRentalUnitDropdown()),
          ],
        ),
        const SizedBox(height: 16),
        _buildCategoryDropdown(ListingCategories.getSellCategories()),
        const SizedBox(height: 16),
        _buildConditionDropdown(),
        const SizedBox(height: 32),
        Text(
          'Photos & Description',
          style: AppTypography.h3.copyWith(color: _onSurfaceColor),
        ),
        const SizedBox(height: 16),
        _buildPhotoRow(),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Description',
          hint: 'Describe your rental item in detail...',
          maxLines: 4,
          controller: _descriptionController,
        ),
        const SizedBox(height: 32),
        _buildLocationSection(),
        const SizedBox(height: 32),
        _buildAdminContactOverrideSection(),
        if (_isAdmin) const SizedBox(height: 32),
        Text(
          'Options',
          style: AppTypography.h3.copyWith(color: _onSurfaceColor),
        ),
        const SizedBox(height: 16),
        _buildOptionsBox(showNegotiation: true, showUrgent: false),
      ],
    );
  }

  Widget _buildServiceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Title',
          hint: 'e.g. I can write assignments',
          controller: _titleController,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Price (Optional)',
                prefix: '₹ ',
                controller: _priceController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildServicePricingDropdown()),
          ],
        ),
        const SizedBox(height: 16),
        _buildCategoryDropdown(ListingCategories.getServiceCategories()),
        const SizedBox(height: 32),
        Text(
          'Description',
          style: AppTypography.h3.copyWith(color: _onSurfaceColor),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Description',
          hint: 'Describe the service you offer...',
          maxLines: 4,
          controller: _descriptionController,
        ),
        const SizedBox(height: 32),
        _buildLocationSection(),
        const SizedBox(height: 32),
        _buildAdminContactOverrideSection(),
        if (_isAdmin) const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRequestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Title',
          hint: 'e.g. Need calculator for exam tomorrow',
          controller: _titleController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Budget (Optional)',
          prefix: '₹ ',
          controller: _priceController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 32),
        Text(
          'Description',
          style: AppTypography.h3.copyWith(color: _onSurfaceColor),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Description',
          hint: 'Describe what you are looking for...',
          maxLines: 4,
          controller: _descriptionController,
        ),
        const SizedBox(height: 32),
        _buildLocationSection(),
        const SizedBox(height: 32),
        _buildAdminContactOverrideSection(),
        if (_isAdmin) const SizedBox(height: 32),
        Text(
          'Options',
          style: AppTypography.h3.copyWith(color: _onSurfaceColor),
        ),
        const SizedBox(height: 16),
        _buildOptionsBox(showNegotiation: false, showUrgent: true),
      ],
    );
  }

  Widget _buildSelectField<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border.all(color: _dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: items,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: _surfaceColor,
          iconEnabledColor: _onSurfaceHint,
          style: AppTypography.bodyLarge.copyWith(color: _onSurfaceColor),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTypography.label.copyWith(color: _onSurfaceMuted),
        ),
        const SizedBox(height: 8),
        _buildSelectField<String>(
          value: categories.contains(_selectedCategory)
              ? _selectedCategory
              : categories.first,
          items: categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedCategory = v);
          },
        ),
      ],
    );
  }

  Widget _buildConditionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Condition',
          style: AppTypography.label.copyWith(color: _onSurfaceMuted),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _surfaceColor,
            border: Border.all(color: _dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCondition,
              hint: Text(
                'Select condition',
                style: AppTypography.bodyLarge.copyWith(color: _onSurfaceHint),
              ),
              items: ListingConditionUtils.orderedValues
                  .map(
                    (condition) => DropdownMenuItem(
                      value: condition,
                      child: Text(
                        ListingConditionUtils.getDisplayCondition(condition),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCondition = value;
                });
              },
              borderRadius: BorderRadius.circular(12),
              dropdownColor: _surfaceColor,
              iconEnabledColor: _onSurfaceHint,
              style: AppTypography.bodyLarge.copyWith(color: _onSurfaceColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicePricingDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing Type',
          style: AppTypography.label.copyWith(color: _onSurfaceMuted),
        ),
        const SizedBox(height: 8),
        _buildSelectField<String>(
          value: _selectedServicePricingType,
          items: const [
            DropdownMenuItem(value: 'fixed', child: Text('Fixed Price')),
            DropdownMenuItem(
              value: 'starting_from',
              child: Text('Starting From'),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _selectedServicePricingType = v);
          },
        ),
      ],
    );
  }

  Widget _buildRentalUnitDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rental Unit',
          style: AppTypography.label.copyWith(color: _onSurfaceMuted),
        ),
        const SizedBox(height: 8),
        _buildSelectField<String>(
          value: _selectedRentalPriceUnit,
          items: MarketplaceConfig.rentalTypes.map((r) {
            final c = r[0].toUpperCase() + r.substring(1);
            return DropdownMenuItem(value: r, child: Text('Per $c'));
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedRentalPriceUnit = v);
          },
        ),
      ],
    );
  }

  Widget _buildPhotoRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [_buildAddPhotoBox()]),
    );
  }

  Widget _buildLocationSection() {
    final availableHostels = _availableHostels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where to meet',
          style: AppTypography.label.copyWith(color: _onSurfaceMuted),
        ),
        const SizedBox(height: 8),
        _buildSelectField<String>(
          value: _locationType,
          items: const [
            DropdownMenuItem(value: 'hostel', child: Text('Hostel')),
            DropdownMenuItem(value: 'campus', child: Text('Campus')),
            DropdownMenuItem(value: 'anywhere', child: Text('Anywhere')),
            DropdownMenuItem(value: 'online', child: Text('Online')),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() {
                if (_locationType != v) {
                  _locationDetailController.clear();
                }
                _locationType = v;
                if (_locationType == 'anywhere' || _locationType == 'online') {
                  _selectedHostel = null;
                } else if (_locationType == 'campus') {
                  _selectedHostel = null;
                } else if (_locationType == 'hostel') {
                  _selectedHostel = availableHostels.isEmpty
                      ? null
                      : availableHostels.first;
                }
              });
            }
          },
        ),
        if (_locationType == 'hostel') ...[
          const SizedBox(height: 16),
          if (availableHostels.isNotEmpty)
            _buildSelectField<String>(
              value: _selectedHostel ?? availableHostels.first,
              items: availableHostels
                  .map(
                    (hostel) => DropdownMenuItem(
                      value: hostel,
                      child: Text(hostel, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _selectedHostel = v;
                  });
                }
              },
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _surfaceColor,
                border: Border.all(color: _dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No hostels available for your campus',
                style: AppTypography.bodyMedium.copyWith(
                  color: _onSurfaceMuted,
                ),
              ),
            ),
        ],
        if (_locationType == 'hostel' || _locationType == 'campus') ...[
          const SizedBox(height: 16),
          _buildTextField(
            label: _locationType == 'hostel'
                ? 'Details (optional)'
                : 'Location',
            hint: _locationType == 'hostel'
                ? 'e.g. Room 217'
                : 'e.g. Library, Gate 2',
            controller: _locationDetailController,
            maxLength: 30,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ],
    );
  }

  Widget _buildOptionsBox({
    required bool showNegotiation,
    required bool showUrgent,
  }) {
    if (!showNegotiation && !showUrgent) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (showUrgent)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.flash_on,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Mark as Urgent',
                      style: AppTypography.bodyLarge.copyWith(
                        color: _onSurfaceColor,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _isUrgent,
                  onChanged: (v) => setState(() => _isUrgent = v),
                ),
              ],
            ),
          if (showUrgent && showNegotiation) const Divider(height: 24),
          if (showNegotiation)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.payments,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Allow Negotiation',
                      style: AppTypography.bodyLarge.copyWith(
                        color: _onSurfaceColor,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _allowNegotiation,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _allowNegotiation = v),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    var path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(12),
        ),
      );

    canvas.drawPath(
      path,
      paint..color = AppColors.textHint.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
