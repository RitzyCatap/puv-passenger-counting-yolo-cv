import 'package:material_ui/material_ui.dart';

import '../../constants/app_colors.dart';
import '../../models/operator_model.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/session_manager.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  final AuthService _authService = AuthService();

  final SessionManager _session = SessionManager.instance;

  List<OperatorModel> _operators = [];

  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadOperators();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _authService.dispose();
    super.dispose();
  }

  Future<void> _loadOperators() async {
    if (_loading) return;

    final token = _session.accessToken;

    if (!_session.isAdmin || token == null) {
      setState(() {
        _operators = [];
        _loadError = 'Administrator access is required.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final result = await _authService.getOperators(token);

      if (!mounted || _session.accessToken != token) {
        return;
      }

      setState(() {
        _operators = result;
      });
    } on ApiException catch (error) {
      if (!mounted || _session.accessToken != token) {
        return;
      }

      if (error.statusCode == 401) {
        _session.clearSession();
      }

      if (!mounted) return;

      setState(() {
        _operators = [];
        _loadError = error.message;
      });
    } catch (_) {
      if (!mounted || _session.accessToken != token) {
        return;
      }

      setState(() {
        _operators = [];
        _loadError = 'Unable to load operator accounts.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openRegistrationDialog() async {
    if (!_session.isAdmin) return;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const _RegisterOperatorDialog();
      },
    );

    if (!mounted) return;

    if (created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operator account created successfully.')),
      );

      await _loadOperators();
    }
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
                  'Registered operators',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'View registered operator accounts in SakaySense.',
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

                    enabled: !_loading,
                    onChanged: (_) => setState(() {}),

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

          _buildOperatorRecords(isMobile),
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
  // OPERATOR RECORDS
  // ==========================================================

  Widget _buildOperatorRecords(bool isMobile) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return _buildListMessage(
        icon: Icons.error_outline,
        message: _loadError!,
        retry: true,
      );
    }

    final query = _searchController.text.trim().toLowerCase();

    final filtered = _operators.where((operator) {
      return operator.user.fullName.toLowerCase().contains(query) ||
          operator.user.email.toLowerCase().contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return _buildListMessage(
        icon: Icons.people_outline,
        message: _operators.isEmpty
            ? 'No operator accounts registered yet.'
            : 'No matching operator accounts.',
      );
    }

    return Column(
      children: [
        for (final operator in filtered) _buildOperatorRow(operator, isMobile),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Showing ${filtered.length} '
                  'of ${_operators.length} operators',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),

              IconButton(
                tooltip: 'Refresh operator list',
                onPressed: _loadOperators,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListMessage({
    required IconData icon,
    required String message,
    bool retry = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 45),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 42, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            if (retry)
              AppButton(
                label: 'Try again',
                icon: Icons.refresh,
                type: AppButtonType.secondary,
                onPressed: _loadOperators,
              )
            else if (_operators.isEmpty)
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

  Widget _buildOperatorRow(OperatorModel operator, bool isMobile) {
    final user = operator.user;

    const style = TextStyle(fontSize: 13, color: AppColors.textPrimary);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(user.email, style: style),
                const SizedBox(height: 8),
                Text('Operator | ${operator.registrationDate}', style: style),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: Text(user.fullName, style: style)),
                Expanded(flex: 4, child: Text(user.email, style: style)),
                const Expanded(flex: 2, child: Text('Operator', style: style)),
                Expanded(
                  flex: 2,
                  child: Text(operator.registrationDate, style: style),
                ),
              ],
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

  final AuthService _registrationService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _registrationService.dispose();
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

    if (value.length > 128) {
      return 'Password must not exceed 128 characters.';
    }

    if (value.trim().isEmpty) {
      return 'Password cannot contain only spaces.';
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
  // Registers operators using the authenticated API.
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

    final manager = SessionManager.instance;
    final token = manager.accessToken;

    if (!manager.isAdmin || token == null) {
      setState(() {
        _errorMessage = 'Administrator access is required.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _registrationService.createOperator(
        accessToken: token,
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted || manager.accessToken != token) {
        return;
      }

      _passwordController.clear();
      _confirmPasswordController.clear();

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;

      if (manager.accessToken != token) return;

      if (error.statusCode == 401) {
        Navigator.of(context).pop();
        manager.clearSession();
        return;
      }

      setState(() {
        _errorMessage = error.statusCode == 409
            ? 'This email address is already registered.'
            : error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to register the operator.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                    'Use 8 to 128 characters.',
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
