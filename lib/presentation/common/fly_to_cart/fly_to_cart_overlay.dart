import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'fly_to_cart_controller.dart';

class FlyToCartOverlay extends StatefulWidget {
  final FlyToCartControllerState controller;

  const FlyToCartOverlay({super.key, required this.controller});

  @override
  State<FlyToCartOverlay> createState() => _FlyToCartOverlayState();
}

class _FlyToCartOverlayState extends State<FlyToCartOverlay> {
  final List<OverlayEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    widget.controller.itemsNotifier.addListener(_onItemsChanged);
  }

  @override
  void dispose() {
    widget.controller.itemsNotifier.removeListener(_onItemsChanged);
    for (final entry in _entries) {
      entry.remove();
    }
    _entries.clear();
    super.dispose();
  }

  void _onItemsChanged() {
    final items = widget.controller.itemsNotifier.value;
    for (final item in items) {
      _launchFlight(item);
    }
  }

  void _launchFlight(FlyingItem item) {
    final targetPosition = widget.controller.cartIconPosition;
    if (targetPosition == null) {
      widget.controller.removeFlyingItem(item);
      return;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FlyingWidget(
        item: item,
        targetPosition: targetPosition,
        onComplete: () {
          entry.remove();
          _entries.remove(entry);
          widget.controller.removeFlyingItem(item);
          widget.controller.triggerBounce();
        },
      ),
    );

    _entries.add(entry);
    Overlay.of(context).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _FlyingWidget extends StatefulWidget {
  final FlyingItem item;
  final Offset targetPosition;
  final VoidCallback onComplete;

  const _FlyingWidget({required this.item, required this.targetPosition, required this.onComplete});

  @override
  State<_FlyingWidget> createState() => _FlyingWidgetState();
}

class _FlyingWidgetState extends State<_FlyingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  late Offset _start;
  late Offset _end;
  late Offset _control;

  @override
  void initState() {
    super.initState();

    _start = widget.item.startPosition;
    _end = widget.targetPosition;

    final dx = _end.dx - _start.dx;
    final dy = _end.dy - _start.dy;
    _control = Offset(_start.dx + dx * 0.3, min(_start.dy, _end.dy) - (dy.abs() * 0.4 + 80));

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _quadraticBezier(double t) {
    final u = 1 - t;
    return Offset(
      u * u * _start.dx + 2 * u * t * _control.dx + t * t * _end.dx,
      u * u * _start.dy + 2 * u * t * _control.dy + t * t * _end.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        final position = _quadraticBezier(t);
        final scale = 1.0 - (t * 0.7);
        final opacity = (1.0 - t * 0.4).clamp(0.0, 1.0);

        return Positioned(
          left: position.dx - (25 * scale),
          top: position.dy - (25 * scale),
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
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: widget.item.imageUrl,
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
