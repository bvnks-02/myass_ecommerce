import 'package:flutter/material.dart';

/// Fly-to-cart overlay + bounce/shake cart badge used on product grids.
class AddToCartAnimation {
  AddToCartAnimation._();

  /// Animates a floating icon from [sourceKey] to [cartKey], then calls [onComplete].
  static void run({
    required BuildContext context,
    required TickerProvider vsync,
    required GlobalKey sourceKey,
    required GlobalKey cartKey,
    required VoidCallback onComplete,
    IconData icon = Icons.shopping_cart_outlined,
    Color flyColor = Colors.white,
    Color iconColor = Colors.black,
    Duration duration = const Duration(milliseconds: 550),
  }) {
    final RenderBox? sourceBox =
        sourceKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? cartBox =
        cartKey.currentContext?.findRenderObject() as RenderBox?;

    if (sourceBox == null || cartBox == null || !sourceBox.hasSize || !cartBox.hasSize) {
      onComplete();
      return;
    }

    final Size sourceSize = sourceBox.size;
    final Size cartSize = cartBox.size;

    // Center-to-center trajectory
    final Offset start = sourceBox.localToGlobal(
      Offset(sourceSize.width / 2, sourceSize.height / 2),
    );
    final Offset end = cartBox.localToGlobal(
      Offset(cartSize.width / 2, cartSize.height / 2),
    );

    const double flySize = 32;
    final Offset startTopLeft = start - const Offset(flySize / 2, flySize / 2);
    final Offset endTopLeft = end - const Offset(flySize / 2, flySize / 2);

    late OverlayEntry overlayEntry;
    final controller = AnimationController(vsync: vsync, duration: duration);

    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    final position = Tween<Offset>(begin: startTopLeft, end: endTopLeft)
        .animate(curved);
    final scale = Tween<double>(begin: 1.0, end: 0.45).animate(curved);
    final opacity = Tween<double>(begin: 1.0, end: 0.65).animate(curved);

    overlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Positioned(
              left: position.value.dx,
              top: position.value.dy,
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity.value,
                  child: Transform.scale(
                    scale: scale.value,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: flySize,
                        height: flySize,
                        decoration: BoxDecoration(
                          color: flyColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: iconColor, size: 16),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      controller.dispose();
      onComplete();
      return;
    }

    overlay.insert(overlayEntry);
    controller.forward().whenComplete(() {
      overlayEntry.remove();
      controller.dispose();
      onComplete();
    });
  }
}

/// Header cart icon with bounce + shake when [itemCount] increases.
class AnimatedCartIcon extends StatefulWidget {
  final int itemCount;
  final VoidCallback? onPressed;
  final Color iconColor;
  final double iconSize;

  const AnimatedCartIcon({
    super.key,
    required this.itemCount,
    this.onPressed,
    this.iconColor = Colors.white,
    this.iconSize = 24,
  });

  @override
  State<AnimatedCartIcon> createState() => _AnimatedCartIconState();
}

class _AnimatedCartIconState extends State<AnimatedCartIcon>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final AnimationController _shakeController;
  late final Animation<double> _bounceAnimation;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.85), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.1), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.12), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.12), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(covariant AnimatedCartIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount > oldWidget.itemCount) {
      _bounceController.forward(from: 0);
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.onPressed,
      icon: AnimatedBuilder(
        animation: Listenable.merge([_bounceController, _shakeController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: Transform.rotate(
              angle: _shakeAnimation.value,
              child: child,
            ),
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              color: widget.iconColor,
              size: widget.iconSize,
            ),
            if (widget.itemCount > 0)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Colors.redAccent],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    widget.itemCount > 99 ? '99+' : '${widget.itemCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
