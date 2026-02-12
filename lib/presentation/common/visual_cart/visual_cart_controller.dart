import 'dart:async';

import 'package:flutter/material.dart';

class VisualCartItem {
  final String imageUrl;
  final String id;

  VisualCartItem({required this.imageUrl, required this.id});
}

class FlyRequest {
  final String imageUrl;
  final Offset startPosition;
  final String id;

  FlyRequest({required this.imageUrl, required this.startPosition, required this.id});
}

class VisualCartControllerState {
  final ValueNotifier<bool> isVisible = ValueNotifier(false);
  final ValueNotifier<List<VisualCartItem>> cartItems = ValueNotifier([]);
  final ValueNotifier<FlyRequest?> activeFly = ValueNotifier(null);
  final ValueNotifier<int> impactTrigger = ValueNotifier(0);

  static const int maxItems = 5;
  static const Duration autoDismissDelay = Duration(seconds: 5);

  Timer? _autoDismissTimer;
  FlyRequest? _pendingFly;
  bool _isFlyActive = false;

  void addProduct(String imageUrl, Offset startPosition) {
    final id = '${DateTime.now().millisecondsSinceEpoch}';
    final request = FlyRequest(imageUrl: imageUrl, startPosition: startPosition, id: id);

    if (!isVisible.value) {
      cartItems.value = [];
      isVisible.value = true;
    }

    _resetAutoDismiss();

    if (_isFlyActive) {
      _pendingFly = request;
      return;
    }

    _startFly(request);
  }

  void _startFly(FlyRequest request) {
    _isFlyActive = true;
    activeFly.value = request;
  }

  void onFlyComplete(FlyRequest request) {
    final newItem = VisualCartItem(imageUrl: request.imageUrl, id: request.id);
    final current = List<VisualCartItem>.from(cartItems.value);

    if (current.length >= maxItems) {
      current.removeAt(0);
    }
    current.add(newItem);
    cartItems.value = current;

    impactTrigger.value++;

    activeFly.value = null;
    _isFlyActive = false;

    _resetAutoDismiss();

    if (_pendingFly != null) {
      final next = _pendingFly!;
      _pendingFly = null;
      _startFly(next);
    }
  }

  void _resetAutoDismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(autoDismissDelay, () {
      isVisible.value = false;
    });
  }

  void dispose() {
    _autoDismissTimer?.cancel();
    isVisible.dispose();
    cartItems.dispose();
    activeFly.dispose();
    impactTrigger.dispose();
  }
}

class VisualCartController extends InheritedWidget {
  final VisualCartControllerState state;

  const VisualCartController({super.key, required this.state, required super.child});

  static VisualCartControllerState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<VisualCartController>()?.state;
  }

  @override
  bool updateShouldNotify(VisualCartController oldWidget) => false;
}
