import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'visual_cart_controller.dart';

class VisualCartOverlay extends StatefulWidget {
  final VisualCartControllerState controller;

  const VisualCartOverlay({super.key, required this.controller});

  @override
  State<VisualCartOverlay> createState() => _VisualCartOverlayState();
}

class _VisualCartOverlayState extends State<VisualCartOverlay> with TickerProviderStateMixin {
  late final AnimationController _showHideController;
  final Tween<Offset> _slideTween = Tween<Offset>(begin: const Offset(-1.2, 0.3), end: Offset.zero);
  late final Animation<Offset> _slideAnimation;
  final Tween<double> _fadeTween = Tween<double>(begin: 0.0, end: 1.0);
  late final Animation<double> _fadeAnimation;

  late final AnimationController _impactController;
  late final Animation<double> _impactAnimation;

  VisualCartControllerState get _ctrl => widget.controller;

  final List<_FlyingImageEntry> _flyingEntries = [];

  @override
  void initState() {
    super.initState();

    _showHideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slideAnimation = _slideTween.animate(
      CurvedAnimation(parent: _showHideController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = _fadeTween.animate(
      CurvedAnimation(parent: _showHideController, curve: Curves.easeOut),
    );

    _impactController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _impactAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 3), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 3, end: -2.5), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -2.5, end: 1.5), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: -0.5), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.5, end: 0), weight: 20),
    ]).animate(CurvedAnimation(parent: _impactController, curve: Curves.easeOut));

    _ctrl.isVisible.addListener(_onVisibilityChanged);
    _ctrl.activeFly.addListener(_onActiveFlyChanged);
    _ctrl.impactTrigger.addListener(_onImpact);
  }

  @override
  void dispose() {
    _ctrl.isVisible.removeListener(_onVisibilityChanged);
    _ctrl.activeFly.removeListener(_onActiveFlyChanged);
    _ctrl.impactTrigger.removeListener(_onImpact);
    _showHideController.dispose();
    _impactController.dispose();
    for (final e in _flyingEntries) {
      e.controller.dispose();
    }
    _flyingEntries.clear();
    super.dispose();
  }

  void _onVisibilityChanged() {
    if (_ctrl.isVisible.value) {
      // Enter from left
      _slideTween
        ..begin = const Offset(-1.2, 0.3)
        ..end = Offset.zero;
      _fadeTween
        ..begin = 0.0
        ..end = 1.0;
      _showHideController.forward(from: 0);
    } else {
      final screenWidth = MediaQuery.of(context).size.width;
      final exitOffsetX = (screenWidth - _basketLeft) / (_basketWidth + 10);
      _slideTween
        ..begin = Offset.zero
        ..end = Offset(exitOffsetX, 0.3);
      _fadeTween
        ..begin = 1.0
        ..end = 0.0;
      _showHideController.forward(from: 0);
    }
  }

  void _onImpact() {
    _impactController.forward(from: 0);
  }

  void _onActiveFlyChanged() {
    final request = _ctrl.activeFly.value;
    if (request == null) return;
    _launchFly(request);
  }

  void _launchFly(FlyRequest request) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final entry = _FlyingImageEntry(request: request, controller: controller);

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _flyingEntries.remove(entry);
        });
        controller.dispose();
        _ctrl.onFlyComplete(request);
      }
    });

    setState(() {
      _flyingEntries.add(entry);
    });

    controller.forward();
  }

  static const double _basketWidth = 74;
  static const double _basketHeight = 66;
  static const double _basketLeft = 16;
  static const double _basketBottom = 24;

  Offset get _basketCenter {
    final screenHeight = MediaQuery.of(context).size.height;
    return Offset(_basketLeft + _basketWidth / 2, screenHeight - _basketBottom - _basketHeight / 2);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ..._flyingEntries.map((entry) => _buildFlyingImage(entry)),
        Positioned(
          left: _basketLeft,
          bottom: _basketBottom,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: AnimatedBuilder(
                animation: _impactAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _impactAnimation.value),
                    child: child,
                  );
                },
                child: _buildBasket(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasket() {
    return ValueListenableBuilder<List<VisualCartItem>>(
      valueListenable: _ctrl.cartItems,
      builder: (context, items, _) {
        return SizedBox(
          width: _basketWidth + 10,
          height: _basketHeight + 18,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: CustomPaint(painter: _ShoppingCartPainter())),

              Positioned(
                left: 10,
                top: 10,
                width: _basketWidth - 6,
                height: _basketHeight - 14,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (items.isEmpty)
                      Center(
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          size: 20,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final placement = _getPlacement(index, items.length);
                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        left: placement.left,
                        top: placement.top,
                        child: AnimatedRotation(
                          turns: placement.rotation / 360,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          child: _buildCartImage(item.imageUrl),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static const double _imgSize = 30;
  static const double _bodyW = 68;

  _ItemPlacement _getPlacement(int index, int total) {
    final cx = (_bodyW - _imgSize) / 2;
    switch (index) {
      case 0:
        return _ItemPlacement(left: cx, top: 20, rotation: 0);
      case 1:
        return _ItemPlacement(left: cx - 12, top: 10, rotation: -8);
      case 2:
        return _ItemPlacement(left: cx + 10, top: 4, rotation: 7);
      case 3:
        return _ItemPlacement(left: cx - 8, top: -2, rotation: -5);
      case 4:
        return _ItemPlacement(left: cx + 4, top: -8, rotation: 4);
      default:
        return _ItemPlacement(left: cx, top: 20, rotation: 0);
    }
  }

  Widget _buildCartImage(String imageUrl) {
    return Container(
      width: _imgSize,
      height: _imgSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            color: Colors.grey.shade700,
            child: const Icon(Icons.shopping_bag, size: 14, color: Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildFlyingImage(_FlyingImageEntry entry) {
    final start = entry.request.startPosition;
    final end = _basketCenter;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final control = Offset(start.dx + dx * 0.3, min(start.dy, end.dy) - (dy.abs() * 0.35 + 60));

    final curved = CurvedAnimation(parent: entry.controller, curve: Curves.easeInOutCubic);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value;
        final u = 1 - t;
        final pos = Offset(
          u * u * start.dx + 2 * u * t * control.dx + t * t * end.dx,
          u * u * start.dy + 2 * u * t * control.dy + t * t * end.dy,
        );
        final scale = 1.0 - (t * 0.65);
        final opacity = (1.0 - t * 0.5).clamp(0.0, 1.0);

        return Positioned(
          left: pos.dx - (25 * scale),
          top: pos.dy - (25 * scale),
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(scale: scale, child: child),
            ),
          ),
        );
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: entry.request.imageUrl,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey.shade300,
              child: const Icon(Icons.shopping_bag, size: 24, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlyingImageEntry {
  final FlyRequest request;
  final AnimationController controller;

  _FlyingImageEntry({required this.request, required this.controller});
}

class _ItemPlacement {
  final double left;
  final double top;
  final double rotation;

  _ItemPlacement({required this.left, required this.top, required this.rotation});
}

class _ShoppingCartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final handlePaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final handlePath = Path()
      ..moveTo(w * 0.02, h * 0.12)
      ..lineTo(w * 0.22, h * 0.12)
      ..lineTo(w * 0.28, h * 0.22);
    canvas.drawPath(handlePath, handlePaint);

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF616161), Color(0xFF424242), Color(0xFF303030)],
      ).createShader(Rect.fromLTWH(w * 0.15, h * 0.15, w * 0.75, h * 0.58));

    final bodyPath = Path()
      ..moveTo(w * 0.18, h * 0.18)
      ..lineTo(w * 0.92, h * 0.18)
      ..lineTo(w * 0.82, h * 0.72)
      ..quadraticBezierTo(w * 0.80, h * 0.76, w * 0.76, h * 0.76)
      ..lineTo(w * 0.32, h * 0.76)
      ..quadraticBezierTo(w * 0.28, h * 0.76, w * 0.26, h * 0.72)
      ..close();

    canvas.drawPath(bodyPath, bodyPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(bodyPath, borderPaint);

    final rimPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.18),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.74, 3));
    canvas.drawRect(Rect.fromLTWH(w * 0.20, h * 0.18, w * 0.70, 2.5), rimPaint);

    final wirePaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 0.7;

    for (double frac = 0.32; frac < 0.72; frac += 0.12) {
      final yy = h * frac;
      final leftX = w * (0.18 + (frac - 0.18) * 0.12);
      final rightX = w * (0.92 - (frac - 0.18) * 0.14);
      canvas.drawLine(Offset(leftX, yy), Offset(rightX, yy), wirePaint);
    }

    final wheelPaint = Paint()
      ..color = const Color(0xFF757575)
      ..style = PaintingStyle.fill;
    final wheelBorderPaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final hubPaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.fill;

    final lwCenter = Offset(w * 0.34, h * 0.86);
    canvas.drawCircle(lwCenter, h * 0.08, wheelPaint);
    canvas.drawCircle(lwCenter, h * 0.08, wheelBorderPaint);
    canvas.drawCircle(lwCenter, h * 0.03, hubPaint);

    final rwCenter = Offset(w * 0.74, h * 0.86);
    canvas.drawCircle(rwCenter, h * 0.08, wheelPaint);
    canvas.drawCircle(rwCenter, h * 0.08, wheelBorderPaint);
    canvas.drawCircle(rwCenter, h * 0.03, hubPaint);

    final axlePaint = Paint()
      ..color = const Color(0xFF616161)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.34, h * 0.76), lwCenter, axlePaint);
    canvas.drawLine(Offset(w * 0.74, h * 0.76), rwCenter, axlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
