import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/session_manager.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  final SessionManager _sessionManager = SessionManager.instance;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _authService.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================================
  // EMAIL VALIDATION
  // ==========================================================

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address.';
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  // ==========================================================
  // PASSWORD VALIDATION
  // ==========================================================

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }

    return null;
  }

  // ==========================================================
  // LOGIN HANDLER
  // Authenticates through the FastAPI backend.
  // Establishes an in-memory authenticated session.
  // ==========================================================

  Future<void> _handleLogin() async {
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

    try {
      final session = await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      _passwordController.clear();

      _sessionManager.startSession(session);

      if (!mounted) return;

      if (session.user.isAdmin) {
        context.go('/dashboard/admin');
      } else if (session.user.isOperator) {
        context.go('/dashboard/operator');
      }
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to sign in. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearError(String value) {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  // ==========================================================
  // MAIN RESPONSIVE LAYOUT
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            if (isDesktop) {
              return Row(
                children: [
                  Expanded(flex: 10, child: _buildBrandPanel()),

                  Expanded(flex: 11, child: _buildLoginPanel(isMobile: false)),
                ],
              );
            }

            return _buildLoginPanel(isMobile: true);
          },
        ),
      ),
    );
  }

  // ==========================================================
  // DESKTOP BRAND PANEL
  // ==========================================================

  Widget _buildBrandPanel() {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(48),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight > 96
                    ? constraints.maxHeight - 96
                    : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrandLogo(darkBackground: true, size: 50),

                  const SizedBox(height: 56),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 25,
                            height: 2,
                            color: AppColors.accent,
                          ),

                          const SizedBox(width: 12),

                          const Expanded(
                            child: Text(
                              'YOUR TRANSPORT WORKSPACE',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      const Text(
                        'Every count',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          letterSpacing: -1.5,
                          color: AppColors.textLight,
                        ),
                      ),

                      const Text(
                        'matters.',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          letterSpacing: -1.5,
                          color: AppColors.accent,
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'A smarter approach to passenger '
                        'counting in public utility vehicles '
                        'through image-based computer vision.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.8,
                          color: AppColors.sidebarText,
                        ),
                      ),

                      const SizedBox(height: 30),

                      _buildTransportIllustration(),

                      const SizedBox(height: 26),

                      const Wrap(
                        spacing: 22,
                        runSpacing: 14,
                        children: [
                          _BrandFeature(
                            icon: Icons.image_outlined,
                            label: 'Still-image analysis',
                          ),

                          _BrandFeature(
                            icon: Icons.center_focus_strong,
                            label: 'YOLO detection',
                          ),

                          _BrandFeature(
                            icon: Icons.analytics_outlined,
                            label: 'Counting reports',
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(color: AppColors.sidebarHover),

                      SizedBox(height: 20),

                      Text(
                        'Developed by RSJ Tech',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.sidebarText,
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        'Caraga State University',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.sidebarMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // LOGIN FORM PANEL
  // ==========================================================

  Widget _buildLoginPanel({required bool isMobile}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = isMobile ? 24.0 : 56.0;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 28),

          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 56
                  ? constraints.maxHeight - 56
                  : 0,
            ),

            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isMobile) ...[
                      const BrandLogo(size: 46),

                      const SizedBox(height: 36),
                    ],

                    TextButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              context.go('/');
                            },

                      icon: const Icon(Icons.arrow_back, size: 18),

                      label: const Text('Back to home'),
                    ),

                    const SizedBox(height: 26),

                    Text(
                      'Welcome back.',
                      style: TextStyle(
                        fontSize: isMobile ? 32 : 38,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.2,
                        color: AppColors.primary,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Sign in to access your '
                      'SakaySense workspace.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 36),

                    _buildLoginForm(),

                    const SizedBox(height: 28),

                    const Divider(),

                    const SizedBox(height: 22),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),

                          child: const Icon(
                            Icons.shield_outlined,
                            size: 22,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(width: 12),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Authorized access only',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),

                              SizedBox(height: 5),

                              Text(
                                'Accounts are managed by '
                                'the system administrator. '
                                'Contact your administrator '
                                'if you need access.',
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

                    const SizedBox(height: 32),

                    const Text(
                      '© 2026 SakaySense',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // LOGIN FORM
  // ==========================================================

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,

      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              _buildErrorMessage(),

              const SizedBox(height: 20),
            ],

            AppTextField(
              label: 'Email address',
              hint: 'Enter your email address',
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
              enabled: !_isLoading,
              onChanged: _clearError,
            ),

            const SizedBox(height: 22),

            AppTextField(
              label: 'Password',
              hint: 'Enter your password',
              controller: _passwordController,
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              validator: _validatePassword,
              enabled: !_isLoading,
              onChanged: _clearError,
            ),

            const SizedBox(height: 28),

            AppButton(
              label: 'Sign in',
              icon: Icons.arrow_forward,
              fullWidth: true,
              isLoading: _isLoading,
              onPressed: _handleLogin,
            ),
          ],
        ),
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

  // ==========================================================
  // TRANSPORT ILLUSTRATION
  // ==========================================================

  Widget _buildTransportIllustration() {
    return Container(
      height: 205,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.sidebarHover,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.chartGreen),
      ),

      child: const ClipRect(
        child: CustomPaint(painter: _LoginTransportPainter()),
      ),
    );
  }
}

// ============================================================
// BRAND FEATURE COMPONENT
// ============================================================

class _BrandFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BrandFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: AppColors.accent),

        const SizedBox(width: 7),

        Text(
          label,
          style: const TextStyle(color: AppColors.sidebarText, fontSize: 12),
        ),
      ],
    );
  }
}

// ============================================================
// CUSTOM VEHICLE ILLUSTRATION
// ============================================================

class _LoginTransportPainter extends CustomPainter {
  const _LoginTransportPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    final horizontalScale = size.width / 400;
    final verticalScale = size.height / 220;

    final scale = horizontalScale < verticalScale
        ? horizontalScale
        : verticalScale;

    canvas.translate(
      (size.width - 400 * scale) / 2,
      (size.height - 220 * scale) / 2,
    );

    canvas.scale(scale);

    final gridPaint = Paint()
      ..color = AppColors.chartGreen.withValues(alpha: 0.15)
      ..strokeWidth = 0.8;

    for (double x = 0; x <= 400; x += 25) {
      canvas.drawLine(Offset(x, 0), Offset(x, 220), gridPaint);
    }

    for (double y = 0; y <= 220; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(400, y), gridPaint);
    }

    final outlinePaint = Paint()
      ..color = AppColors.chartSage
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bodyPaint = Paint()..color = AppColors.primaryDark;

    final vehicle = RRect.fromRectAndRadius(
      const Rect.fromLTWH(40, 55, 320, 108),
      const Radius.circular(12),
    );

    canvas.drawRRect(vehicle, bodyPaint);
    canvas.drawRRect(vehicle, outlinePaint);

    final windowPaint = Paint()
      ..color = AppColors.chartSage.withValues(alpha: 0.13);

    final window = RRect.fromRectAndRadius(
      const Rect.fromLTWH(52, 67, 296, 64),
      const Radius.circular(5),
    );

    canvas.drawRRect(window, windowPaint);
    canvas.drawRRect(window, outlinePaint);

    final personPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.75);

    final detectionPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    for (int i = 0; i < 4; i++) {
      final x = 88.0 + i * 75;

      canvas.drawCircle(Offset(x, 85), 9, personPaint);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 13, 98, 26, 24),
          const Radius.circular(8),
        ),
        personPaint,
      );

      canvas.drawRect(Rect.fromLTWH(x - 19, 73, 38, 53), detectionPaint);
    }

    canvas.drawCircle(const Offset(104, 167), 19, bodyPaint);

    canvas.drawCircle(const Offset(104, 167), 19, outlinePaint);

    canvas.drawCircle(const Offset(296, 167), 19, bodyPaint);

    canvas.drawCircle(const Offset(296, 167), 19, outlinePaint);

    canvas.drawLine(
      const Offset(25, 192),
      const Offset(375, 192),
      outlinePaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LoginTransportPainter oldDelegate) {
    return false;
  }
}
