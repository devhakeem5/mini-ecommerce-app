import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_commerce_app/core/localization/app_localizations.dart';
import 'package:mini_commerce_app/core/util/responsive.dart';

import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import 'order_confirmation_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _selectedPaymentIndex = 0;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'key': 'credit_card', 'icon': Icons.credit_card, 'sub_key': 'visa_mastercard'},
    {'key': 'apple_pay', 'icon': Icons.apple, 'sub_key': 'fast_secure'},
    {'key': 'paypal', 'icon': Icons.account_balance_wallet, 'sub_key': 'direct_payment'},
    {'key': 'cash_on_delivery', 'icon': Icons.money, 'sub_key': 'pay_at_door'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('confirm_order')), centerTitle: true),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is! CartLoaded) return const SizedBox.shrink();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Responsive(
                mobile: _buildMobileLayout(state),
                desktop: _buildDesktopLayout(state),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is! CartLoaded) return const SizedBox.shrink();
          return Responsive.isDesktop(context) ? const SizedBox.shrink() : _buildBottomBar(context);
        },
      ),
    );
  }

  Widget _buildMobileLayout(CartLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context.tr('order_summary')),
          _buildOrderSummary(state),
          const SizedBox(height: 24),
          _buildSectionHeader(context.tr('payment_method')),
          _buildPaymentMethods(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(CartLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildSectionHeader(context.tr('payment_method')), _buildPaymentMethods()],
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context.tr('order_summary')),
                _buildOrderSummary(state),
                const SizedBox(height: 32),
                _buildDesktopConfirmButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPaymentMethods() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _paymentMethods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildSelectionCard(
        title: context.tr(_paymentMethods[index]['key']),
        subtitle: context.tr(_paymentMethods[index]['sub_key']),
        icon: _paymentMethods[index]['icon'],
        isSelected: _selectedPaymentIndex == index,
        onTap: () => setState(() => _selectedPaymentIndex = index),
      ),
    );
  }

  Widget _buildOrderSummary(CartLoaded state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            '${context.tr('items')} (${state.itemCount})',
            state.totalPrice.toStringAsFixed(2),
          ),
          if (state.totalSavings > 0)
            _buildSummaryRow(
              context.tr('discount'),
              '-${state.totalSavings.toStringAsFixed(2)}',
              isDiscount: true,
            ),
          const Divider(height: 24),
          _buildSummaryRow(
            context.tr('total'),
            state.totalDiscountedPrice.toStringAsFixed(2),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isDiscount
                  ? Colors.green
                  : (isTotal
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: FontWeight.bold,
              color: isDiscount ? Colors.green : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).dividerColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.black : Theme.of(context).iconTheme.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: SafeArea(child: _buildConfirmButton(context)),
    );
  }

  Widget _buildDesktopConfirmButton(BuildContext context) {
    return SizedBox(width: double.infinity, child: _buildConfirmButton(context));
  }

  Widget _buildConfirmButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OrderConfirmationPage()),
          (route) => false,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 0,
      ),
      child: Text(
        context.tr('confirm_order'),
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
