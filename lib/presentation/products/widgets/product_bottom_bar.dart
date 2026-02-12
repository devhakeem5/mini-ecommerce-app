import 'package:flutter/material.dart';
import 'package:mini_commerce_app/core/localization/app_localizations.dart';

class ProductBottomBar extends StatelessWidget {
  final bool isFavorite;
  final bool canAddToCart;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onAddToCart;

  const ProductBottomBar({
    super.key,
    required this.isFavorite,
    required this.canAddToCart,
    required this.onFavoriteToggle,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: onFavoriteToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isFavorite
                        ? Colors.red.withOpacity(0.3)
                        : theme.dividerColor.withOpacity(0.1),
                  ),
                ),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton(
                onPressed: canAddToCart ? onAddToCart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey.shade800,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  context.tr(canAddToCart ? 'add_to_cart' : 'out_of_stock'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
