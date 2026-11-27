import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../widgets/brand_logo.dart';
import '../widgets/app_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final section = key.currentContext;

    if (section != null) {
      Scrollable.ensureVisible(
        section,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 850;

    return Scaffold(
      backgroundColor: AppColors.background,

      endDrawer: isMobile
          ? Drawer(
              backgroundColor: AppColors.surface,
              child: SafeArea(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: BrandLogo(size: 44, showTagline: false),
                    ),

                    const Divider(),

                    _mobileNavItem('Home', Icons.home_outlined, _homeKey),

                    _mobileNavItem(
                      'How it works',
                      Icons.info_outline,
                      _howItWorksKey,
                    ),

                    _mobileNavItem('About', Icons.groups_outlined, _aboutKey),

                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: AppButton(
                        label: 'Sign in',
                        fullWidth: true,
                        icon: Icons.arrow_forward,
                        onPressed: () {
                          Navigator.pop(context);
                          _openLogin();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,

      body: Column(
        children: [
          _buildHeader(isMobile),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHero(isMobile),
                  _buildHowItWorks(isMobile),
                  _buildAbout(isMobile),
                  _buildCallToAction(isMobile),
                  _buildFooter(isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HEADER AND NAVIGATION
  // ==========================================================

  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 56,
              vertical: 18,
            ),
            child: Row(
              children: [
                const BrandLogo(size: 42, showTagline: false),

                const Spacer(),

                if (!isMobile) ...[
                  _navItem('Home', _homeKey),

                  const SizedBox(width: 24),

                  _navItem('How it works', _howItWorksKey),

                  const SizedBox(width: 24),

                  _navItem('About', _aboutKey),

                  const SizedBox(width: 32),

                  AppButton(
                    label: 'Sign in',
                    icon: Icons.arrow_forward,
                    onPressed: _openLogin,
                  ),
                ] else
                  Builder(
                    builder: (context) {
                      return IconButton(
                        tooltip: 'Open navigation',
                        icon: const Icon(
                          Icons.menu,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        onPressed: () {
                          Scaffold.of(context).openEndDrawer();
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(String label, GlobalKey key) {
    return TextButton(
      onPressed: () => _scrollTo(key),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _mobileNavItem(String label, IconData icon, GlobalKey key) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        _scrollTo(key);
      },
    );
  }

  // ==========================================================
  // HERO SECTION
  // ==========================================================

  Widget _buildHero(bool isMobile) {
    return Container(
      key: _homeKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 56,
        vertical: isMobile ? 48 : 84,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1328),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heroContent(true),

                    const SizedBox(height: 40),

                    _buildDetectionPreview(true),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 10, child: _heroContent(false)),

                    const SizedBox(width: 64),

                    Expanded(flex: 10, child: _buildDetectionPreview(false)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _heroContent(bool isMobile) {
    final headlineSize = isMobile ? 40.0 : 58.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 25, height: 2, color: AppColors.chartGreen),

            const SizedBox(width: 10),

            const Flexible(
              child: Text(
                'INTELLIGENT TRANSPORTATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 25),

        Text(
          'Every passenger.\nEvery count.',
          style: TextStyle(
            fontSize: headlineSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.8,
            height: 1.12,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'Made simpler.',
          style: TextStyle(
            fontSize: headlineSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.8,
            height: 1.12,
            color: AppColors.chartGreen,
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'A smarter approach to passenger counting '
          'in public utility vehicles through '
          'image-based computer vision.',
          style: TextStyle(
            fontSize: 17,
            height: 1.75,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 30),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AppButton(
              label: 'Get started',
              icon: Icons.arrow_forward,
              onPressed: _openLogin,
            ),

            AppButton(
              label: 'How it works',
              type: AppButtonType.secondary,
              onPressed: () {
                _scrollTo(_howItWorksKey);
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        const Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 18,
              color: AppColors.chartGreen,
            ),

            SizedBox(width: 8),

            Expanded(
              child: Text(
                'Still-image analysis powered by YOLO',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // DETECTION CONCEPT PREVIEW
  // ==========================================================

  Widget _buildDetectionPreview(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.center_focus_strong,
                color: AppColors.accent,
                size: 19,
              ),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  'PASSENGER DETECTION',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),

              Text(
                'DEMO',
                style: TextStyle(
                  color: AppColors.sidebarText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Container(
            height: isMobile ? 220 : 290,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.sidebarHover,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.chartGreen),
            ),
            child: const CustomPaint(painter: _DetectionIllustrationPainter()),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.groups_outlined, color: AppColors.primary, size: 32),

                SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passengers detected',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        'Example result',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  '04',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Illustrative preview only. Actual results '
            'will be generated by the detection model.',
            style: TextStyle(
              color: AppColors.sidebarText,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HOW IT WORKS
  // ==========================================================

  Widget _buildHowItWorks(bool isMobile) {
    final steps = [
      const _FeatureStep(
        number: '01',
        icon: Icons.image_outlined,
        title: 'Upload an image',
        description:
            'Select a still image showing the '
            'interior of a public utility vehicle.',
      ),

      const _FeatureStep(
        number: '02',
        icon: Icons.center_focus_strong,
        title: 'Detect passengers',
        description:
            'The YOLO model processes the image '
            'and identifies visible persons.',
      ),

      const _FeatureStep(
        number: '03',
        icon: Icons.analytics_outlined,
        title: 'Review results',
        description:
            'View the detected passenger count '
            'and access saved counting records.',
      ),
    ];

    return Container(
      key: _howItWorksKey,
      width: double.infinity,
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 56,
        vertical: isMobile ? 48 : 68,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1328),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'THE PROCESS',
                style: TextStyle(
                  color: AppColors.chartGreen,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'From image to insight.',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: isMobile ? 28 : 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.7,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Three simple steps for a more '
                'organized passenger counting process.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 36),

              if (isMobile)
                Column(
                  children: [
                    steps[0],

                    const SizedBox(height: 28),

                    steps[1],

                    const SizedBox(height: 28),

                    steps[2],
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: steps[0]),

                    const SizedBox(width: 36),

                    Expanded(child: steps[1]),

                    const SizedBox(width: 36),

                    Expanded(child: steps[2]),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ABOUT SECTION
  // ==========================================================

  Widget _buildAbout(bool isMobile) {
    return Container(
      key: _aboutKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 56,
        vertical: isMobile ? 48 : 72,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ABOUT SAKAYSENSE',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.chartGreen,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Built for a smarter way to count.',
                style: TextStyle(
                  fontSize: isMobile ? 28 : 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'SakaySense is a public utility vehicle '
                'passenger counting system that uses '
                'YOLO-based computer vision to detect '
                'and count visible persons from still images.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'The system is designed for authorized '
                'administrators and operators to manage '
                'PUV information, process passenger images, '
                'review counting history, and access '
                'summary reports.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              const Wrap(
                spacing: 28,
                runSpacing: 20,
                children: [
                  _TechnologyLabel(
                    icon: Icons.image_outlined,
                    title: 'Still-image processing',
                  ),

                  _TechnologyLabel(
                    icon: Icons.center_focus_strong,
                    title: 'YOLO computer vision',
                  ),

                  _TechnologyLabel(
                    icon: Icons.storage_outlined,
                    title: 'Organized counting records',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CALL TO ACTION
  // ==========================================================

  Widget _buildCallToAction(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 56,
        vertical: 40,
      ),
      color: AppColors.primaryLight,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 32,
            runSpacing: 24,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to get started?',
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Sign in to your authorized '
                    'SakaySense workspace.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              AppButton(
                label: 'Access workspace',
                icon: Icons.arrow_forward,
                onPressed: _openLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FOOTER
  // ==========================================================

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryDark,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 56,
        vertical: 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1328),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandLogo(darkBackground: true, size: 44),

              const SizedBox(height: 24),

              const Text(
                'Public Utility Vehicle Passenger '
                'Counting Using YOLO-Based Computer Vision',
                style: TextStyle(
                  color: AppColors.sidebarText,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'An academic system developed by RSJ Tech.',
                style: TextStyle(color: AppColors.sidebarMuted, fontSize: 13),
              ),

              const SizedBox(height: 28),

              const Divider(color: AppColors.sidebarHover),

              const SizedBox(height: 20),

              const Wrap(
                spacing: 20,
                runSpacing: 12,
                children: [
                  Text(
                    '© 2026 SakaySense',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.sidebarMuted,
                    ),
                  ),

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
      ),
    );
  }
}

// ============================================================
// FEATURE STEP COMPONENT
// ============================================================

class _FeatureStep extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;

  const _FeatureStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 25),
              ),

              const Spacer(),

              Text(
                number,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.chartGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TECHNOLOGY LABEL COMPONENT
// ============================================================

class _TechnologyLabel extends StatelessWidget {
  final IconData icon;
  final String title;

  const _TechnologyLabel({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 22),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CUSTOM TRANSPORTATION ILLUSTRATION
// ============================================================

class _DetectionIllustrationPainter extends CustomPainter {
  const _DetectionIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    final scale = size.width / 400;

    canvas.translate(0, (size.height - 240 * scale) / 2);

    canvas.scale(scale);

    final gridPaint = Paint()
      ..color = AppColors.chartGreen.withValues(alpha: 0.15)
      ..strokeWidth = 0.7;

    for (double x = 0; x <= 400; x += 25) {
      canvas.drawLine(Offset(x, 0), Offset(x, 240), gridPaint);
    }

    for (double y = 0; y <= 240; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(400, y), gridPaint);
    }

    final outlinePaint = Paint()
      ..color = AppColors.chartSage
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final bodyPaint = Paint()..color = AppColors.primaryDark;

    final vehicle = RRect.fromRectAndRadius(
      const Rect.fromLTWH(35, 65, 330, 115),
      const Radius.circular(13),
    );

    canvas.drawRRect(vehicle, bodyPaint);
    canvas.drawRRect(vehicle, outlinePaint);

    final windowPaint = Paint()
      ..color = AppColors.chartSage.withValues(alpha: 0.18);

    final window = RRect.fromRectAndRadius(
      const Rect.fromLTWH(48, 78, 304, 66),
      const Radius.circular(5),
    );

    canvas.drawRRect(window, windowPaint);
    canvas.drawRRect(window, outlinePaint);

    final wheelPaint = Paint()..color = AppColors.primaryDark;

    canvas.drawCircle(const Offset(100, 183), 21, wheelPaint);

    canvas.drawCircle(const Offset(300, 183), 21, wheelPaint);

    canvas.drawCircle(const Offset(100, 183), 21, outlinePaint);

    canvas.drawCircle(const Offset(300, 183), 21, outlinePaint);

    final personPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.7);

    final detectionPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 0; i < 4; i++) {
      final x = 85.0 + i * 76;

      // Head
      canvas.drawCircle(Offset(x, 96), 10, personPaint);

      // Body
      final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 14, 109, 28, 27),
        const Radius.circular(10),
      );

      canvas.drawRRect(body, personPaint);

      // Detection bounding box
      canvas.drawRect(Rect.fromLTWH(x - 20, 82, 40, 58), detectionPaint);
    }

    canvas.drawLine(
      const Offset(22, 211),
      const Offset(378, 211),
      outlinePaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DetectionIllustrationPainter oldDelegate) {
    return false;
  }
}
