import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/crop_data.dart';
import '../../core/theme/app_theme.dart';

/// Displays a product image. Priority:
/// 1. First entry in [images] (base64 data URL or https URL)
/// 2. Asset looked up by [productName] via CropData
/// 3. Green eco icon fallback
class ProductImage extends StatelessWidget {
  final String productName;
  final List<dynamic>? images;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.productName,
    this.images,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final firstImage = images?.isNotEmpty == true ? images!.first?.toString() : null;
    Widget img;

    if (firstImage != null && firstImage.startsWith('data:image')) {
      // Base64 data URL from farmer upload
      try {
        final base64Str = firstImage.split(',').last;
        final bytes = base64Decode(base64Str);
        img = Image.memory(bytes, width: width, height: height, fit: fit,
            errorBuilder: (_, __, ___) => _fallbackAsset());
      } catch (_) {
        img = _fallbackAsset();
      }
    } else if (firstImage != null && firstImage.startsWith('http')) {
      img = Image.network(firstImage, width: width, height: height, fit: fit,
          errorBuilder: (_, __, ___) => _fallbackAsset());
    } else {
      img = _fallbackAsset();
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
  }

  Widget _fallbackAsset() {
    final asset = CropData.assetFor(productName);
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: AppTheme.primary.withValues(alpha: 0.08),
        child: const Center(child: Icon(Icons.eco, size: 48, color: AppTheme.primary)),
      ),
    );
  }
}
