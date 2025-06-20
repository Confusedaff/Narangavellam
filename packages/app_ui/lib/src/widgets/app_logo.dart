// ignore_for_file: public_member_api_docs

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    required this.fit,
    this.color,
    this.height,
    this.width,
    super.key,});

  final double? height;
  final double? width;
  final BoxFit fit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Assets.images.instagramTextLogo.svg(
      height: height ?? 60,
      width: width ?? 60,
      fit: fit,
      colorFilter: ColorFilter.mode(
        color ?? context.adaptiveColor, BlendMode.srcIn,
        ),
    );
  }
}
