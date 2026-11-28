import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';
import 'brand_logo.dart';

enum DashboardRole { admin, operator }

enum DashboardSection {
  overview,
  passengerCounting,
  puvManagement,
  countingHistory,
  reports,
  userManagement,
}

class DashboardLayout extends StatelessWidget {
  final DashboardRole role;
  final String userName;
  final DashboardSection selectedSection;
  final ValueChanged<DashboardSection> onSectionChanged;
  final VoidCallback onLogout;
  final Widget child;

  const DashboardLayout({
    super.key,
    required this.role,
    required this.userName,
    required this.selectedSection,
    required this.onSectionChanged,
    required this.onLogout,
    required this.child,
  });

  bool get _isAdmin => role == DashboardRole.admin;

  String get _roleLabel => _isAdmin ? 'Administrator' : 'Operator';

  String _sectionTitle(DashboardSection section) {
    switch (section) {
      case DashboardSection.overview:
        return 'Overview';

      case DashboardSection.passengerCounting:
        return 'Passenger counting';

      case DashboardSection.puvManagement:
        return _isAdmin ? 'PUV management' : 'PUV information';

      case DashboardSection.countingHistory:
        return 'Counting history';

      case DashboardSection.reports:
        return 'Reports';

      case DashboardSection.userManagement:
        return 'User management';
    }
  }

  // ==========================================================
  // MAIN DASHBOARD LAYOUT
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Scaffold(
          backgroundColor: AppColors.background,

          drawer: isMobile
              ? Drawer(
                  width: 280,
                  backgroundColor: AppColors.sidebar,
                  child: _buildSidebar(context, isMobile: true),
                )
              : null,

          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, bodyConstraints) {
                // Prevent RenderFlex overflow when the browser
                // viewport temporarily becomes extremely small
                // during resizing or mobile simulation.
                if (bodyConstraints.maxWidth < 200 ||
                    bodyConstraints.maxHeight < 100) {
                  return const SizedBox.expand();
                }

                return Row(
                  children: [
                    if (!isMobile)
                      SizedBox(
                        width: 256,
                        child: _buildSidebar(context, isMobile: false),
                      ),

                    Expanded(
                      child: Column(
                        children: [
                          _buildHeader(isMobile),

                          Expanded(child: child),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // DASHBOARD HEADER
  // ==========================================================

  Widget _buildHeader(bool isMobile) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            Builder(
              builder: (context) {
                return IconButton(
                  tooltip: 'Open navigation',
                  icon: const Icon(Icons.menu, color: AppColors.primary),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),

            const SizedBox(width: 8),
          ],

          Expanded(
            child: Text(
              _sectionTitle(selectedSection),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          const SizedBox(width: 12),

          if (!isMobile) ...[
            Text(
              '$_roleLabel workspace',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(width: 20),
          ],

          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isAdmin
                  ? Icons.admin_panel_settings_outlined
                  : Icons.person_outline,
              size: 22,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DASHBOARD SIDEBAR
  // ==========================================================

  Widget _buildSidebar(BuildContext context, {required bool isMobile}) {
    return Container(
      color: AppColors.sidebar,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Avoid rendering sidebar elements when the
            // available viewport becomes extremely narrow.
            if (constraints.maxWidth < 200 || constraints.maxHeight < 100) {
              return const SizedBox.expand();
            }

            // Allow the complete sidebar to scroll on
            // short screens instead of overflowing.
            if (constraints.maxHeight < 450) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSidebarLogo(),

                    _buildNavigationItems(context, isMobile: isMobile),

                    _buildSidebarFooter(context, isMobile: isMobile),
                  ],
                ),
              );
            }

            // Preserve the normal sidebar layout.
            return Column(
              children: [
                _buildSidebarLogo(),

                Expanded(
                  child: SingleChildScrollView(
                    child: _buildNavigationItems(context, isMobile: isMobile),
                  ),
                ),

                _buildSidebarFooter(context, isMobile: isMobile),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // SIDEBAR LOGO
  // ==========================================================

  Widget _buildSidebarLogo() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: BrandLogo(darkBackground: true, showTagline: false, size: 42),
    );
  }

  // ==========================================================
  // SIDEBAR NAVIGATION ITEMS
  // ==========================================================

  Widget _buildNavigationItems(BuildContext context, {required bool isMobile}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupLabel('WORKSPACE'),

          _buildNavItem(
            context: context,
            section: DashboardSection.overview,
            icon: Icons.dashboard_outlined,
            isMobile: isMobile,
          ),

          _buildNavItem(
            context: context,
            section: DashboardSection.passengerCounting,
            icon: Icons.center_focus_strong,
            isMobile: isMobile,
          ),

          _buildNavItem(
            context: context,
            section: DashboardSection.puvManagement,
            icon: Icons.directions_bus_outlined,
            isMobile: isMobile,
          ),

          _buildNavItem(
            context: context,
            section: DashboardSection.countingHistory,
            icon: Icons.history,
            isMobile: isMobile,
          ),

          _buildNavItem(
            context: context,
            section: DashboardSection.reports,
            icon: Icons.analytics_outlined,
            isMobile: isMobile,
          ),

          if (_isAdmin) ...[
            const SizedBox(height: 26),

            _buildGroupLabel('ADMINISTRATION'),

            _buildNavItem(
              context: context,
              section: DashboardSection.userManagement,
              icon: Icons.manage_accounts_outlined,
              isMobile: isMobile,
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==========================================================
  // SIDEBAR GROUP LABEL
  // ==========================================================

  Widget _buildGroupLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
          color: AppColors.sidebarMuted,
        ),
      ),
    );
  }

  // ==========================================================
  // SIDEBAR NAVIGATION ITEM
  // ==========================================================

  Widget _buildNavItem({
    required BuildContext context,
    required DashboardSection section,
    required IconData icon,
    required bool isMobile,
  }) {
    final isSelected = selectedSection == section;

    final foregroundColor = isSelected
        ? AppColors.primary
        : AppColors.sidebarText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: isSelected ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(8),

        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          hoverColor: AppColors.sidebarHover,

          onTap: () {
            if (isMobile) {
              Navigator.of(context).pop();
            }

            onSectionChanged(section);
          },

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 21, color: foregroundColor),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    _sectionTitle(section),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: foregroundColor,
                    ),
                  ),
                ),

                if (isSelected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // USER INFORMATION AND LOGOUT
  // ==========================================================

  Widget _buildSidebarFooter(BuildContext context, {required bool isMobile}) {
    final cleanName = userName.trim();

    final initial = cleanName.isNotEmpty ? cleanName[0].toUpperCase() : 'U';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          const Divider(color: AppColors.sidebarHover),

          const SizedBox(height: 18),

          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.sidebarHover,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cleanName.isEmpty ? _roleLabel : cleanName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _roleLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.sidebarMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),

            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              hoverColor: AppColors.sidebarHover,

              onTap: () {
                if (isMobile) {
                  Navigator.of(context).pop();
                }

                onLogout();
              },

              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: AppColors.sidebarText),

                    SizedBox(width: 12),

                    Text(
                      'Sign out',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.sidebarText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
