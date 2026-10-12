import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/location_service.dart';
import '../../core/services/image_upload_service.dart';
import '../../core/services/notification_store.dart';
import '../../core/theme/app_theme.dart';
import '../../models/category_model.dart';
import '../../models/complaint_model.dart';
import '../../repositories/category_repo.dart';
import '../../repositories/complaint_repo.dart';

class CreateComplaintScreen extends StatefulWidget {
  const CreateComplaintScreen({super.key});

  @override
  State<CreateComplaintScreen> createState() => _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends State<CreateComplaintScreen> {
  static const List<String> _stepTitles = [
    'Capture & Details',
    'Review',
    'Dispatch',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _wardController = TextEditingController();

  late final CategoryRepository _categoryRepository;
  late final ComplaintRepository _complaintRepository;

  int _step = 0;

  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;
  String? _error;

  // Location state -- coordinates only, no map widget.
  double? _latitude;
  double? _longitude;
  bool _isDetectingLocation = false;

  // Photo state
  Uint8List? _photoBytes;
  String? _uploadedPhotoUrl;
  bool _isUploadingPhoto = false;

  // UI-only severity picker. Not sent to the backend -- there is no
  // severity/priority field on complaint creation. Priority is set later
  // by the authority on Verify. Kept here purely for the citizen's own
  // sense of urgency; has zero effect on the submitted request.
  String _severity = 'moderate';

  // UI-only toggle. There is no anonymous-submission flag on the backend.
  bool _civicProfileOn = true;

  @override
  void initState() {
    super.initState();
    final dio = DioClient.createDio();
    _categoryRepository = CategoryRepository(dio);
    _complaintRepository = ComplaintRepository(dio);
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _wardController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryRepository.getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load categories: ${e.toString().replaceFirst('Exception: ', '')}';
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isDetectingLocation = true;
      _error = null;
    });
    try {
      final result = await LocationService.getCurrentLocationWithAddress();
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        // Best-effort: fills in when reverse geocoding succeeds (usually
        // on a real device). If it comes back empty -- common on
        // emulators, which frequently lack a working Geocoder backend --
        // these fields just stay blank and editable for manual entry.
        if (result.address != null && result.address!.isNotEmpty) {
          _addressController.text = result.address!;
        }
        if (result.city != null && result.city!.isNotEmpty) {
          _cityController.text = result.city!;
        }
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _capturePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _uploadedPhotoUrl = null;
    });
  }

  Future<String?> _ensurePhotoUploaded() async {
    if (_photoBytes == null) return null;
    if (_uploadedPhotoUrl != null) return _uploadedPhotoUrl;

    setState(() => _isUploadingPhoto = true);
    try {
      final url = await ImageUploadService.uploadImage(_photoBytes!);
      setState(() => _uploadedPhotoUrl = url);
      return url;
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }

  Future<bool?> _showDuplicateDialog(ComplaintResponse existing) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Similar complaint found'),
        content: Text(
          'A similar complaint already exists nearby:\n\n"${existing.title}"\n\nWould you like to upvote it instead of filing a new one?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await _complaintRepository.upvoteComplaint(existing.id);
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Upvote failed: ${e.toString().replaceFirst('Exception: ', '')}')),
                  );
                  Navigator.pop(context, null);
                }
              }
            },
            child: const Text('Yes, upvote'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, file new'),
          ),
        ],
      ),
    );
  }

  void _goToReview() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      setState(() => _error = 'Please select a category');
      return;
    }
    if (_latitude == null || _longitude == null) {
      setState(() => _error = 'Please detect your location first');
      return;
    }
    setState(() {
      _error = null;
      _step = 1;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final similar = await _complaintRepository.checkSimilarComplaints(
        categoryId: _selectedCategory!.id,
        latitude: _latitude!,
        longitude: _longitude!,
      );

      if (similar.isNotEmpty) {
        final result = await _showDuplicateDialog(similar.first);
        if (!mounted) return;
        if (result == true) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upvoted existing complaint')),
          );
          Navigator.of(context).pop();
          return;
        }
        if (result == null) {
          setState(() => _isSubmitting = false);
          return;
        }
      }

      String? photoUrl;
      if (_photoBytes != null) {
        photoUrl = await _ensurePhotoUploaded();
      }

      final created = await _complaintRepository.createComplaint(
        ComplaintCreateRequest(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          categoryId: _selectedCategory!.id,
          photoUrl: photoUrl,
          latitude: _latitude!,
          longitude: _longitude!,
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          city: _cityController.text.trim(),
          ward: _wardController.text.trim(),
        ),
      );
      NotificationStore.instance.notifyFiled(created);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint filed successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ---------------------------------------------------------------
  // UI building blocks
  // ---------------------------------------------------------------

  Widget _buildStepperHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        '${_step + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Step ${_step + 1} of 3: ${_stepTitles[_step]}',
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.04 * 11,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= _step ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              final labels = ['1. Capture', '2. Review', '3. Dispatch'];
              final active = i == _step;
              return Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: active ? AppColors.primary : AppColors.textMuted,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('pothole') || n.contains('road')) return Icons.directions_car_filled_rounded;
    if (n.contains('light')) return Icons.lightbulb_outline_rounded;
    if (n.contains('garbage') || n.contains('sanitation') || n.contains('trash')) return Icons.delete_outline_rounded;
    if (n.contains('animal')) return Icons.pets_rounded;
    if (n.contains('water')) return Icons.water_drop_outlined;
    if (n.contains('tax') || n.contains('revenue')) return Icons.account_balance_outlined;
    return Icons.report_gmailerrorred_rounded;
  }

  Widget _buildCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  // ---------------------------------------------------------------
  // Step 0: Capture & Details
  // ---------------------------------------------------------------

  Widget _buildCaptureStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.errorColor.withValues(alpha: 0.3)),
                ),
                child: Text(_error!, style: const TextStyle(color: AppColors.errorColor)),
              ),
              const SizedBox(height: 16),
            ],

            // Photo card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: _photoBytes != null
                        ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(_photoBytes!, fit: BoxFit.cover),
                        if (_latitude != null)
                          Positioned(
                            top: 10, left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.gps_fixed_rounded, size: 12, color: Colors.white),
                                  SizedBox(width: 5),
                                  Text('Location attached', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          top: 10, right: 10,
                          child: InkWell(
                            onTap: _capturePhoto,
                            borderRadius: BorderRadius.circular(9999),
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
                              child: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    )
                        : Container(
                      color: AppColors.canvas,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.textMuted),
                          const SizedBox(height: 8),
                          Text('No photo yet', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingPhoto ? null : _capturePhoto,
                      icon: _isUploadingPhoto
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.camera_alt_outlined),
                      label: Text(_photoBytes == null ? 'Capture photo' : 'Retake photo'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _titleController,
              maxLength: 150,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLength: 2000,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 20),

            Text('Confirm category', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (_isLoadingCategories)
              const Center(child: CircularProgressIndicator())
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.6,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, i) {
                  final c = _categories[i];
                  final selected = _selectedCategory?.id == c.id;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedCategory = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(_iconForCategory(c.name), size: 18, color: selected ? Colors.white : AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (selected) const Icon(Icons.check_circle, size: 16, color: Colors.white),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),

            Text('Incident location', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),

            // CHANGED: no map widget -- just the raw coordinates plus a
            // detect button. Address/city below remain editable in case
            // reverse geocoding doesn't come back (common on emulators).
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        _latitude != null ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                        size: 20,
                        color: _latitude != null ? AppColors.primary : AppColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _latitude != null
                              ? '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                              : 'Location not detected yet',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: _latitude != null ? FontWeight.w600 : FontWeight.w400,
                            color: _latitude != null ? AppColors.textPrimary : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isDetectingLocation ? null : _detectLocation,
                    icon: _isDetectingLocation
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                    label: Text(_latitude == null ? 'Detect my location' : 'Re-detect location'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _addressController,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Address (auto-filled, editable)'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City (auto-filled, editable)'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'City is required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _wardController,
              decoration: const InputDecoration(labelText: 'Ward'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ward is required' : null,
            ),
            const SizedBox(height: 20),

            Text('Urgency (for your reference)', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Not sent with your report -- priority is set by the authority after review.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _severityChip('low', 'Low'),
                const SizedBox(width: 6),
                _severityChip('moderate', 'Mod'),
                const SizedBox(width: 6),
                _severityChip('high', 'High'),
                const SizedBox(width: 6),
                _severityChip('hazard', 'Hazard'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _severityChip(String value, String label) {
    final selected = _severity == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _severity = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.border : Colors.transparent),
            boxShadow: selected ? AppColors.shadowLevel1 : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: selected ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Step 1: Review
  // ---------------------------------------------------------------

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value.isEmpty ? '—' : value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Report details', style: Theme.of(context).textTheme.titleLarge),
                    TextButton(onPressed: () => setState(() => _step = 0), child: const Text('Change')),
                  ],
                ),
                if (_photoBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_photoBytes!, height: 140, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 8),
                ],
                _reviewRow('Title', _titleController.text.trim()),
                _reviewRow('Category', _selectedCategory?.name ?? ''),
                _reviewRow('Address', _addressController.text.trim()),
                _reviewRow('City / Ward', '${_cityController.text.trim()} / ${_wardController.text.trim()}'),
                _reviewRow('Coordinates', _latitude != null ? '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}' : ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Step 2: Dispatch
  // ---------------------------------------------------------------

  Widget _buildDispatchStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.errorColor.withValues(alpha: 0.3)),
              ),
              child: Text(_error!, style: const TextStyle(color: AppColors.errorColor)),
            ),
            const SizedBox(height: 16),
          ],

          _buildCard(
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.shield_outlined, color: AppColors.secondary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Submit with civic profile', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Preview only -- not yet connected to the backend', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Switch(value: _civicProfileOn, onChanged: (v) => setState(() => _civicProfileOn = v)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF0369A1)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Target municipal response window (preview -- not confirmed by backend)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
            label: Text(_isSubmitting ? 'Submitting…' : 'Submit report'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Footer nav + build
  // ---------------------------------------------------------------

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => setState(() => _step -= 1),
                child: const Text('Back'),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          if (_step < 2)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _step == 0 ? _goToReview : () => setState(() => _step = 2),
                child: const Text('Next'),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File a complaint')),
      body: Column(
        children: [
          _buildStepperHeader(),
          Expanded(
            child: switch (_step) {
              0 => _buildCaptureStep(),
              1 => _buildReviewStep(),
              _ => _buildDispatchStep(),
            },
          ),
          _buildFooter(),
        ],
      ),
    );
  }
}