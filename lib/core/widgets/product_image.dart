import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/api_service.dart';

/// Shows a product image from the backend (relative or absolute URL),
/// or from a local file (e.g. a freshly picked image before upload).
class ProductImage extends StatelessWidget {
  final String? path;
  final Widget fallback;
  final BoxFit fit;
  const ProductImage({
    super.key,
    required this.path,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final src = path;
    if (src == null || src.trim().isEmpty) return fallback;

    // Local file (picked from gallery/camera, not uploaded yet)
    final isRemote = src.startsWith('http') || src.startsWith('/uploads/');
    if (!isRemote && File(src).existsSync()) {
      return Image.file(File(src),
          fit: fit, errorBuilder: (_, __, ___) => fallback);
    }

    final url = ApiService().resolveImageUrl(src);
    if (url == null) return fallback;

    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}