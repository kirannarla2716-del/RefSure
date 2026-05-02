// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';

class HotBadge extends StatelessWidget {
  const HotBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFFF6B35), borderRadius: BorderRadius.circular(4)),
    child: const Text('\u{1F525} HOT', style: TextStyle(
      fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)));
}
