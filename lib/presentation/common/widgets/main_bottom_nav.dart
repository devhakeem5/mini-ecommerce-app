import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cart/cubit/cart_cubit.dart';
import '../../cart/cubit/cart_state.dart';
import '../../cart/pages/cart_page.dart';
import '../../profile/pages/profile_page.dart';
import '../fly_to_cart/fly_to_cart_controller.dart';

class MainBottomNav extends StatefulWidget {
  const MainBottomNav({super.key});

  @override
  State<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends State<MainBottomNav> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controllerState = FlyToCartController.maybeOf(context);
    if (controllerState != null) {
      controllerState.bounceNotifier.addListener(_onBounce);
    }
  }

  void _onBounce() {
    final controllerState = FlyToCartController.maybeOf(context);
    if (controllerState != null && controllerState.bounceNotifier.value) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    final controllerState = FlyToCartController.maybeOf(context);
    controllerState?.bounceNotifier.removeListener(_onBounce);
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = FlyToCartController.maybeOf(context);
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        onTap: (index) {
          if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
          } else if (index == 4) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(CupertinoIcons.house_fill), label: ''),
          const BottomNavigationBarItem(icon: Icon(CupertinoIcons.square_grid_2x2), label: ''),
          const BottomNavigationBarItem(icon: Icon(CupertinoIcons.chat_bubble_2), label: ''),
          BottomNavigationBarItem(
            icon: _CartBadgeIcon(
              bounceAnimation: _bounceAnimation,
              cartIconKey: controllerState?.cartIconKey,
            ),
            label: '',
          ),
          const BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: ''),
        ],
      ),
    );
  }
}

class _CartBadgeIcon extends StatelessWidget {
  final Animation<double> bounceAnimation;
  final GlobalKey? cartIconKey;

  const _CartBadgeIcon({required this.bounceAnimation, this.cartIconKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final itemCount = cartState is CartLoaded ? cartState.itemCount : 0;
        return AnimatedBuilder(
          animation: bounceAnimation,
          builder: (context, child) {
            return Transform.scale(scale: bounceAnimation.value, child: child);
          },
          child: Container(
            key: cartIconKey,
            child: Badge(
              isLabelVisible: itemCount > 0,
              label: Text('$itemCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
              backgroundColor: Colors.black,
              child: const Icon(CupertinoIcons.cart),
            ),
          ),
        );
      },
    );
  }
}
