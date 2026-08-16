import 'package:flutter/material.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class LoadingSpinner extends StatelessWidget {
  final String semanticLabel;

  const LoadingSpinner({
    super.key,
    this.semanticLabel = 'Loading',
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Semantics(
          label: semanticLabel,
          liveRegion: true,
          child: const CircularProgressIndicator(color: AppColors.primary),
        ),
      );
}
