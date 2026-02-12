import 'package:flutter/material.dart';

class FlyToCartController extends InheritedWidget {
  final FlyToCartControllerState state;

  const FlyToCartController({super.key, required this.state, required super.child});

  static FlyToCartControllerState of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<FlyToCartController>();
    assert(widget != null, 'No FlyToCartController found in context');
    return widget!.state;
  }

  static FlyToCartControllerState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FlyToCartController>()?.state;
  }

  @override
  bool updateShouldNotify(FlyToCartController oldWidget) => false;
}

class FlyToCartControllerState {
  final GlobalKey cartIconKey = GlobalKey();
  final ValueNotifier<bool> bounceNotifier = ValueNotifier(false);
  final List<FlyingItem> _activeItems = [];
  final ValueNotifier<List<FlyingItem>> itemsNotifier = ValueNotifier([]);

  void addFlyingItem(FlyingItem item) {
    _activeItems.add(item);
    itemsNotifier.value = List.from(_activeItems);
  }

  void removeFlyingItem(FlyingItem item) {
    _activeItems.remove(item);
    itemsNotifier.value = List.from(_activeItems);
  }

  void triggerBounce() {
    bounceNotifier.value = true;
    Future.delayed(const Duration(milliseconds: 50), () {
      bounceNotifier.value = false;
    });
  }

  Offset? get cartIconPosition {
    final renderBox = cartIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final position = renderBox.localToGlobal(Offset.zero);
    return position + Offset(renderBox.size.width / 2, renderBox.size.height / 2);
  }

  void dispose() {
    bounceNotifier.dispose();
    itemsNotifier.dispose();
  }
}

class FlyingItem {
  final String imageUrl;
  final Offset startPosition;
  final String id;

  FlyingItem({required this.imageUrl, required this.startPosition, required this.id});
}
