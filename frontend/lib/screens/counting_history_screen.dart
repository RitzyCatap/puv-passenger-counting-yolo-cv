import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';

class CountingHistoryScreen extends StatefulWidget {
  const CountingHistoryScreen({super.key});

  @override
  State<CountingHistoryScreen> createState() => _CountingHistoryScreenState();
}

class _CountingHistoryScreenState extends State<CountingHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'All statuses';

  DateTimeRange? _selectedDateRange;

  static const List<String> _statusOptions = [
    'All statuses',
    'Pending',
    'Processing',
    'Completed',
    'Failed',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      return 'Select date range';
    }

    return '${_formatDate(_selectedDateRange!.start)} - '
        '${_formatDate(_selectedDateRange!.end)}';
  }

  // ==========================================================
  // DATE RANGE FILTER
  // ==========================================================

  Future<void> _selectDateRange() async {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      initialDateRange: _selectedDateRange,
      helpText: 'Select counting record dates',
      saveText: 'Apply',
    );

    if (!mounted || result == null) return;

    setState(() {
      _selectedDateRange = result;
    });
  }

  // ==========================================================
  // RESET FILTERS
  // ==========================================================

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = 'All statuses';
      _selectedDateRange = null;
    });
  }

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        _selectedStatus != 'All statuses' ||
        _selectedDateRange != null;
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

              _buildStatistics(),

              const SizedBox(height: 24),

              _buildInformationNotice(),

              const SizedBox(height: 24),

              _buildRecordsPanel(),

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
          'Counting history',
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'View and review previously processed passenger '
          'counting records.',
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
  // HISTORY STATISTICS
  // ==========================================================

  Widget _buildStatistics() {
    const spacing = 14.0;

    const cards = [
      _HistoryStatisticCard(
        title: 'Total records',
        description: 'All counting records',
        icon: Icons.history,
        iconColor: AppColors.primary,
        iconBackground: AppColors.primaryLight,
      ),

      _HistoryStatisticCard(
        title: 'Completed',
        description: 'Successfully processed',
        icon: Icons.check_circle_outline,
        iconColor: AppColors.success,
        iconBackground: AppColors.successLight,
      ),

      _HistoryStatisticCard(
        title: 'Failed',
        description: 'Unsuccessful processing',
        icon: Icons.error_outline,
        iconColor: AppColors.error,
        iconBackground: AppColors.errorLight,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        final columns = availableWidth >= 700 ? 3 : 1;

        final cardWidth = (availableWidth - spacing * (columns - 1)) / columns;

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
                  'Passenger counting records',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Review previous image-based passenger '
                  'counts, detection confidence thresholds, '
                  'processing dates, and record statuses.',
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
  // COUNTING RECORDS PANEL
  // ==========================================================

  Widget _buildRecordsPanel() {
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
            'Counting records',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Search and filter previous passenger '
            'counting records.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          _buildFilters(),

          const SizedBox(height: 20),

          if (_hasActiveFilters) ...[
            _buildActiveFiltersNotice(),

            const SizedBox(height: 20),
          ],

          const Divider(color: AppColors.border),

          const SizedBox(height: 12),

          _buildRecordsTable(),

          _buildUnavailableState(),

          const Divider(color: AppColors.border),

          const SizedBox(height: 12),

          _buildRecordsFooter(),
        ],
      ),
    );
  }

  // ==========================================================
  // RESPONSIVE FILTER LAYOUT
  // ==========================================================

  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 850;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchField(),

              const SizedBox(height: 14),

              _buildStatusFilter(),

              const SizedBox(height: 14),

              _buildDateFilter(),

              const SizedBox(height: 14),

              SizedBox(width: double.infinity, child: _buildResetButton()),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(flex: 4, child: _buildSearchField()),

            const SizedBox(width: 12),

            Expanded(flex: 3, child: _buildStatusFilter()),

            const SizedBox(width: 12),

            Expanded(flex: 4, child: _buildDateFilter()),

            const SizedBox(width: 12),

            _buildResetButton(),
          ],
        );
      },
    );
  }

  // ==========================================================
  // SEARCH FIELD
  // ==========================================================

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FilterLabel(label: 'Search records'),

        const SizedBox(height: 8),

        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: 'Record ID or PUV type',
            prefixIcon: const Icon(Icons.search, size: 21),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                      });
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // PROCESSING STATUS FILTER
  // ==========================================================

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FilterLabel(label: 'Processing status'),

        const SizedBox(height: 8),

        InputDecorator(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.filter_list, size: 20),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // DATE RANGE FILTER
  // ==========================================================

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FilterLabel(label: 'Date range'),

        const SizedBox(height: 8),

        InkWell(
          onTap: _selectDateRange,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 19,
                  color: AppColors.textSecondary,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    _dateRangeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: _selectedDateRange == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // RESET FILTER BUTTON
  // ==========================================================

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: _hasActiveFilters ? _resetFilters : null,
      icon: const Icon(Icons.restart_alt, size: 18),
      label: const Text('Reset filters'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ==========================================================
  // ACTIVE FILTERS NOTICE
  // ==========================================================

  Widget _buildActiveFiltersNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.filter_alt_outlined, size: 19, color: AppColors.info),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'Filters selected. Matching records will become '
              'available once the counting history API is connected.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RECORDS TABLE
  // ==========================================================

  Widget _buildRecordsTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The table will scroll horizontally on small screens
        // to prevent RenderFlex overflow.

        final tableWidth = constraints.maxWidth < 1050
            ? 1050.0
            : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Row(
                children: [
                  _TableHeading(label: 'Record ID', flex: 2),

                  _TableHeading(label: 'PUV type', flex: 3),

                  _TableHeading(label: 'Passengers', flex: 2),

                  _TableHeading(label: 'Threshold', flex: 2),

                  _TableHeading(label: 'Status', flex: 2),

                  _TableHeading(label: 'Processed date', flex: 3),

                  _TableHeading(label: 'Actions', flex: 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // RECORDS UNAVAILABLE STATE
  // ==========================================================

  Widget _buildUnavailableState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.history,
              size: 32,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Counting records unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Previous counting records will appear here '
            'once the backend API is connected.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Awaiting backend connection',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RECORDS TABLE FOOTER
  // ==========================================================

  Widget _buildRecordsFooter() {
    return const Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Text(
          'Record data unavailable',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: null,
              tooltip: 'Previous page',
              icon: Icon(Icons.chevron_left),
            ),

            Text(
              '— / —',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),

            IconButton(
              onPressed: null,
              tooltip: 'Next page',
              icon: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// HISTORY STATISTIC CARD
// ============================================================

class _HistoryStatisticCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _HistoryStatisticCard({
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
                child: Icon(icon, size: 20, color: iconColor),
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
            '—',
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
// FILTER LABEL COMPONENT
// ============================================================

class _FilterLabel extends StatelessWidget {
  final String label;

  const _FilterLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ============================================================
// TABLE HEADING COMPONENT
// ============================================================

class _TableHeading extends StatelessWidget {
  final String label;
  final int flex;

  const _TableHeading({required this.label, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
