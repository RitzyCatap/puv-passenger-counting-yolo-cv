import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';
import '../widgets/dashboard_layout.dart';

class DashboardOverview extends StatelessWidget {
  final DashboardRole role;
  final ValueChanged<DashboardSection> onSectionChanged;
  final VoidCallback onStartCounting;

  const DashboardOverview({
    super.key,
    required this.role,
    required this.onSectionChanged,
    required this.onStartCounting,
  });

  bool get isAdmin => role == DashboardRole.admin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width < 600 ? 16.0 : 28.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeading(width),

              const SizedBox(height: 28),

              _buildStatistics(width),

              const SizedBox(height: 26),

              _buildActivityAndActions(width),

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

  Widget _buildPageHeading(double width) {
    final isMobile = width < 600;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 16,
      spacing: 16,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? width - 32 : 430,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard overview',
                style: TextStyle(
                  fontSize: isMobile ? 23 : 27,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.7,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Monitor passenger counting activity and system records.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        ElevatedButton.icon(
          onPressed: onStartCounting,
          icon: const Icon(Icons.add, size: 19),
          label: const Text('New passenger count'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textLight,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // RESPONSIVE STATISTICS
  // ==========================================================

  Widget _buildStatistics(double width) {
    final columns = width >= 1100
        ? 4
        : width >= 600
            ? 2
            : 1;

    const spacing = 14.0;

    const cards = [
      _StatisticCard(
        title: 'Counting records',
        description: 'Total processed records',
        icon: Icons.description_outlined,
      ),

      _StatisticCard(
        title: 'Passengers counted',
        description: 'Across completed records',
        icon: Icons.people_outline,
      ),

      _StatisticCard(
        title: 'Registered PUVs',
        description: 'Vehicles in the system',
        icon: Icons.directions_bus_outlined,
      ),

      _StatisticCard(
        title: 'Completed counts',
        description: 'Successfully processed',
        icon: Icons.check_circle_outline,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        final cardWidth =
            (availableWidth - (spacing * (columns - 1))) /
                columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) {
            return SizedBox(
              width: cardWidth,
              child: card,
            );
          }).toList(),
        );
      },
    );
  }

  // ==========================================================
  // RECENT ACTIVITY AND QUICK ACTIONS
  // ==========================================================

  Widget _buildActivityAndActions(double width) {
    final isMobile = width < 760;

    final activity = Expanded(
      flex: 7,
      child: _buildRecentActivity(),
    );

    final actions = Expanded(
      flex: 4,
      child: _buildQuickActions(),
    );

    if (isMobile) {
      return Column(
        children: [
          _buildRecentActivity(),
          const SizedBox(height: 18),
          _buildQuickActions(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        activity,
        const SizedBox(width: 18),
        actions,
      ],
    );
  }

  // ==========================================================
  // RECENT COUNTING ACTIVITY
  // ==========================================================

  Widget _buildRecentActivity() {
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
            'Recent counting activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Your latest passenger counting records',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 20),

          const Divider(color: AppColors.border),

          const SizedBox(height: 28),

          Center(
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insert_chart_outlined,
                    size: 27,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Counting activity unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Records will appear when the API is connected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 20),

                OutlinedButton.icon(
                  onPressed: onStartCounting,
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    size: 17,
                  ),
                  label: const Text('Start counting'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================================
  // QUICK ACTIONS
  // ==========================================================

  Widget _buildQuickActions() {
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
            'Quick actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Access workspace tools',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 18),

          _QuickAction(
            icon: Icons.center_focus_strong,
            label: 'Passenger counting',
            onTap: () {
              onSectionChanged(
                DashboardSection.passengerCounting,
              );
            },
          ),

          _QuickAction(
            icon: Icons.directions_bus_outlined,
            label: 'PUV information',
            onTap: () {
              onSectionChanged(
                DashboardSection.puvManagement,
              );
            },
          ),

          _QuickAction(
            icon: Icons.history,
            label: 'Counting history',
            onTap: () {
              onSectionChanged(
                DashboardSection.countingHistory,
              );
            },
          ),

          _QuickAction(
            icon: Icons.analytics_outlined,
            label: 'View reports',
            onTap: () {
              onSectionChanged(
                DashboardSection.reports,
              );
            },
          ),

          if (isAdmin) ...[
            _QuickAction(
              icon: Icons.manage_accounts_outlined,
              label: 'User management',
              onTap: () {
                onSectionChanged(
                  DashboardSection.userManagement,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// STATISTIC CARD
// ============================================================

class _StatisticCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _StatisticCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 170,
      ),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),

              const Spacer(),

              const Icon(
                Icons.more_horiz,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QUICK ACTION ITEM
// ============================================================

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: AppColors.primary,
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 13,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}