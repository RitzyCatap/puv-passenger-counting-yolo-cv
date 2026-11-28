import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';
import '../models/puv_model.dart';
import '../models/puv_summary.dart';
import '../services/api_service.dart';
import '../services/puv_service.dart';
import '../services/session_manager.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/dashboard_layout.dart';

class PuvManagementScreen extends StatefulWidget {
  final DashboardRole role;

  const PuvManagementScreen({super.key, required this.role});

  @override
  State<PuvManagementScreen> createState() => _PuvManagementScreenState();
}

class _PuvManagementScreenState extends State<PuvManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  final PuvService _puvService = PuvService();

  final SessionManager _session = SessionManager.instance;

  List<PuvModel> _records = [];

  bool _loading = false;
  bool _hasLoaded = false;
  String? _loadError;

  bool get _isAdmin => widget.role == DashboardRole.admin;

  bool get _canModify => _isAdmin && _session.isAdmin;

  @override
  void initState() {
    super.initState();
    _loadPuvs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _puvService.dispose();
    super.dispose();
  }

  Future<void> _loadPuvs() async {
    if (_loading) return;

    final token = _session.accessToken;

    if (token == null) {
      setState(() {
        _records = [];
        _hasLoaded = false;
        _loadError = 'Authentication is required.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final records = await _puvService.getPuvs(accessToken: token);

      if (!mounted || _session.accessToken != token) {
        return;
      }

      setState(() {
        _records = records;
        _hasLoaded = true;
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
        _records = [];
        _hasLoaded = false;
        _loadError = error.message;
      });
    } catch (_) {
      if (!mounted || _session.accessToken != token) {
        return;
      }

      setState(() {
        _records = [];
        _hasLoaded = false;
        _loadError = 'Unable to load vehicle records.';
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
    await _openVehicleDialog();
  }

  Future<void> _openVehicleDialog({PuvModel? existing}) async {
    if (!_canModify || _loading) return;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _RegisterPuvDialog(existing: existing);
      },
    );

    if (!mounted || saved != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null
              ? 'PUV registered successfully.'
              : 'PUV updated successfully.',
        ),
      ),
    );

    await _loadPuvs();
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

              _buildStatistics(isMobile),

              const SizedBox(height: 24),

              _buildPuvPanel(isMobile),
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
                _isAdmin ? 'PUV management' : 'PUV information',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.7,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _isAdmin
                    ? 'Register and manage public utility vehicles.'
                    : 'View registered public utility vehicles.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          if (_isAdmin)
            AppButton(
              label: 'Register PUV',
              icon: Icons.add,
              onPressed: _canModify && !_loading
                  ? _openRegistrationDialog
                  : null,
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACCESS INFORMATION NOTICE
  // ==========================================================

  Widget _buildInformationNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _isAdmin ? Icons.admin_panel_settings_outlined : Icons.info_outline,
            color: AppColors.primary,
            size: 25,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAdmin ? 'Vehicle administration' : 'View-only access',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  _isAdmin
                      ? 'Administrators can register and update '
                            'public utility vehicle information.'
                      : 'Operators can view registered vehicles '
                            'but cannot create or modify PUV records.',
                  style: const TextStyle(
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

  Widget _buildStatistics(bool isMobile) {
    final summary = PuvSummary.fromRecords(_records);

    final available = _hasLoaded && _loadError == null;

    final cards = [
      _PuvStatisticCard(
        value: available ? summary.registeredCount.toString() : '—',
        title: 'Registered PUVs',
        description: 'Total vehicles in the system',
        icon: Icons.directions_bus_outlined,
      ),

      _PuvStatisticCard(
        value: available ? summary.vehicleTypeCount.toString() : '—',
        title: 'Vehicle types',
        description: 'Registered vehicle categories',
        icon: Icons.category_outlined,
      ),

      _PuvStatisticCard(
        value: available ? summary.totalCapacity.toString() : '—',
        title: 'Total capacity',
        description: 'Combined registered capacity',
        icon: Icons.groups_outlined,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 12),
          cards[1],
          const SizedBox(height: 12),
          cards[2],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 14),
        Expanded(child: cards[1]),
        const SizedBox(width: 14),
        Expanded(child: cards[2]),
      ],
    );
  }

  // ==========================================================
  // REGISTERED PUV PANEL
  // ==========================================================

  Widget _buildPuvPanel(bool isMobile) {
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
                  'Registered vehicles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'View public utility vehicles '
                  'registered in SakaySense.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
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

                    enabled: !_loading && _hasLoaded,
                    onChanged: (_) => setState(() {}),

                    decoration: const InputDecoration(
                      hintText: 'Search by PUV type or ID',
                      prefixIcon: Icon(Icons.search, size: 21),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          if (!isMobile) _buildTableHeader(),

          _buildVehicleRecords(isMobile),
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
      child: Row(
        children: [
          const Expanded(flex: 2, child: _PuvTableHeading('PUV ID')),

          const Expanded(flex: 3, child: _PuvTableHeading('PUV type')),

          const Expanded(flex: 2, child: _PuvTableHeading('Capacity')),

          const Expanded(flex: 3, child: _PuvTableHeading('Date registered')),

          if (_isAdmin)
            const Expanded(flex: 2, child: _PuvTableHeading('Actions')),
        ],
      ),
    );
  }

  // ==========================================================
  // VEHICLE RECORDS
  // ==========================================================

  Widget _buildVehicleRecords(bool isMobile) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return _buildRecordMessage(
        message: _loadError!,
        icon: Icons.error_outline,
      );
    }

    final filtered = PuvSummary.search(_records, _searchController.text);

    return Column(
      children: [
        if (filtered.isEmpty)
          _buildRecordMessage(
            message: _records.isEmpty
                ? 'No vehicles registered yet.'
                : 'No matching vehicles found.',
            icon: Icons.directions_bus_outlined,
          )
        else
          for (final record in filtered) _buildVehicleRow(record, isMobile),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Showing ${filtered.length} '
                  'of ${_records.length} vehicles',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),

              IconButton(
                tooltip: 'Refresh vehicle records',
                onPressed: _loadPuvs,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordMessage({
    required String message,
    required IconData icon,
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
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 18),

            if (_loadError != null)
              AppButton(
                label: 'Try again',
                icon: Icons.refresh,
                type: AppButtonType.secondary,
                onPressed: _loadPuvs,
              )
            else if (_records.isEmpty && _canModify)
              AppButton(
                label: 'Register PUV',
                icon: Icons.add,
                type: AppButtonType.secondary,
                onPressed: _openRegistrationDialog,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleRow(PuvModel record, bool isMobile) {
    const style = TextStyle(fontSize: 13, color: AppColors.textPrimary);

    final registered = PuvSummary.registrationDate(record.createdAt);

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
                  record.puvType,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Text('PUV ID: ${record.puvId}', style: style),

                Text('Capacity: ${record.capacity}', style: style),

                Text('Registered: $registered', style: style),

                if (_canModify) ...[
                  const SizedBox(height: 12),

                  AppButton(
                    label: 'Edit PUV',
                    icon: Icons.edit_outlined,
                    type: AppButtonType.secondary,
                    onPressed: () => _openVehicleDialog(existing: record),
                  ),
                ],
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(record.puvId.toString(), style: style),
                ),

                Expanded(flex: 3, child: Text(record.puvType, style: style)),

                Expanded(
                  flex: 2,
                  child: Text(record.capacity.toString(), style: style),
                ),

                Expanded(flex: 3, child: Text(registered, style: style)),

                if (_isAdmin)
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Edit PUV',
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                        ),
                        onPressed: _canModify
                            ? () => _openVehicleDialog(existing: record)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ============================================================
// PUV STATISTIC CARD
// ============================================================

class _PuvStatisticCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String value;

  const _PuvStatisticCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 21, color: AppColors.primary),
          ),

          const SizedBox(height: 16),

          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
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
// TABLE HEADING COMPONENT
// ============================================================

class _PuvTableHeading extends StatelessWidget {
  final String label;

  const _PuvTableHeading(this.label);

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
// REGISTER PUV DIALOG
// ============================================================

class _RegisterPuvDialog extends StatefulWidget {
  final PuvModel? existing;

  const _RegisterPuvDialog({this.existing});

  @override
  State<_RegisterPuvDialog> createState() => _RegisterPuvDialogState();
}

class _RegisterPuvDialogState extends State<_RegisterPuvDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _typeController = TextEditingController();

  final TextEditingController _capacityController = TextEditingController();

  final PuvService _dialogService = PuvService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    if (existing != null) {
      _typeController.text = existing.puvType;
      _capacityController.text = existing.capacity.toString();
    }
  }

  @override
  void dispose() {
    _dialogService.dispose();
    _typeController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  // ==========================================================
  // FIELD VALIDATION
  // ==========================================================

  String? _validateType(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the PUV type.';
    }

    if (value.trim().runes.length > 50) {
      return 'PUV type must not exceed 50 characters.';
    }

    return null;
  }

  String? _validateCapacity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the passenger capacity.';
    }

    final input = value.trim();

    if (!RegExp(r'^[0-9]+$').hasMatch(input)) {
      return 'Capacity must be a whole number.';
    }

    final capacity = int.tryParse(input);

    if (capacity == null || capacity > 2147483647) {
      return 'Please enter a valid passenger capacity.';
    }

    if (capacity <= 0) {
      return 'Capacity must be greater than zero.';
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
  // Saves vehicle information using the authenticated API.
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

    final session = SessionManager.instance;
    final token = session.accessToken;

    if (!session.isAdmin || token == null) {
      setState(() {
        _errorMessage = 'Administrator access is required.';
      });
      return;
    }

    final capacity = int.parse(_capacityController.text.trim());

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing) {
        await _dialogService.updatePuv(
          puvId: widget.existing!.puvId,
          puvType: _typeController.text,
          capacity: capacity,
          accessToken: token,
        );
      } else {
        await _dialogService.createPuv(
          puvType: _typeController.text,
          capacity: capacity,
          accessToken: token,
        );
      }

      if (!mounted || session.accessToken != token) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted || session.accessToken != token) {
        return;
      }

      if (error.statusCode == 401) {
        Navigator.of(context).pop();
        session.clearSession();
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to save vehicle information.';
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
                    label: 'PUV type',
                    hint: 'e.g. Jeepney, Bus, Multicab',
                    controller: _typeController,
                    prefixIcon: Icons.directions_bus_outlined,
                    validator: _validateType,
                    enabled: !_isLoading,
                    onChanged: _clearError,
                  ),

                  const SizedBox(height: 18),

                  AppTextField(
                    label: 'Passenger capacity',
                    hint: 'Enter maximum capacity',
                    controller: _capacityController,
                    prefixIcon: Icons.groups_outlined,
                    keyboardType: TextInputType.number,
                    validator: _validateCapacity,
                    enabled: !_isLoading,
                    onChanged: _clearError,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Enter a positive whole number '
                    'representing the vehicle capacity.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 22),

                  _buildInformationNotice(),

                  const SizedBox(height: 24),

                  const Divider(),

                  const SizedBox(height: 20),

                  AppButton(
                    label: _isEditing ? 'Save changes' : 'Register PUV',
                    icon: _isEditing ? Icons.save_outlined : Icons.add,
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
                Icons.directions_bus_outlined,
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

        Text(
          _isEditing ? 'Edit PUV' : 'Register PUV',
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          _isEditing
              ? 'Update the registered vehicle information.'
              : 'Enter the vehicle information to register '
                    'a public utility vehicle in SakaySense.',
          style: const TextStyle(
            fontSize: 13,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 22),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vehicle identification',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  _isEditing
                      ? 'PUV ID ${widget.existing!.puvId} '
                            'and its registration date will be preserved.'
                      : 'The PUV ID and registration date '
                            'will be generated automatically '
                            'by the backend when the vehicle '
                            'is registered.',
                  style: const TextStyle(
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
