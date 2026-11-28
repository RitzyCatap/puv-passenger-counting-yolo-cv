import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../widgets/dashboard_layout.dart';
import '../dashboard_overview.dart';
import '../puv_management_screen.dart';
import '../passenger_counting_screen.dart';
import '../counting_history_screen.dart';
import '../reports_screen.dart';
import 'user_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  DashboardSection _selectedSection = DashboardSection.overview;

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  void _changeSection(DashboardSection section) {
    setState(() {
      _selectedSection = section;
    });
  }

  void _startCounting() {
    _changeSection(DashboardSection.passengerCounting);
  }

  // ==========================================================
  // LOGOUT CONFIRMATION
  // ==========================================================

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.logout, size: 32, color: AppColors.primary),

          title: const Text(
            'Sign out?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          content: const Text(
            'Are you sure you want to sign out '
            'of your SakaySense workspace?',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),

          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      context.go('/login');
    }
  }

  // ==========================================================
  // SECTION CONTENT
  // ==========================================================

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case DashboardSection.overview:
        return DashboardOverview(
          role: DashboardRole.admin,
          onSectionChanged: _changeSection,
          onStartCounting: _startCounting,
        );

      case DashboardSection.passengerCounting:
        return const PassengerCountingScreen();

      case DashboardSection.puvManagement:
        return const PuvManagementScreen(role: DashboardRole.admin);

      case DashboardSection.countingHistory:
        return const CountingHistoryScreen();

      case DashboardSection.reports:
        return const ReportsScreen();

      case DashboardSection.userManagement:
        return const UserManagementScreen();
    }
  }

  // ==========================================================
  // MAIN DASHBOARD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      role: DashboardRole.admin,
      userName: 'Administrator',
      selectedSection: _selectedSection,
      onSectionChanged: _changeSection,
      onLogout: _handleLogout,
      child: _buildSectionContent(),
    );
  }
}
