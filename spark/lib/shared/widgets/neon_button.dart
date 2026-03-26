import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_theme.dart';

class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradient = AppColors.primaryGradient,
    this.glowColor = AppColors.neonPink,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.borderRadius = AppDimensions.radiusRound,
    this.icon,
    this.isLoading = false,
    this.enabled = true,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final LinearGradient gradient;
  final Color glowColor;
  final double? width;
  final double height;
  final double borderRadius;
  final IconData? icon;
  final bool isLoading;
  final bool enabled;
  final TextStyle? textStyle;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppDimensions.animFast),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled || widget.isLoading) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (!widget.enabled || widget.isLoading) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    if (!widget.enabled || widget.isLoading) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOpacity = widget.enabled ? 1.0 : 0.5;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: (widget.enabled && !widget.isLoading) ? widget.onPressed : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: AppDimensions.animFast),
          opacity: effectiveOpacity,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: _isPressed ? 0.6 : 0.4),
                  blurRadius: _isPressed
                      ? AppDimensions.neonBlurLarge
                      : AppDimensions.neonBlurMedium,
                  spreadRadius: _isPressed
                      ? AppDimensions.neonSpreadMedium
                      : AppDimensions.neonSpreadSmall,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: AppColors.white, size: AppDimensions.iconM),
                          const SizedBox(width: AppDimensions.spacing8),
                        ],
                        Text(
                          widget.label,
                          style: widget.textStyle ??
                              const TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: AppDimensions.animNormal))
        .slideY(begin: 0.1, end: 0, duration: const Duration(milliseconds: AppDimensions.animNormal));
  }
}

/// Variant: outlined neon button (no fill, neon border)
class NeonOutlinedButton extends StatelessWidget {
  const NeonOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.neonPink,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double? width;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        decoration: AppTheme.neonGlowDecoration(
          color: color,
          backgroundColor: AppColors.transparent,
          blurRadius: AppDimensions.neonBlurSmall,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: AppDimensions.iconM),
                const SizedBox(width: AppDimensions.spacing8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
