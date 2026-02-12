import 'package:flutter/material.dart';

class ProductInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const ProductInfoRow({super.key, required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
