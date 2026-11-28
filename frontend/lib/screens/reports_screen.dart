import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _selectedDateRange;

  // ==========================================================
  // DATE FORMATTER
  // ==========================================================

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$month/$day/${date.year}';
  }

  String get _dateRangeLabel {
    if (_selectedDateRange == null) {
      return 'All dates';
    }

    return '${_formatDate(_selectedDateRange!.start)} - '
        '${_formatDate(_selectedDateRange!.end)}';
  }

  // ==========================================================
  // DATE RANGE SELECTION
  // ==========================================================

  Future<void> _selectDateRange() async {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      initialDateRange: _selectedDateRange,
      helpText: 'Select report date range',
      saveText: 'Apply',
    );

    if (!mounted || result == null) return;

    setState(() {
      _selectedDateRange = result;
    });
  }

  void _resetDateRange() {
    setState(() {
      _selectedDateRange = null;
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

              _buildDateFilterPanel(),

              const SizedBox(height: 24),

              _buildInformationNotice(),

              const SizedBox(height: 24),

              _buildStatistics(),

              const SizedBox(height: 24),

              _buildPassengerTrends(),

              const SizedBox(height: 24),

              _buildAdditionalReports(),

              const SizedBox(height: 24),

              _buildProcessingDetails(),

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
          'Reports and summary',
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Review passenger counting statistics, processing '
          'performance, and available vehicle reports.',
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
  // DATE FILTER PANEL
  // ==========================================================

  Widget _buildDateFilterPanel() {
    return _ReportPanel(
      title: 'Report period',
      description: 'Select the date range for report summaries.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 580;

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateSelector(),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: _buildResetButton(),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: _buildDateSelector()),

                  const SizedBox(width: 14),

                  _buildResetButton(),
                ],
              );
            },
          ),

          if (_selectedDateRange != null) ...[
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    size: 20,
                    color: AppColors.info,
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Report period selected. Statistics will '
                      'reflect the selected dates once the '
                      'reports API is connected.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // DATE SELECTOR
  // ==========================================================

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDateRange,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: AppColors.primary,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                _dateRangeLabel,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.keyboard_arrow_down,
              size: 21,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // RESET DATE FILTER
  // ==========================================================

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: _selectedDateRange == null ? null : _resetDateRange,
      icon: const Icon(Icons.restart_alt, size: 18),
      label: const Text('Reset period'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
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
          Icon(Icons.info_outline, size: 24, color: AppColors.primary),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Passenger counting analytics',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Reports summarize recorded image-based '
                  'passenger counts. Passenger totals and '
                  'averages will be based on successfully '
                  'completed counting records.',
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
  // SUMMARY STATISTICS
  // ==========================================================

  Widget _buildStatistics() {
    const spacing = 14.0;

    const cards = [
      _ReportStatisticCard(
        title: 'Total passengers',
        description: 'Across completed counts',
        icon: Icons.people_outline,
        iconColor: AppColors.primary,
        iconBackground: AppColors.primaryLight,
      ),

      _ReportStatisticCard(
        title: 'Counting records',
        description: 'All processing records',
        icon: Icons.description_outlined,
        iconColor: AppColors.info,
        iconBackground: AppColors.infoLight,
      ),

      _ReportStatisticCard(
        title: 'Average passengers',
        description: 'Per completed count',
        icon: Icons.bar_chart,
        iconColor: AppColors.primary,
        iconBackground: AppColors.primaryLight,
      ),

      _ReportStatisticCard(
        title: 'Completed counts',
        description: 'Successfully processed',
        icon: Icons.check_circle_outline,
        iconColor: AppColors.success,
        iconBackground: AppColors.successLight,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = width >= 1100
            ? 4
            : width >= 600
            ? 2
            : 1;

        final cardWidth = (width - spacing * (columns - 1)) / columns;

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
  // PASSENGER COUNTING TRENDS
  // ==========================================================

  Widget _buildPassengerTrends() {
    return _ReportPanel(
      title: 'Passenger counting trends',
      description: 'Passenger counts over the selected report period.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _ChartLegend(
                color: AppColors.chartGreen,
                label: 'Passengers counted',
              ),

              _ChartLegend(
                color: AppColors.chartSage,
                label: 'Counting records',
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            height: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _EmptyChartPainter()),

                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.show_chart,
                          color: AppColors.textMuted,
                          size: 30,
                        ),

                        SizedBox(height: 10),

                        Text(
                          'Chart data unavailable',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        SizedBox(height: 6),

                        Text(
                          'Awaiting backend connection',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Trend data will appear when completed counting '
            'records become available.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ADDITIONAL REPORTS
  // ==========================================================

  Widget _buildAdditionalReports() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;

        if (isCompact) {
          return Column(
            children: [
              _buildVehicleReport(),

              const SizedBox(height: 20),

              _buildProcessingReport(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildVehicleReport()),

            const SizedBox(width: 20),

            Expanded(child: _buildProcessingReport()),
          ],
        );
      },
    );
  }

  // ==========================================================
  // PASSENGERS BY PUV TYPE
  // ==========================================================

  Widget _buildVehicleReport() {
    return _ReportPanel(
      title: 'Passengers by PUV type',
      description: 'Passenger count distribution by vehicle type.',
      child: const Column(
        children: [
          _ReportEmptyState(
            icon: Icons.directions_bus_outlined,
            title: 'Vehicle data unavailable',
            description:
                'Vehicle-based passenger statistics will '
                'appear when counting records with assigned '
                'vehicles are available.',
          ),

          SizedBox(height: 16),

          Divider(color: AppColors.border),

          SizedBox(height: 14),

          _ReportDetailRow(label: 'Vehicle types with records'),

          SizedBox(height: 12),

          _ReportDetailRow(label: 'Records with assigned vehicles'),

          SizedBox(height: 12),

          _ReportDetailRow(label: 'Records without assigned vehicles'),
        ],
      ),
    );
  }

  // ==========================================================
  // PROCESSING SUMMARY
  // ==========================================================

  Widget _buildProcessingReport() {
    return _ReportPanel(
      title: 'Processing summary',
      description: 'Distribution of counting record statuses.',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportEmptyState(
            icon: Icons.pie_chart_outline,
            title: 'Processing data unavailable',
            description:
                'Processing status distribution will '
                'appear once the reports API is connected.',
          ),

          SizedBox(height: 16),

          Divider(color: AppColors.border),

          SizedBox(height: 14),

          _ProcessingStatusRow(label: 'Completed', color: AppColors.success),

          SizedBox(height: 14),

          _ProcessingStatusRow(label: 'Processing', color: AppColors.info),

          SizedBox(height: 14),

          _ProcessingStatusRow(label: 'Pending', color: AppColors.warning),

          SizedBox(height: 14),

          _ProcessingStatusRow(label: 'Failed', color: AppColors.error),
        ],
      ),
    );
  }

  // ==========================================================
  // PROCESSING DETAILS
  // ==========================================================

  Widget _buildProcessingDetails() {
    return _ReportPanel(
      title: 'Processing performance',
      description: 'Summary of passenger detection processing results.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 14.0;

              final columns = constraints.maxWidth >= 700 ? 2 : 1;

              final cardWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              const items = [
                _PerformanceCard(
                  title: 'Completion rate',
                  description:
                      'Completed records as a percentage '
                      'of all counting records.',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),

                _PerformanceCard(
                  title: 'Failed processing rate',
                  description:
                      'Failed records as a percentage '
                      'of all counting records.',
                  icon: Icons.error_outline,
                  color: AppColors.error,
                ),

                _PerformanceCard(
                  title: 'Average confidence threshold',
                  description:
                      'Mean confidence threshold used '
                      'for completed counting records.',
                  icon: Icons.tune,
                  color: AppColors.primary,
                ),

                _PerformanceCard(
                  title: 'Average detection confidence',
                  description:
                      'Mean confidence of detected persons '
                      'in completed records.',
                  icon: Icons.center_focus_strong,
                  color: AppColors.info,
                ),
              ];

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: items.map((item) {
                  return SizedBox(width: cardWidth, child: item);
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 19, color: AppColors.warning),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Report statistics are currently unavailable. '
                    'Values will be calculated using actual '
                    'counting and detection records after '
                    'backend integration.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.warning,
                    ),
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

// ============================================================
// REUSABLE REPORT PANEL
// ============================================================

class _ReportPanel extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _ReportPanel({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          child,
        ],
      ),
    );
  }
}

// ============================================================
// SUMMARY STATISTIC CARD
// ============================================================

class _ReportStatisticCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _ReportStatisticCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),

              const Spacer(),

              const Icon(
                Icons.more_horiz,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            '\u2014',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),

          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CHART LEGEND
// ============================================================

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        const SizedBox(width: 7),

        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// EMPTY CHART PAINTER
//
// Draws the chart framework only.
// No fabricated passenger statistics are displayed.
// ============================================================

class _EmptyChartPainter extends CustomPainter {
  const _EmptyChartPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 40 || size.height < 40) return;

    const left = 12.0;
    const top = 12.0;

    final right = size.width - 12;
    final bottom = size.height - 12;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = AppColors.sidebarMuted
      ..strokeWidth = 1;

    const horizontalLines = 5;

    final availableHeight = bottom - top;

    for (int i = 0; i <= horizontalLines; i++) {
      final y = top + availableHeight / horizontalLines * i;

      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    const verticalLines = 6;

    final availableWidth = right - left;

    for (int i = 0; i <= verticalLines; i++) {
      final x = left + availableWidth / verticalLines * i;

      canvas.drawLine(Offset(x, top), Offset(x, bottom), gridPaint);
    }

    canvas.drawLine(const Offset(left, top), Offset(left, bottom), axisPaint);

    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), axisPaint);
  }

  @override
  bool shouldRepaint(covariant _EmptyChartPainter oldDelegate) {
    return false;
  }
}

// ============================================================
// REPORT EMPTY STATE
// ============================================================

class _ReportEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ReportEmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 210),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: AppColors.primary),
          ),

          const SizedBox(height: 16),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REPORT DETAIL ROW
// ============================================================

class _ReportDetailRow extends StatelessWidget {
  final String label;

  const _ReportDetailRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        const SizedBox(width: 12),

        const Text(
          '\u2014',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PROCESSING STATUS ROW
// ============================================================

class _ProcessingStatusRow extends StatelessWidget {
  final String label;
  final Color color;

  const _ProcessingStatusRow({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        const Text(
          '\u2014',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PERFORMANCE STATISTIC CARD
// ============================================================

class _PerformanceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _PerformanceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 155),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: color),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Text(
            '\u2014',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
