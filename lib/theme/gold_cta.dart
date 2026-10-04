import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/widgets/press_scale.dart';
import 'app_theme.dart';
import 'myazz_tokens.dart';

/// Primary CTA in the myazz-ui "StartButton" language: champagne-gold
/// gradient outer ring (2px), dark-navy inner fill, white label, and a slow
/// sheen sweep (6s loop).
///
/// Effect budget: ONE sheen per screen — use this for the single primary
/// action only (product-details add-to-cart, cart checkout). Secondary
/// actions use [GoldButton] (static gold) or the dark-pill theme button.
///
/// Honors MediaQuery.disableAnimations: no sweep, static ring.
/// Press feedback comes from [PressScale] (scale .97 + light haptic).
class GoldCta extends StatefulWidget {
  const GoldCta({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.height = 52,
    this.sheen = true,
    this.glow = true,
  });

  final String label;

  /// null → disabled: dimmed ring, no sheen/glow, no tap.
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;
  final bool sheen;
  final bool glow;

  @override
  State<GoldCta> createState() => _GoldCtaState();
}

class _GoldCtaState extends State<GoldCta> with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  bool _sweepStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (widget.sheen && !reduceMotion && !_sweepStarted) {
      _sweepStarted = true;
      _sheen.repeat();
    } else if ((reduceMotion || !widget.sheen) && _sweepStarted) {
      _sweepStarted = false;
      _sheen.stop();
      _sheen.value = 0;
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return PressScale(
      scale: 0.97,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.55,
        duration: M.d2,
        child: Container(
          height: widget.height,
          padding: const EdgeInsets.all(2), // gold ring thickness
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: enabled ? M.goldGradient : null,
            color: enabled ? null : AppTheme.dim,
            boxShadow: enabled && widget.glow ? M.goldGlow : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dark navy inner fill (StartButton language)
                Positioned.fill(
                  child: Container(
                    color: const Color(0xC70C1424),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Slow sheen sweep — the ONE gold accent animation on screen.
                if (enabled && widget.sheen && _sweepStarted)
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _sheen,
                      builder: (_, __) {
                        final t = Curves.easeInOut
                            .transform((_sheen.value * 1.4).clamp(0, 1));
                        return Transform.translate(
                          offset: Offset(-200 + t * 600, 0),
                          child: Transform.rotate(
                            angle: 0.5,
                            child: Container(
                              width: 60,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: 0.30),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact static gold button (myazz-ui "GoldButton"): gold-gradient fill,
/// INK label (skill rule: text on gold is ink, not white), soft gold shadow.
/// No sheen — stays inside the effect budget. Max one per screen.
class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.fontSize = 13,
  });

  final String label;

  /// null → disabled: dim fill, no tap.
  final VoidCallback? onTap;
  final IconData? icon;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return PressScale(
      scale: 0.94,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.55,
        duration: M.d2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            gradient: enabled ? M.goldGradient : null,
            color: enabled ? null : AppTheme.dim,
            borderRadius: BorderRadius.circular(999),
            boxShadow: enabled
                ? const [
                    BoxShadow(
                      color: Color(0x59C99A3C), // rgba(201,154,60,.35)
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: M.ink, size: fontSize + 2),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: M.ink,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
