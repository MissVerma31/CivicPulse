import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/dio_client.dart';
import '../../core/storage/token_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../models/complaint_model.dart';
import '../../repositories/complaint_repo.dart';
import '../../widgets/complaint_tracking_rail.dart';
import '../../widgets/sla_badge.dart';
import '../../core/services/image_upload_service.dart';

class ComplaintDetailsScreen extends StatefulWidget {
  final int complaintId;

  const ComplaintDetailsScreen({
    super.key,
    required this.complaintId,
  });

  @override
  State<ComplaintDetailsScreen> createState() =>
      _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState
    extends State<ComplaintDetailsScreen> {
  late final ComplaintRepository _complaintRepository;

  ComplaintResponse? _complaint;

  String? _role;

  bool _isLoading = true;
  bool _isActionLoading = false;
  bool _isUpvoting = false;

  Timer? _pollTimer;

  String? _error;

  @override
  void initState() {
    super.initState();

    _complaintRepository =
        ComplaintRepository(DioClient.createDio());

    _init();

    _pollTimer = Timer.periodic(
      const Duration(seconds: 20),
          (_) => _silentRefresh(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // =========================================================
  // REFRESH
  // =========================================================

  Future<void> _silentRefresh() async {
    if (_isLoading ||
        _isActionLoading ||
        _isUpvoting) {
      return;
    }

    try {
      final c =
      await _complaintRepository.getComplaintById(
        widget.complaintId,
      );

      if (mounted) {
        setState(() {
          _complaint = c;
        });
      }
    } catch (_) {}
  }

  Future<void> _init() async {
    _role = await TokenStorage.getRole();

    await _loadComplaint();
  }

  Future<void> _loadComplaint() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final c =
      await _complaintRepository.getComplaintById(
        widget.complaintId,
      );

      setState(() {
        _complaint = c;
      });
    } catch (e) {
      setState(() {
        _error =
            e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // GENERIC ACTION
  // =========================================================

  Future<void> _runAction(
      Future<void> Function() action,
      ) async {
    setState(() {
      _isActionLoading = true;
    });

    try {
      await action();

      await _loadComplaint();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  // =========================================================
  // VERIFY
  // =========================================================

  
  // =========================================================
  // RESOLVE COMPLAINT
  // =========================================================

  Future<void> _showResolveDialog() async {
    final noteController = TextEditingController();

    XFile? resolutionPhoto;

    bool isUploadingPhoto = false;

    String? photoError;

    final result = await showDialog<Map<String, String>?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // =====================================================
            // CAPTURE PHOTO
            // =====================================================

            Future<void> captureResolutionPhoto() async {
              try {
                final picker = ImagePicker();

                final XFile? pickedPhoto =
                await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                  maxWidth: 1280,
                );

                if (pickedPhoto == null) {
                  return;
                }

                // Store the actual XFile.
                setDialogState(() {
                  resolutionPhoto = pickedPhoto;
                  photoError = null;
                });
              } catch (e) {
                setDialogState(() {
                  photoError =
                  'Could not capture photo: $e';
                });
              }
            }

            // =====================================================
            // UPLOAD PHOTO
            // =====================================================

            Future<void> uploadAndResolve() async {
              if (resolutionPhoto == null) {
                setDialogState(() {
                  photoError =
                  'Please capture a resolution photo first.';
                });
                return;
              }

              setDialogState(() {
                isUploadingPhoto = true;
                photoError = null;
              });

              try {
                // Read captured image as bytes.
                final Uint8List imageBytes =
                await resolutionPhoto!.readAsBytes();

                if (imageBytes.isEmpty) {
                  throw Exception(
                    'Captured image is empty.',
                  );
                }

                // Upload to ImgBB.
                final String photoUrl =
                await ImageUploadService.uploadImage(
                  imageBytes,
                );

                if (!dialogContext.mounted) {
                  return;
                }

                // Return note + uploaded URL.
                Navigator.pop(
                  dialogContext,
                  {
                    'note':
                    noteController.text.trim(),
                    'photoUrl':
                    photoUrl,
                  },
                );
              } catch (e) {
                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  isUploadingPhoto = false;

                  photoError = e
                      .toString()
                      .replaceFirst(
                    'Exception: ',
                    '',
                  );
                });
              }
            }

            // =====================================================
            // DIALOG
            // =====================================================

            return AlertDialog(
              title: const Text(
                'Resolve Complaint',
              ),

              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                    children: [

                      // -------------------------------------------
                      // RESOLUTION NOTE
                      // -------------------------------------------

                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        enabled: !isUploadingPhoto,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Resolution note',
                          hintText:
                          'Describe what was fixed...',
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // -------------------------------------------
                      // PHOTO TITLE
                      // -------------------------------------------

                      const Text(
                        'Resolution Photo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      // -------------------------------------------
                      // PHOTO PREVIEW
                      // -------------------------------------------

                      if (resolutionPhoto != null)
                        FutureBuilder<Uint8List>(
                          future:
                          resolutionPhoto!
                              .readAsBytes(),

                          builder:
                              (
                              context,
                              snapshot,
                              ) {
                            if (snapshot
                                .connectionState ==
                                ConnectionState
                                    .waiting) {
                              return Container(
                                height: 180,
                                width:
                                double.infinity,
                                decoration:
                                BoxDecoration(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    12,
                                  ),
                                  color:
                                  Colors.grey
                                      .shade200,
                                ),
                                child:
                                const Center(
                                  child:
                                  CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (snapshot
                                .hasError ||
                                !snapshot.hasData) {
                              return Container(
                                height: 180,
                                width:
                                double.infinity,
                                decoration:
                                BoxDecoration(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    12,
                                  ),
                                  color:
                                  Colors.grey
                                      .shade200,
                                ),
                                child:
                                const Center(
                                  child: Text(
                                    'Unable to preview photo',
                                  ),
                                ),
                              );
                            }

                            return ClipRRect(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),
                              child:
                              Image.memory(
                                snapshot.data!,
                                height: 180,
                                width:
                                double.infinity,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),

                      const SizedBox(
                        height: 10,
                      ),

                      // -------------------------------------------
                      // CAMERA BUTTON
                      // -------------------------------------------

                      OutlinedButton.icon(
                        onPressed:
                        isUploadingPhoto
                            ? null
                            : captureResolutionPhoto,

                        icon: const Icon(
                          Icons.camera_alt,
                        ),

                        label: Text(
                          resolutionPhoto == null
                              ? 'Capture Resolution Photo'
                              : 'Retake Photo',
                        ),
                      ),

                      // -------------------------------------------
                      // PHOTO SELECTED MESSAGE
                      // -------------------------------------------

                      if (resolutionPhoto !=
                          null)
                        const Padding(
                          padding:
                          EdgeInsets.only(
                            top: 6,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .check_circle,
                                size: 18,
                                color:
                                Colors.green,
                              ),
                              SizedBox(
                                width: 6,
                              ),
                              Text(
                                'Photo captured successfully',
                                style:
                                TextStyle(
                                  color:
                                  Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // -------------------------------------------
                      // ERROR
                      // -------------------------------------------

                      if (photoError != null)
                        Padding(
                          padding:
                          const EdgeInsets.only(
                            top: 8,
                          ),
                          child: Text(
                            photoError!,
                            style: TextStyle(
                              color:
                              Colors.red
                                  .shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      // -------------------------------------------
                      // UPLOAD PROGRESS
                      // -------------------------------------------

                      if (isUploadingPhoto)
                        const Padding(
                          padding:
                          EdgeInsets.only(
                            top: 14,
                          ),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(
                                height: 8,
                              ),
                              Text(
                                'Uploading photo...',
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ===================================================
              // BUTTONS
              // ===================================================

              actions: [

                TextButton(
                  onPressed:
                  isUploadingPhoto
                      ? null
                      : () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                  const Text('Cancel'),
                ),

                ElevatedButton.icon(
                  onPressed:
                  isUploadingPhoto ||
                      resolutionPhoto ==
                          null
                      ? null
                      : uploadAndResolve,

                  icon: const Icon(
                    Icons.check_circle,
                  ),

                  label: const Text(
                    'Mark Resolved',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    noteController.dispose();

    // ===========================================================
    // SEND TO YOUR EXISTING BACKEND
    // ===========================================================

    if (result != null) {
      _runAction(
            () => _complaintRepository
            .resolveComplaint(
          widget.complaintId,
          result['note'] ?? '',
          result['photoUrl']!,
        ),
      );
    }
  }


  // =========================================================
  // REJECT
  // =========================================================

  Future<void> _showRejectDialog() async {
    final reasonController =
    TextEditingController();

    final confirmed =
    await showDialog<bool>(
      context: context,

      builder: (context) =>
          AlertDialog(
            title: const Text(
              'Reject Complaint',
            ),

            content: TextField(
              controller:
              reasonController,

              maxLines: 3,

              decoration:
              const InputDecoration(
                labelText:
                'Reason for rejection',
              ),
            ),

            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                      false,
                    ),

                child:
                const Text('Cancel'),
              ),

              ElevatedButton(
                onPressed: () {
                  if (reasonController
                      .text
                      .trim()
                      .isEmpty) {
                    return;
                  }

                  Navigator.pop(
                    context,
                    true,
                  );
                },

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.red,
                ),

                child:
                const Text('Reject'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      _runAction(
            () => _complaintRepository
            .rejectComplaint(
          widget.complaintId,
          reasonController.text.trim(),
        ),
      );
    }
  }

  // =========================================================
  // UPVOTE
  // =========================================================

  Future<void> _upvote() async {
    setState(() {
      _isUpvoting = true;
    });

    try {
      await _complaintRepository
          .upvoteComplaint(
        widget.complaintId,
      );

      final c =
      await _complaintRepository
          .getComplaintById(
        widget.complaintId,
      );

      if (!mounted) return;

      setState(() {
        _complaint = c;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text('Upvoted'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpvoting = false;
        });
      }
    }
  }

  // =========================================================
  // UPVOTE ROW
  // =========================================================

  Widget _buildUpvoteRow() {
    if (_complaint == null) {
      return const SizedBox.shrink();
    }

    final status =
        _complaint!.status;

    final isAuthority =
        (_role ?? '').toUpperCase() ==
            'AUTHORITY';

    final canUpvote =
        !isAuthority &&
            status !=
                ComplaintStatus.rejected &&
            status !=
                ComplaintStatus.closed;

    final count =
        _complaint!.upvoteCount;

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),

      decoration:
      BoxDecoration(
        color: AppColors.surface,

        borderRadius:
        BorderRadius.circular(16),

        border: Border.all(
          color: AppColors.border,
        ),
      ),

      child: Row(
        children: [

          const Icon(
            Icons.arrow_upward_rounded,
            size: 20,
            color: AppColors.primary,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              '$count community upvote${count == 1 ? '' : 's'}',

              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),

          if (canUpvote)
            OutlinedButton(
              onPressed:
              _isUpvoting
                  ? null
                  : _upvote,

              style:
              OutlinedButton.styleFrom(
                minimumSize:
                const Size(0, 38),

                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 16,
                ),
              ),

              child: _isUpvoting
                  ? const SizedBox(
                width: 16,
                height: 16,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Upvote',
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // PHOTO TILE
  // =========================================================

  Widget _photoTile(
      String label,
      String url,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 16,
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Text(
            label,

            style:
            const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          GestureDetector(
            onTap: () =>
                _openFullPhoto(url),

            child: ClipRRect(
              borderRadius:
              BorderRadius.circular(
                12,
              ),

              child:
              Image.network(
                url,

                width:
                double.infinity,

                height: 200,

                fit: BoxFit.cover,

                loadingBuilder:
                    (
                    context,
                    child,
                    progress,
                    ) {
                  if (progress ==
                      null) {
                    return child;
                  }

                  return Container(
                    height: 200,

                    alignment:
                    Alignment.center,

                    color:
                    AppColors.surface,

                    child:
                    const CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  );
                },

                errorBuilder:
                    (
                    context,
                    error,
                    stack,
                    ) =>
                    Container(
                      height: 200,

                      alignment:
                      Alignment.center,

                      color:
                      AppColors.surface,

                      child:
                      const Icon(
                        Icons
                            .broken_image_outlined,

                        size: 36,

                        color:
                        Colors.grey,
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FULL PHOTO
  // =========================================================

  void _openFullPhoto(
      String url,
      ) {
    showDialog(
      context: context,

      builder: (context) =>
          Dialog(
            insetPadding:
            const EdgeInsets.all(
              12,
            ),

            backgroundColor:
            Colors.black,

            child:
            InteractiveViewer(
              child:
              Image.network(url),
            ),
          ),
    );
  }

  // =========================================================
  // BEFORE / AFTER PHOTO SECTION
  // =========================================================

  Widget _buildPhotoSection() {
    final c = _complaint;

    if (c == null) {
      return const SizedBox.shrink();
    }

    final reported =
        c.photoUrl ?? '';

    final resolution =
        c.resolutionPhotoUrl ?? '';

    if (reported.isEmpty &&
        resolution.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        const Text(
          'Before vs After',

          style: TextStyle(
            fontSize: 18,
            fontWeight:
            FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // ===============================================
            // BEFORE
            // ===============================================

            if (reported.isNotEmpty)
              Expanded(
                child: _beforeAfterCard(
                  title: 'BEFORE',
                  subtitle:
                  'Reported issue',
                  url: reported,
                  icon:
                  Icons.report_problem_outlined,
                ),
              ),

            if (reported.isNotEmpty &&
                resolution.isNotEmpty)
              const SizedBox(
                width: 12,
              ),

            // ===============================================
            // AFTER
            // ===============================================

            if (resolution.isNotEmpty)
              Expanded(
                child: _beforeAfterCard(
                  title: 'AFTER',
                  subtitle:
                  'Resolved issue',
                  url: resolution,
                  icon:
                  Icons.check_circle_outline,
                ),
              ),
          ],
        ),

        const SizedBox(
          height: 20,
        ),
      ],
    );
  }

  Widget _beforeAfterCard({
    required String title,
    required String subtitle,
    required String url,
    required IconData icon,
  }) {
    return Container(
      decoration:
      BoxDecoration(
        color: AppColors.surface,

        borderRadius:
        BorderRadius.circular(14),

        border: Border.all(
          color: AppColors.border,
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Padding(
            padding:
            const EdgeInsets.all(
              10,
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Row(
                  children: [

                    Icon(
                      icon,
                      size: 18,
                      color:
                      AppColors.primary,
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Expanded(
                      child: Text(
                        title,

                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  subtitle,

                  style:
                  const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () =>
                _openFullPhoto(url),

            child: ClipRRect(
              borderRadius:
              const BorderRadius.only(
                bottomLeft:
                Radius.circular(14),
                bottomRight:
                Radius.circular(14),
              ),

              child:
              Image.network(
                url,

                height: 170,

                width:
                double.infinity,

                fit: BoxFit.cover,

                loadingBuilder:
                    (
                    context,
                    child,
                    progress,
                    ) {
                  if (progress ==
                      null) {
                    return child;
                  }

                  return const SizedBox(
                    height: 170,

                    child: Center(
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },

                errorBuilder:
                    (
                    context,
                    error,
                    stack,
                    ) {
                  return const SizedBox(
                    height: 170,

                    child: Center(
                      child: Icon(
                        Icons
                            .broken_image_outlined,
                        size: 35,
                        color:
                        Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ACTION BUTTONS
  // =========================================================

  Widget _buildActionButtons() {
    if (_complaint == null ||
        _role == null) {
      return const SizedBox.shrink();
    }

    final status =
        _complaint!.status;

    final isAuthority =
        _role!.toUpperCase() ==
            'AUTHORITY';

    final buttons =
    <Widget>[];

    if (isAuthority) {

      // -----------------------------------------------
      // PENDING VERIFICATION
      // -----------------------------------------------

      if (status == ComplaintStatus.pendingVerification) {
        buttons.add(ElevatedButton.icon(
          onPressed: _isActionLoading
              ? null
              : () => _runAction(
                () => _complaintRepository.verifyComplaint(widget.complaintId, 'HIGH'),
          ),
          icon: const Icon(Icons.verified_outlined),
          label: const Text('Verify'),
        ));

        buttons.add(
          OutlinedButton.icon(
            onPressed:
            _isActionLoading
                ? null
                : _showRejectDialog,

            icon: const Icon(
              Icons.cancel_outlined,
              color: Colors.red,
            ),

            label: const Text(
              'Reject',
              style: TextStyle(
                color: Colors.red,
              ),
            ),

            style:
            OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Colors.red,
              ),
            ),
          ),
        );
      }

      // -----------------------------------------------
      // VERIFIED
      // -----------------------------------------------

      else if (status ==
          ComplaintStatus
              .verified) {

        buttons.add(
          ElevatedButton.icon(
            onPressed:
            _isActionLoading
                ? null
                : () =>
                _runAction(
                      () =>
                      _complaintRepository
                          .startProgress(
                        widget.complaintId,
                      ),
                ),

            icon: const Icon(
              Icons.play_arrow,
            ),

            label:
            const Text(
              'Start Progress',
            ),
          ),
        );
      }

      // -----------------------------------------------
      // IN PROGRESS
      // -----------------------------------------------

      else if (status ==
          ComplaintStatus
              .inProgress) {

        buttons.add(
          ElevatedButton.icon(
            onPressed:
            _isActionLoading
                ? null
                : _showResolveDialog,

            icon: const Icon(
              Icons
                  .check_circle_outline,
            ),

            label:
            const Text(
              'Resolve',
            ),
          ),
        );
      }
    }

    // =====================================================
    // CITIZEN ACTIONS
    // =====================================================

    else {

      if (status ==
          ComplaintStatus
              .resolved) {

        buttons.add(
          ElevatedButton.icon(
            onPressed:
            _isActionLoading
                ? null
                : () =>
                _runAction(
                      () =>
                      _complaintRepository
                          .closeComplaint(
                        widget.complaintId,
                      ),
                ),

            icon: const Icon(
              Icons.done_all,
            ),

            label:
            const Text(
              'Close Complaint',
            ),
          ),
        );
      }
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
      const EdgeInsets.only(
        top: 16,
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .stretch,

        children: buttons
            .map(
              (b) => Padding(
            padding:
            const EdgeInsets.only(
              bottom: 8,
            ),
            child: b,
          ),
        )
            .toList(),
      ),
    );
  }

  // =========================================================
  // INFORMATION ROW
  // =========================================================

  Widget _infoRow(
      String label,
      String? value,
      ) {
    if (value == null ||
        value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 4,
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          SizedBox(
            width: 110,

            child: Text(
              label,

              style:
              const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),

          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text(
          'Complaint Details',
        ),
      ),

      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )

          : _error != null
          ? Center(
        child:
        Text(_error!),
      )

          : RefreshIndicator(
        onRefresh:
        _loadComplaint,

        child: ListView(
          padding:
          const EdgeInsets
              .all(20),

          children: [

            // ======================================
            // TITLE
            // ======================================

            Text(
              _complaint!.title,

              style:
              const TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            // ======================================
            // STATUS
            // ======================================

            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment:
              WrapCrossAlignment
                  .center,

              children: [
                StatusBadge(
                  status:
                  _complaint!
                      .status
                      .name,
                ),

                SlaBadge(
                  complaint:
                  _complaint!,
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            // ======================================
            // TRACKING
            // ======================================

            Container(
              padding:
              const EdgeInsets
                  .all(16),

              decoration:
              BoxDecoration(
                color:
                AppColors
                    .surface,

                borderRadius:
                BorderRadius
                    .circular(
                  16,
                ),

                border:
                Border.all(
                  color:
                  AppColors
                      .border,
                ),
              ),

              child:
              ComplaintTrackingRail(
                status:
                _complaint!
                    .status,

                rejectionReason:
                _complaint!
                    .rejectionReason,

                createdAt:
                _complaint!
                    .createdAt,

                verifiedAt:
                _complaint!
                    .verifiedAt,

                resolvedAt:
                _complaint!
                    .resolvedAt,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ======================================
            // BEFORE / AFTER
            // ======================================

            _buildPhotoSection(),

            // ======================================
            // UPVOTE
            // ======================================

            _buildUpvoteRow(),

            const SizedBox(
              height: 20,
            ),

            // ======================================
            // DESCRIPTION
            // ======================================

            if (_complaint!
                .description !=
                null) ...[
              Text(
                _complaint!
                    .description!,

                style:
                const TextStyle(
                  fontSize: 15,
                ),
              ),

              const SizedBox(
                height: 16,
              ),
            ],

            const Divider(),

            // ======================================
            // INFORMATION
            // ======================================

            _infoRow(
              'Category',
              _complaint!
                  .categoryName,
            ),

            _infoRow(
              'Department',
              _complaint!
                  .department,
            ),

            _infoRow(
              'Priority',
              _complaint!
                  .priority,
            ),

            _infoRow(
              'Address',
              _complaint!
                  .address,
            ),

            _infoRow(
              'City',
              _complaint!
                  .city,
            ),

            _infoRow(
              'Ward',
              _complaint!
                  .ward,
            ),

            _infoRow(
              'Citizen',
              _complaint!
                  .citizenName,
            ),

            _infoRow(
              'Assigned Authority',
              _complaint!
                  .assignedAuthorityName,
            ),

            if (_complaint!
                .rejectionReason !=
                null)
              _infoRow(
                'Rejection Reason',
                _complaint!
                    .rejectionReason,
              ),

            if (_complaint!
                .resolutionNote !=
                null)
              _infoRow(
                'Resolution Note',
                _complaint!
                    .resolutionNote,
              ),

            const Divider(),

            _infoRow(
              'Created',
              _complaint!
                  .createdAt
                  ?.toLocal()
                  .toString(),
            ),

            _infoRow(
              'Verified',
              _complaint!
                  .verifiedAt
                  ?.toLocal()
                  .toString(),
            ),

            _infoRow(
              'Resolved',
              _complaint!
                  .resolvedAt
                  ?.toLocal()
                  .toString(),
            ),

            // ======================================
            // ACTION LOADING
            // ======================================

            if (_isActionLoading) ...[
              const SizedBox(
                height: 16,
              ),

              const Center(
                child:
                CircularProgressIndicator(),
              ),
            ],

            // ======================================
            // ACTION BUTTONS
            // ======================================

            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
}