import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;
  final bool? enableBlur;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius,
    this.blur = 18.0, // Elegant frosted glass blur level
    this.opacity = 0.45, // 50% glassy effect
    this.color = Colors.white,
    this.borderColor = Colors.white,
    this.borderWidth = 1.2, // Thin light reflection
    this.padding,
    this.margin,
    this.boxShadow,
    this.enableBlur,
  });

  @override
  Widget build(BuildContext context) {
    final borderRad = borderRadius ?? BorderRadius.circular(20);
    
    // Auto-disable blur on mobile (Android/iOS) to prevent scroll jank/lag.
    // BackdropFilter is extremely heavy to render while scrolling on mobile GPUs.
    final bool isMobile = !kIsWeb && 
        (Theme.of(context).platform == TargetPlatform.android || 
         Theme.of(context).platform == TargetPlatform.iOS);
    final bool shouldBlur = (enableBlur ?? !isMobile) && blur > 0;

    final containerBody = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: borderRad,
        border: Border.all(
          color: borderColor.withOpacity(opacity + 0.15),
          width: borderWidth,
        ),
      ),
      child: child,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRad,
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: shouldBlur
          ? ClipRRect(
              borderRadius: borderRad,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: containerBody,
              ),
            )
          : containerBody,
    );
  }
}
