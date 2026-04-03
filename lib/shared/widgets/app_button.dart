// Part of eSun Flutter App — design system
/// Primary and secondary buttons with gradient, loading state, and press animation.
library;


import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Primary button — 52px height, 14px radius, Royal Blue gradient.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.variant = AppButtonVariant.primary,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.width,
  }) : variant = AppButtonVariant.secondary;

  @override
  State<AppButton> createState() => _AppButtonState();
}

enum AppButtonVariant { primary, secondary }

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.variant == AppButtonVariant.primary;

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _enabled ? (_) => _scaleCtrl.forward() : null,
        onTapUp: _enabled ? (_) => _scaleCtrl.reverse() : null,
        onTapCancel: _enabled ? () => _scaleCtrl.reverse() : null,
        child: SizedBox(
          width: widget.width ?? double.infinity,
          height: 52,
          child: isPrimary
              ? _buildPrimary(context)
              : _buildSecondary(context),
        ),
      ),
    );
  }

  Widget _buildPrimary(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: _enabled
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3B5BBF), Color(0xFF2E4A9A)],
              )
            : null,
        color: _enabled ? null : ESUNColors.primary.withOpacity(0.5),
        boxShadow: _enabled
            ? const [
                BoxShadow(
                  color: Color(0x402E4A9A),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _enabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(14),
          splashColor: const Color(0xFF1A3080),
          child: Center(child: _label(Colors.white)),
        ),
      ),
    );
  }

  Widget _buildSecondary(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ESUNColors.primary,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _enabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(14),
          splashColor: ESUNColors.primary.withOpacity(0.08),
          child: Center(child: _label(ESUNColors.primary)),
        ),
      ),
    );
  }

  Widget _label(Color color) {
    if (widget.isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator.adaptive(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }
    return Text(
      widget.label,
      style: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}
