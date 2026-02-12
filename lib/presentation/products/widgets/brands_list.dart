import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mini_commerce_app/core/localization/app_localizations.dart';

import '../../common/widgets/section_title.dart';

class BrandsList extends StatelessWidget {
  const BrandsList({super.key});

  final List<String> brands = const [
    'assets/brands/airbnb.svg',
    'assets/brands/apple-11.svg',
    'assets/brands/bobcat-50221.svg',
    'assets/brands/prada.svg',
    'assets/brands/puma-logo.svg',
    'assets/brands/samsung-electronics.svg',
    'assets/brands/suzuki-12.svg',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: context.tr('brands')),
        const SizedBox(height: 16),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  color: Colors.transparent,
                ),
                child: SvgPicture.asset(brands[index], fit: BoxFit.contain),
              );
            },
          ),
        ),
      ],
    );
  }
}
