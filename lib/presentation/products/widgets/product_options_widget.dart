import 'package:flutter/material.dart';

import '../../../data/models/product_option_config.dart';

class ProductOptionsWidget extends StatelessWidget {
  final ProductOptionConfig config;
  final int selectedIndex;
  final ValueChanged<int> onOptionSelected;

  const ProductOptionsWidget({
    super.key,
    required this.config,
    required this.selectedIndex,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(config.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: config.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final selected = selectedIndex == i;
              return GestureDetector(
                onTap: () => onOptionSelected(i),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: theme.cardTheme.color,
                    border: Border.all(
                      color: selected ? theme.dividerColor : theme.dividerColor.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    config.values[i],
                    style: TextStyle(
                      color: selected
                          ? theme.textTheme.bodyLarge?.color
                          : theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
