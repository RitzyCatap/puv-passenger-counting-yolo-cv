import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';

// ============================================================
// DETECTION STATUS
// ============================================================

enum DetectionStatus { idle, processing, completed, failed }

// ============================================================
// DETECTED PERSON MODEL
//
// Bounding box coordinates must use the original image's
// pixel coordinate system.
// ============================================================

class DetectedPerson {
  final double confidence;
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  const DetectedPerson({
    required this.confidence,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });
}

// ============================================================
// PASSENGER DETECTION RESULT MODEL
// ============================================================

class PassengerDetectionResult {
  final Uint8List imageBytes;
  final double imageWidth;
  final double imageHeight;
  final double confidenceThreshold;
  final List<DetectedPerson> detections;

  const PassengerDetectionResult({
    required this.imageBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.confidenceThreshold,
    required this.detections,
  });

  int get passengerCount => detections.length;

  double? get averageConfidence {
    if (detections.isEmpty) return null;

    final total = detections.fold<double>(
      0,
      (sum, detection) => sum + detection.confidence,
    );

    return total / detections.length;
  }
}

// ============================================================
// DETECTION RESULTS WIDGET
// ============================================================

class DetectionResults extends StatelessWidget {
  final DetectionStatus status;
  final PassengerDetectionResult? result;
  final String? errorMessage;

  const DetectionResults({
    super.key,
    this.status = DetectionStatus.idle,
    this.result,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), const Divider(height: 1), _buildContent()],
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Detection results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),

              _buildStatusBadge(),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Review the detected passenger count '
            'and image processing results.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STATUS BADGE
  // ==========================================================

  Widget _buildStatusBadge() {
    String label;
    Color backgroundColor;
    Color foregroundColor;
    IconData icon;

    switch (status) {
      case DetectionStatus.idle:
        label = 'Awaiting image';
        backgroundColor = AppColors.surfaceAlt;
        foregroundColor = AppColors.textSecondary;
        icon = Icons.hourglass_empty;
        break;

      case DetectionStatus.processing:
        label = 'Processing';
        backgroundColor = AppColors.warningLight;
        foregroundColor = AppColors.warning;
        icon = Icons.sync;
        break;

      case DetectionStatus.completed:
        label = 'Completed';
        backgroundColor = AppColors.successLight;
        foregroundColor = AppColors.success;
        icon = Icons.check_circle_outline;
        break;

      case DetectionStatus.failed:
        label = 'Failed';
        backgroundColor = AppColors.errorLight;
        foregroundColor = AppColors.error;
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foregroundColor),

          const SizedBox(width: 6),

          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CONTENT BASED ON DETECTION STATUS
  // ==========================================================

  Widget _buildContent() {
    switch (status) {
      case DetectionStatus.idle:
        return _buildEmptyState();

      case DetectionStatus.processing:
        return _buildProcessingState();

      case DetectionStatus.completed:
        if (result == null) {
          return _buildMessageState(
            icon: Icons.error_outline,
            title: 'Detection data unavailable',
            description: 'The processing result could not be displayed.',
            foregroundColor: AppColors.error,
            backgroundColor: AppColors.errorLight,
          );
        }

        return _buildCompletedState(result!);

      case DetectionStatus.failed:
        return _buildFailedState();
    }
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildEmptyState() {
    return _buildMessageState(
      icon: Icons.analytics_outlined,
      title: 'No detection results yet',
      description:
          'Upload and process an image to view the '
          'detected passenger count and confidence results.',
      foregroundColor: AppColors.primary,
      backgroundColor: AppColors.primaryLight,
    );
  }

  // ==========================================================
  // PROCESSING STATE
  // ==========================================================

  Widget _buildProcessingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 45),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: AppColors.primary,
              ),
            ),

            SizedBox(height: 22),

            Text(
              'Processing image...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: 10),

            Text(
              'Please wait while the passenger '
              'detection process is running.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // FAILED STATE
  // ==========================================================

  Widget _buildFailedState() {
    return _buildMessageState(
      icon: Icons.error_outline,
      title: 'Unable to process image',
      description:
          errorMessage ??
          'Passenger detection could not be completed. '
              'Please try again.',
      foregroundColor: AppColors.error,
      backgroundColor: AppColors.errorLight,
    );
  }

  // ==========================================================
  // REUSABLE MESSAGE STATE
  // ==========================================================

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String description,
    required Color foregroundColor,
    required Color backgroundColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: foregroundColor),
            ),

            const SizedBox(height: 18),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 9),

            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // COMPLETED STATE
  // ==========================================================

  Widget _buildCompletedState(PassengerDetectionResult detectionResult) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatistics(detectionResult),

          const SizedBox(height: 24),

          const Text(
            'Processed image',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Bounding boxes identify detected persons '
            'within the submitted image.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          _buildProcessedImage(detectionResult),

          const SizedBox(height: 14),

          _buildImageLegend(),

          const SizedBox(height: 24),

          const Divider(),

          const SizedBox(height: 20),

          _buildDetectedPersons(detectionResult),
        ],
      ),
    );
  }

  // ==========================================================
  // RESULT STATISTICS
  // ==========================================================

  Widget _buildStatistics(PassengerDetectionResult detectionResult) {
    final averageConfidence = detectionResult.averageConfidence;

    final cards = [
      _ResultStatisticCard(
        title: 'Passenger count',
        value: '${detectionResult.passengerCount}',
        icon: Icons.people_outline,
        iconColor: AppColors.success,
        iconBackground: AppColors.successLight,
      ),

      _ResultStatisticCard(
        title: 'Confidence threshold',
        value: '${(detectionResult.confidenceThreshold * 100).round()}%',
        icon: Icons.tune,
        iconColor: AppColors.primary,
        iconBackground: AppColors.primaryLight,
      ),

      _ResultStatisticCard(
        title: 'Average confidence',
        value: averageConfidence == null
            ? 'N/A'
            : '${(averageConfidence * 100).toStringAsFixed(1)}%',
        icon: Icons.analytics_outlined,
        iconColor: AppColors.info,
        iconBackground: AppColors.infoLight,
      ),

      const _ResultStatisticCard(
        title: 'Processing status',
        value: 'Completed',
        icon: Icons.check_circle_outline,
        iconColor: AppColors.success,
        iconBackground: AppColors.successLight,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        final int columns;

        if (availableWidth >= 900) {
          columns = 4;
        } else if (availableWidth >= 440) {
          columns = 2;
        } else {
          columns = 1;
        }

        const spacing = 14.0;

        final cardWidth =
            (availableWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) {
            return SizedBox(width: cardWidth, child: card);
          }).toList(),
        );
      },
    );
  }

  // ==========================================================
  // PROCESSED IMAGE WITH BOUNDING BOXES
  // ==========================================================

  Widget _buildProcessedImage(PassengerDetectionResult detectionResult) {
    if (!detectionResult.imageWidth.isFinite ||
        !detectionResult.imageHeight.isFinite ||
        detectionResult.imageWidth <= 0 ||
        detectionResult.imageHeight <= 0) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Invalid image dimensions.',
          style: TextStyle(color: AppColors.error),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final displayHeight = constraints.maxWidth < 500 ? 260.0 : 440.0;

        return Container(
          width: double.infinity,
          height: displayHeight,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  detectionResult.imageBytes,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Unable to display the processed image.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textLight),
                        ),
                      ),
                    );
                  },
                ),

                IgnorePointer(
                  child: CustomPaint(
                    painter: _BoundingBoxPainter(
                      imageWidth: detectionResult.imageWidth,
                      imageHeight: detectionResult.imageHeight,
                      detections: detectionResult.detections,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // IMAGE LEGEND
  // ==========================================================

  Widget _buildImageLegend() {
    return const Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.crop_square, size: 20, color: AppColors.success),

            SizedBox(width: 6),

            Text(
              'Detected person',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.percent, size: 17, color: AppColors.textSecondary),

            SizedBox(width: 6),

            Text(
              'Detection confidence',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // DETECTED PERSON LIST
  // ==========================================================

  Widget _buildDetectedPersons(PassengerDetectionResult detectionResult) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detected persons (${detectionResult.passengerCount})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 14),

        if (detectionResult.detections.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.person_search_outlined,
                  size: 32,
                  color: AppColors.textSecondary,
                ),

                SizedBox(height: 12),

                Text(
                  'No persons detected',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'No persons were detected at '
                  'the selected confidence threshold.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 360),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: detectionResult.detections.length,
              separatorBuilder: (context, index) {
                return const Divider(height: 1, color: AppColors.divider);
              },
              itemBuilder: (context, index) {
                final detection = detectionResult.detections[index];

                return _DetectedPersonTile(
                  number: index + 1,
                  confidence: detection.confidence,
                );
              },
            ),
          ),
      ],
    );
  }
}

// ============================================================
// RESULT STATISTIC CARD
// ============================================================

class _ResultStatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _ResultStatisticCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 145),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DETECTED PERSON TILE
// ============================================================

class _DetectedPersonTile extends StatelessWidget {
  final int number;
  final double confidence;

  const _DetectedPersonTile({required this.number, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final safeConfidence = confidence.isFinite
        ? confidence.clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 21,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Person $number',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: safeConfidence,
                    minHeight: 6,
                    color: AppColors.success,
                    backgroundColor: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          Text(
            '${(safeConfidence * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BOUNDING BOX PAINTER
// ============================================================

class _BoundingBoxPainter extends CustomPainter {
  final double imageWidth;
  final double imageHeight;
  final List<DetectedPerson> detections;

  const _BoundingBoxPainter({
    required this.imageWidth,
    required this.imageHeight,
    required this.detections,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth <= 0 ||
        imageHeight <= 0 ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    // Match the BoxFit.contain image scaling.
    final widthScale = size.width / imageWidth;
    final heightScale = size.height / imageHeight;

    final scale = widthScale < heightScale ? widthScale : heightScale;

    final displayedWidth = imageWidth * scale;
    final displayedHeight = imageHeight * scale;

    final offsetX = (size.width - displayedWidth) / 2;

    final offsetY = (size.height - displayedHeight) / 2;

    final imageRect = Rect.fromLTWH(
      offsetX,
      offsetY,
      displayedWidth,
      displayedHeight,
    );

    final boxPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final labelPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.clipRect(imageRect);

    for (int i = 0; i < detections.length; i++) {
      final detection = detections[i];

      if (!detection.x1.isFinite ||
          !detection.y1.isFinite ||
          !detection.x2.isFinite ||
          !detection.y2.isFinite ||
          !detection.confidence.isFinite ||
          detection.x2 <= detection.x1 ||
          detection.y2 <= detection.y1) {
        continue;
      }

      final left = offsetX + detection.x1 * scale;

      final top = offsetY + detection.y1 * scale;

      final right = offsetX + detection.x2 * scale;

      final bottom = offsetY + detection.y2 * scale;

      final rect = Rect.fromLTRB(left, top, right, bottom).intersect(imageRect);

      if (rect.isEmpty) continue;

      canvas.drawRect(rect, boxPaint);

      final confidence = (detection.confidence * 100).toStringAsFixed(0);

      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Person ${i + 1} | $confidence%',
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );

      final maxLabelWidth = imageRect.width - 10;

      if (maxLabelWidth <= 0) continue;

      textPainter.layout(maxWidth: maxLabelWidth);

      final labelWidth = textPainter.width + 10;
      final labelHeight = textPainter.height + 6;

      if (labelHeight > imageRect.height) {
        textPainter.dispose();
        continue;
      }

      final labelLeft = rect.left
          .clamp(imageRect.left, imageRect.right - labelWidth)
          .toDouble();

      final preferredTop = rect.top - labelHeight;

      final labelTop = preferredTop
          .clamp(imageRect.top, imageRect.bottom - labelHeight)
          .toDouble();

      final labelRect = Rect.fromLTWH(
        labelLeft,
        labelTop,
        labelWidth,
        labelHeight,
      );

      canvas.drawRect(labelRect, labelPaint);

      textPainter.paint(canvas, Offset(labelLeft + 5, labelTop + 3));

      textPainter.dispose();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) {
    return oldDelegate.imageWidth != imageWidth ||
        oldDelegate.imageHeight != imageHeight ||
        oldDelegate.detections != detections;
  }
}
