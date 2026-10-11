import 'package:flutter/material.dart';

import '../../theme/myazz_tokens.dart';

/// Lightweight press feedback per luxury-glass-ui §8: while pressed the child
/// sinks [dip] logical px (translateY(1px)) and scales to [scale] (.96),
/// springing back on release/cancel with `--lg-spring` (0.25s) — playful but
/// short. Use for custom (non-Material-ink) tap targets — pills, circular
/// buttons, cards, CTAs — so they feel physical.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  /// Press sink in logical px (CSS `translateY(1px)`). 0 disables the dip.
  final double dip;
  final Duration duration;
  final HitTestBehavior behavior;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
    this.dip = 1.0,
    this.duration = const Duration(milliseconds: 250),
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      onTap: widget.onTap,
      // One implicit 0→1 driver so the dip and the scale stay perfectly in
      // sync; the spring curve overshoots slightly past both ends (§8).
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: _pressed ? 1 : 0),
        // Reduced motion: snap instead of spring (this SDK's implicit
        // animations do not auto-honor MediaQuery.disableAnimations).
        duration: MediaQuery.maybeOf(context)?.disableAnimations ?? false
            ? Duration.zero
            : widget.duration,
        curve: M.spring,
        builder: (context, t, child) => Transform.translate(
          offset: Offset(0, widget.dip * t),
          child: Transform.scale(
            scale: 1 - (1 - widget.scale) * t,
            child: child,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
