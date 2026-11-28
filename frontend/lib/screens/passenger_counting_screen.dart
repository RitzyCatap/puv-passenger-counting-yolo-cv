import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:file_picker/file_picker.dart';

import '../constants/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/detection_results.dart';

class PassengerCountingScreen extends StatefulWidget {
  const PassengerCountingScreen({super.key});

  @override
  State<PassengerCountingScreen> createState() =>
      _PassengerCountingScreenState();
}

class _PassengerCountingScreenState extends State<PassengerCountingScreen> {
  static const int _maximumFileSize = 10 * 1024 * 1024;

  Uint8List? _imageBytes;
  String? _imageName;
  int? _imageSize;

  double _confidenceThreshold = 0.50;

  bool _isPickingImage = false;
  bool _isProcessing = false;

  String? _errorMessage;
  String? _detectionErrorMessage;

  DetectionStatus _detectionStatus = DetectionStatus.idle;

  // ==========================================================
  // RESET DETECTION RESULTS
  // ==========================================================

  void _resetDetectionResults() {
    _detectionStatus = DetectionStatus.idle;
    _detectionErrorMessage = null;
  }

  // ==========================================================
  // SELECT IMAGE
  // ==========================================================

  Future<void> _pickImage() async {
    if (_isProcessing || _isPickingImage) return;

    setState(() {
      _isPickingImage = true;
      _errorMessage = null;
    });

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (!mounted || file == null) return;

      final extension = file.name.split('.').last.toLowerCase();

      if (!['jpg', 'jpeg', 'png'].contains(extension)) {
        setState(() {
          _errorMessage =
              'Unsupported file format. Please select '
              'a JPG, JPEG, or PNG image.';
        });
        return;
      }

      final fileSize = await file.length();

      if (!mounted) return;

      if (fileSize != null && fileSize > _maximumFileSize) {
        setState(() {
          _errorMessage =
              'The selected image exceeds the '
              'maximum file size of 10 MB.';
        });
        return;
      }

      final bytes = await file.readAsBytes();

      if (!mounted) return;

      if (bytes.isEmpty) {
        setState(() {
          _errorMessage = 'Unable to read the selected image.';
        });
        return;
      }

      if (bytes.length > _maximumFileSize) {
        setState(() {
          _errorMessage =
              'The selected image exceeds the '
              'maximum file size of 10 MB.';
        });
        return;
      }

      // Verify that the selected file is a valid image.
      try {
        final codec = await ui.instantiateImageCodec(bytes);

        try {
          final frame = await codec.getNextFrame();
          frame.image.dispose();
        } finally {
          codec.dispose();
        }
      } catch (_) {
        if (!mounted) return;

        setState(() {
          _errorMessage = 'The selected file is not a valid image.';
        });
        return;
      }

      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
        _imageSize = bytes.length;
        _errorMessage = null;

        _resetDetectionResults();
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to select the image. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  // ==========================================================
  // REMOVE SELECTED IMAGE
  // ==========================================================

  void _removeImage() {
    if (_isProcessing || _isPickingImage) return;

    setState(() {
      _imageBytes = null;
      _imageName = null;
      _imageSize = null;
      _errorMessage = null;

      _resetDetectionResults();
    });
  }

  // ==========================================================
  // FILE SIZE FORMATTER
  // ==========================================================

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '$bytes B';
  }

  // ==========================================================
  // PROCESS IMAGE
  //
  // Temporary frontend-only implementation.
  // Actual detection requires the YOLO backend API.
  // ==========================================================

  Future<void> _processImage() async {
    if (_isProcessing || _isPickingImage) return;

    if (_imageBytes == null) {
      setState(() {
        _errorMessage = 'Please select an image before processing.';
      });

      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _detectionErrorMessage = null;

      _detectionStatus = DetectionStatus.processing;
    });

    // Temporary delay for frontend state testing.
    // Replace with the actual backend request later.
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    setState(() {
      _isProcessing = false;

      _detectionStatus = DetectionStatus.failed;

      _detectionErrorMessage =
          'Passenger detection is not connected to '
          'the backend yet. No counting record '
          'has been created.';
    });
  }

  // ==========================================================
  // RESET SETTINGS
  // ==========================================================

  void _resetSettings() {
    if (_isProcessing || _isPickingImage) return;

    setState(() {
      _confidenceThreshold = 0.50;
      _errorMessage = null;

      _resetDetectionResults();
    });
  }

  // ==========================================================
  // MAIN SCREEN
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 760;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 28),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeading(isMobile),

              const SizedBox(height: 24),

              _buildInformationNotice(),

              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                _buildErrorMessage(),
                const SizedBox(height: 24),
              ],

              if (isMobile)
                Column(
                  children: [
                    _buildImagePanel(),

                    const SizedBox(height: 20),

                    _buildSettingsPanel(),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _buildImagePanel()),

                    const SizedBox(width: 20),

                    Expanded(flex: 5, child: _buildSettingsPanel()),
                  ],
                ),

              const SizedBox(height: 24),

              _buildResultsPanel(),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // PAGE HEADING
  // ==========================================================

  Widget _buildPageHeading(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passenger counting',
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Upload a still image to detect and count '
          'visible passengers using computer vision.',
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // INFORMATION NOTICE
  // ==========================================================

  Widget _buildInformationNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 24),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image-based passenger detection',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Use a clear photograph of the vehicle '
                  'interior. This system supports '
                  'still images only, not video files '
                  'or live camera feeds.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // IMAGE UPLOAD PANEL
  // ==========================================================

  Widget _buildImagePanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Image upload',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Select an image for passenger detection.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 22),

          if (_imageBytes == null) _buildUploadArea() else _buildImagePreview(),

          const SizedBox(height: 20),

          const Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _UploadRequirement(
                icon: Icons.image_outlined,
                text: 'JPG, JPEG, PNG',
              ),

              _UploadRequirement(
                icon: Icons.storage_outlined,
                text: 'Maximum 10 MB',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EMPTY IMAGE UPLOAD AREA
  // ==========================================================

  Widget _buildUploadArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 38),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.sidebarMuted),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.cloud_upload_outlined,
              size: 36,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Upload passenger image',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Select a photograph from your device '
            'to begin the counting process.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 22),

          AppButton(
            label: 'Browse files',
            icon: Icons.folder_open,
            isLoading: _isPickingImage,
            onPressed: _pickImage,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SELECTED IMAGE PREVIEW
  // ==========================================================

  Widget _buildImagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 290,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _imageBytes!,
              fit: BoxFit.contain,

              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Unable to display this image. '
                      'Please replace it with a valid image.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.image_outlined,
                color: AppColors.primary,
                size: 25,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _imageName ?? 'Selected image',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _formatFileSize(_imageSize ?? 0),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            AppButton(
              label: 'Replace image',
              icon: Icons.refresh,
              type: AppButtonType.secondary,
              isLoading: _isPickingImage,
              onPressed: _isProcessing ? null : _pickImage,
            ),

            OutlinedButton.icon(
              onPressed: _isProcessing || _isPickingImage ? null : _removeImage,

              icon: const Icon(Icons.delete_outline, size: 18),

              label: const Text('Remove'),

              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.border),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // DETECTION SETTINGS PANEL
  // ==========================================================

  Widget _buildSettingsPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detection settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Configure the passenger detection process.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 26),

          _buildPuvSelector(),

          const SizedBox(height: 26),

          const Divider(),

          const SizedBox(height: 24),

          _buildConfidenceSlider(),

          const SizedBox(height: 22),

          const Divider(),

          const SizedBox(height: 22),

          AppButton(
            label: 'Process image',
            icon: Icons.center_focus_strong,
            fullWidth: true,
            isLoading: _isProcessing,
            onPressed: _imageBytes == null || _isPickingImage || _isProcessing
                ? null
                : _processImage,
          ),

          const SizedBox(height: 10),

          AppButton(
            label: 'Reset settings',
            icon: Icons.restart_alt,
            type: AppButtonType.secondary,
            fullWidth: true,
            onPressed: _isProcessing || _isPickingImage ? null : _resetSettings,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // OPTIONAL PUV SELECTION
  // ==========================================================

  Widget _buildPuvSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select PUV (optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 9),

        const TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: 'No vehicle selected',
            prefixIcon: Icon(Icons.directions_bus_outlined, size: 20),
            suffixIcon: Icon(Icons.keyboard_arrow_down),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Registered vehicles will become selectable '
          'after the vehicle API is connected.',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // CONFIDENCE THRESHOLD SLIDER
  // ==========================================================

  Widget _buildConfidenceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Confidence threshold',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${(_confidenceThreshold * 100).round()}%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Slider(
          value: _confidenceThreshold,
          min: 0.0,
          max: 1.0,
          divisions: 100,

          label: '${(_confidenceThreshold * 100).round()}%',

          activeColor: AppColors.primary,
          inactiveColor: AppColors.primaryLight,

          onChanged: _isProcessing || _isPickingImage
              ? null
              : (value) {
                  setState(() {
                    _confidenceThreshold = value;
                    _errorMessage = null;

                    _resetDetectionResults();
                  });
                },
        ),

        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0%',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),

            Text(
              '100%',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),

        const SizedBox(height: 14),

        const Text(
          'Higher confidence thresholds generally '
          'filter out uncertain detections but may '
          'also miss some visible passengers.',
          style: TextStyle(
            fontSize: 12,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.tune, size: 18, color: AppColors.primary),

              SizedBox(width: 9),

              Expanded(
                child: Text(
                  'Default confidence threshold: 50%',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // DETECTION RESULTS PANEL
  //
  // Connected to the reusable DetectionResults widget.
  // Actual completed results will come from the YOLO API.
  // ==========================================================

  Widget _buildResultsPanel() {
    return DetectionResults(
      status: _detectionStatus,
      errorMessage: _detectionErrorMessage,
    );
  }

  // ==========================================================
  // ERROR MESSAGE
  // ==========================================================

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 21, color: AppColors.error),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.error,
              ),
            ),
          ),

          const SizedBox(width: 8),

          InkWell(
            onTap: () {
              setState(() {
                _errorMessage = null;
              });
            },
            child: const Icon(Icons.close, size: 19, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// UPLOAD REQUIREMENT COMPONENT
// ============================================================

class _UploadRequirement extends StatelessWidget {
  final IconData icon;
  final String text;

  const _UploadRequirement({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),

        const SizedBox(width: 7),

        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
