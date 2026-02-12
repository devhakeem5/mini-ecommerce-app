import 'package:flutter/material.dart';

import '../../common/widgets/custom_cached_image.dart';

class DetailsImageGallery extends StatelessWidget {
  final List<String> images;
  final String? heroTag;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final Color primaryColor;

  const DetailsImageGallery({
    super.key,
    required this.images,
    this.heroTag,
    required this.currentIndex,
    required this.onPageChanged,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.42;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final image = CustomCachedImage(
                imageUrl: images[index],
                fit: BoxFit.contain,
                width: double.infinity,
                height: height,
              );

              if (index == 0 && heroTag != null) {
                return Hero(
                  tag: heroTag!,
                  child: Material(color: Colors.transparent, child: image),
                );
              }
              return image;
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentIndex == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentIndex == i ? primaryColor : Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
