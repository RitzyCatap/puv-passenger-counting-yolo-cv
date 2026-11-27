import 'package:material_ui/material_ui.dart';
import '../constants/app_colors.dart';

enum AppButtonType {
  primary,
  secondary,
  danger,
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final AppButtonType type;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.type = AppButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSecondary =
        type == AppButtonType.secondary;

    final Color foregroundColor = isSecondary
        ? AppColors.primary
        : AppColors.textLight;

    final Color backgroundColor =
        type == AppButtonType.danger
            ? AppColors.error
            : AppColors.primary;

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor,
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(
            icon,
            size: 19,
          ),
          const SizedBox(width: 9),
        ],

        Flexible(
          child: Text(
            isLoading ? 'Please wait...' : label,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    final VoidCallback? action =
        isLoading ? null : onPressed;

    final Widget button = isSecondary
        ? OutlinedButton(
            onPressed: action,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 14,
              ),
              side: const BorderSide(
                color: AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: content,
          )
        : ElevatedButton(
            onPressed: action,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              disabledBackgroundColor: isLoading
                  ? backgroundColor
                  : AppColors.disabled,
              disabledForegroundColor: isLoading
                  ? foregroundColor
                  : AppColors.disabledText,
              elevation: 0,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: content,
          );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: button,
    );
  }
}