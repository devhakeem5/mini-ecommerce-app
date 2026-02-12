import 'package:flutter/material.dart';
import 'package:mini_commerce_app/presentation/common/widgets/section_title.dart';

class EmptyWidget extends StatelessWidget {
  final String title;
  const EmptyWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: title),
        const SizedBox(height: 16),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('لا توجد منتجات')),
      ],
    );
  }
}
