import 'package:material_ui/material_ui.dart';

import '../../constants/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // REGISTER OPERATOR DIALOG
  // ==========================================================

  Future<void> _openRegistrationDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return const _RegisterOperatorDialog();
      },
    );
  }

  // ==========================================================
  // MAIN SCREEN
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeading(isMobile),

              const SizedBox(height: 28),

              _buildInformationNotice(),

              const SizedBox(height: 24),

              _buildUsersPanel(isMobile),
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
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 18,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User management',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.7,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Register and manage authorized system users.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          AppButton(
            label: 'Register operator',
            icon: Icons.person_add_outlined,
            onPressed: _openRegistrationDialog,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ADMIN INFORMATION NOTICE
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
          Icon(
            Icons.admin_panel_settings_outlined,
            color: AppColors.primary,
            size: 25,
          ),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Administrator access',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Only authorized administrators can '
                  'register operator accounts. Public '
                  'account registration is not available.',
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
  // REGISTERED USERS PANEL
  // ==========================================================

  Widget _buildUsersPanel(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registered users',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'View authorized accounts in SakaySense.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 22),

                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : 360,
                  ),
                  child: TextField(
                    controller: _searchController,

                    // Enabled when the user-list API is connected.
                    enabled: false,

                    decoration: const InputDecoration(
                      hintText: 'Search by name or email',
                      prefixIcon: Icon(Icons.search, size: 21),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          if (!isMobile) _buildTableHeader(),

          _buildUnavailableState(),
        ],
      ),
    );
  }

  // ==========================================================
  // TABLE HEADER
  // ==========================================================

  Widget _buildTableHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceAlt,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _TableHeading('Full name')),

          Expanded(flex: 4, child: _TableHeading('Email address')),

          Expanded(flex: 2, child: _TableHeading('Role')),

          Expanded(flex: 2, child: _TableHeading('Date registered')),
        ],
      ),
    );
  }

  // ==========================================================
  // UNAVAILABLE STATE
  // ==========================================================

  Widget _buildUnavailableState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 55),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.people_outline,
                color: AppColors.primary,
                size: 32,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'User records unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 9),

            const Text(
              'Registered users will appear here '
              'once the backend API is connected.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 22),

            AppButton(
              label: 'Register operator',
              icon: Icons.person_add_outlined,
              type: AppButtonType.secondary,
              onPressed: _openRegistrationDialog,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TABLE HEADING
// ============================================================

class _TableHeading extends StatelessWidget {
  final String label;

  const _TableHeading(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

// ============================================================
// REGISTER OPERATOR DIALOG
// ============================================================

class _RegisterOperatorDialog extends StatefulWidget {
  const _RegisterOperatorDialog();

  @override
  State<_RegisterOperatorDialog> createState() =>
      _RegisterOperatorDialogState();
}

class _RegisterOperatorDialogState extends State<_RegisterOperatorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ==========================================================
  // FIELD VALIDATION
  // ==========================================================

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the full name.';
    }

    if (value.trim().length > 100) {
      return 'Full name must not exceed 100 characters.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an email address.';
    }

    if (value.trim().length > 150) {
      return 'Email must not exceed 150 characters.';
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }

    if (value.length < 8) {
      return 'Password must contain at least 8 characters.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm the password.';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }

    return null;
  }

  void _clearError(String value) {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  // ==========================================================
  // REGISTRATION HANDLER
  // Frontend validation only until API integration.
  // ==========================================================

  Future<void> _handleRegistration() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      _errorMessage =
          'Registration is not connected to the backend yet. '
          'No account has been created.';
    });
  }

  // ==========================================================
  // DIALOG INTERFACE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: Dialog(
        backgroundColor: AppColors.surface,

        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),

          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Form(
              key: _formKey,

              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  _buildDialogHeader(),

                  const SizedBox(height: 24),

                  if (_errorMessage != null) ...[
                    _buildErrorMessage(),

                    const SizedBox(height: 20),
                  ],

                  AppTextField(
                    label: 'Full name',
                    hint: 'Enter full name',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline,
                    validator: _validateName,
                    enabled: !_isLoading,
                    onChanged: _clearError,
                  ),

                  const SizedBox(height: 18),

                  AppTextField(
                    label: 'Email address',
                    hint: 'Enter email address',
                    controller: _emailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    enabled: !_isLoading,
                    onChanged: _clearError,
                  ),

                  const SizedBox(height: 18),

                  AppTextField(
                    label: 'Password',
                    hint: 'Enter password',
                    controller: _passwordController,
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: _validatePassword,
                    enabled: !_isLoading,
                    onChanged: _clearError,
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    'Use at least 8 characters.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 18),

                  AppTextField(
                    label: 'Confirm password',
                    hint: 'Re-enter password',
                    controller: _confirmPasswordController,
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: _validateConfirmPassword,
                    enabled: !_isLoading,
                    onChanged: _clearError,
                  ),

                  const SizedBox(height: 20),

                  _buildRoleInformation(),

                  const SizedBox(height: 24),

                  const Divider(),

                  const SizedBox(height: 20),

                  AppButton(
                    label: 'Register operator',
                    icon: Icons.person_add_outlined,
                    fullWidth: true,
                    isLoading: _isLoading,
                    onPressed: _handleRegistration,
                  ),

                  const SizedBox(height: 10),

                  AppButton(
                    label: 'Cancel',
                    type: AppButtonType.secondary,
                    fullWidth: true,
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DIALOG HEADER
  // ==========================================================

  Widget _buildDialogHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_add_outlined,
                color: AppColors.primary,
                size: 23,
              ),
            ),

            const Spacer(),

            IconButton(
              tooltip: 'Close',
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.of(context).pop();
                    },
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
            ),
          ],
        ),

        const SizedBox(height: 17),

        const Text(
          'Register operator',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Enter the required information to create '
          'an authorized operator account.',
          style: TextStyle(
            fontSize: 13,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // FIXED OPERATOR ROLE
  // ==========================================================

  Widget _buildRoleInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.badge_outlined, color: AppColors.primary, size: 22),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned role: Operator',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'This form creates operator accounts only.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
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
          const Icon(Icons.info_outline, size: 20, color: AppColors.error),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
