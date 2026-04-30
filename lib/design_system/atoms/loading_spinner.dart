import 'package:flutter/material.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.primary));
}
