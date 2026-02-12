import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_commerce_app/core/localization/app_localizations.dart';
import 'package:mini_commerce_app/presentation/profile/cubit/locale_cubit.dart';

import '../../products/pages/home_page.dart';
import '../cubit/cart_cubit.dart';

class OrderConfirmationPage extends StatefulWidget {
  const OrderConfirmationPage({super.key});

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _checkController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<ConfettiParticle> _particles = List.generate(50, (index) => ConfettiParticle());

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _confettiController = AnimationController(vsync: this, duration: const Duration(seconds: 3));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _mainController.forward();
    Future.delayed(const Duration(milliseconds: 400), () => _checkController.forward());
    Future.delayed(const Duration(milliseconds: 800), () => _confettiController.repeat());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartCubit>().clearCart();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _checkController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                painter: ConfettiPainter(_particles, _confettiController.value),
                size: Size.infinite,
              );
            },
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.1),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _checkController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: SuccessCheckPainter(_checkController.value),
                                size: const Size(60, 60),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            context.tr('order_confirmed'),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${context.tr('order_number')} #MS-${Random().nextInt(9000) + 1000}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.read<LocaleCubit>().state.languageCode == 'ar'
                                ? context.tr('order_success_msg')
                                : 'Your order ${context.tr('order_success_msg')}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HomePage()),
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                elevation: 0,
                              ),
                              child: Text(
                                context.tr('continue_shopping'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SuccessCheckPainter extends CustomPainter {
  final double progress;
  SuccessCheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.45);
    path.lineTo(size.width * 0.45, size.height * 0.75);
    path.lineTo(size.width * 0.85, size.height * 0.25);

    if (progress > 0) {
      final pathMetrics = path.computeMetrics().first;
      final extractPath = pathMetrics.extractPath(0, pathMetrics.length * progress);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(SuccessCheckPainter oldDelegate) => oldDelegate.progress != progress;
}

class ConfettiParticle {
  late double x, y;
  late double speed;
  late Color color;
  late double size;

  ConfettiParticle() {
    reset();
  }

  void reset() {
    x = Random().nextDouble();
    y = -0.1 - Random().nextDouble();
    speed = 0.005 + Random().nextDouble() * 0.01;
    size = 4 + Random().nextDouble() * 6;
    color = [
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.pink,
      Colors.orange,
      Colors.purple,
    ][Random().nextInt(6)];
  }

  void update() {
    y += speed;
    x += sin(y * 10) * 0.002;
    if (y > 1.1) reset();
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double animationValue;

  ConfettiPainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();
      final paint = Paint()..color = particle.color.withOpacity(0.6);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(particle.x * size.width, particle.y * size.height),
          width: particle.size,
          height: particle.size,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}
