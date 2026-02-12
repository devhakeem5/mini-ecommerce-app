import 'package:flutter/material.dart';

import '../../common/widgets/skeleton_loaders.dart';

class LoadingHorizontalList extends StatelessWidget {
  final String title;
  const LoadingHorizontalList({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return HorizontalProductSkeleton(title: title);
  }
}
