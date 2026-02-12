import 'package:flutter/material.dart';
import 'package:mini_commerce_app/core/localization/app_localizations.dart';

import 'section_title.dart';

class CustomErrorWidget extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  const CustomErrorWidget({super.key, required this.title, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: title),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Text(message ?? context.tr('load_error'), style: const TextStyle(color: Colors.red)),
              if (onRetry != null)
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.tr('retry')),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
