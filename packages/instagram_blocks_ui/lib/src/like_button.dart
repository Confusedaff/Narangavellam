// ignore_for_file: public_member_api_docs

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

class LikeButton extends StatelessWidget {
  const LikeButton({
    required this.isLiked,
    required this.onLikedTap,
    super.key,
    this.scaleStrength = ScaleStrength.sm,
    this.color,
    this.size,
  });

  final bool isLiked;

  final VoidCallback onLikedTap;

  final Color? color;

  final double? size;

  final ScaleStrength scaleStrength;

  @override
  Widget build(BuildContext context) {
    return Tappable.scaled(
      backgroundColor: AppColors.transparent,
      scaleStrength: scaleStrength,
      onTap: onLikedTap,
      child: Icon(
        isLiked ? Icons.favorite : Icons.favorite_outline,
        color: isLiked ? AppColors.red : color,
        size: size ?? AppSize.iconSize,
      ),
    );
  }
}
