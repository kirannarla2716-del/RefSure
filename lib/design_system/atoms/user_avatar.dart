// ignore_for_file: require_trailing_commas

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;
  final bool showOnlineDot;
  const UserAvatar({super.key, required this.name, this.photoUrl,
    this.size = 40, this.showOnlineDot = false});

  Color get _bg {
    const colors = [
      Color(0xFF0A66C2), Color(0xFF057642), Color(0xFF7C3AED),
      Color(0xFFB45309), Color(0xFFCC1016), Color(0xFF4F46E5),
    ];
    return name.isEmpty ? colors[0] : colors[name.codeUnitAt(0) % colors.length];
  }

  String get _initials => name.trim().split(' ')
      .map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      avatar = ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: CachedNetworkImage(
          imageUrl: photoUrl!, width: size, height: size, fit: BoxFit.cover,
          placeholder: (_, __) => _fallback,
          errorWidget: (_, __, ___) => _fallback));
    } else {
      avatar = _fallback;
    }
    if (!showOnlineDot) return avatar;
    return Stack(children: [
      avatar,
      Positioned(right: 2, bottom: 2, child: Container(
        width: size * 0.22, height: size * 0.22,
        decoration: BoxDecoration(
          color: AppColors.emerald, shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5)))),
    ]);
  }

  Widget get _fallback => CircleAvatar(
    radius: size / 2, backgroundColor: _bg,
    child: Text(_initials, style: GoogleFonts.inter(
      color: Colors.white, fontWeight: FontWeight.w700,
      fontSize: size * 0.35)));
}
