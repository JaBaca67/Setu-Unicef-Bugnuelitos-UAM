import 'package:flutter/material.dart';

class SetuCard extends StatelessWidget {
  const SetuCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.borderColor = const Color(0xFFE1E6EF),
    this.onTap,
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: color,
    surfaceTintColor: Colors.transparent,
    shadowColor: const Color(0x300F172A),
    elevation: 2,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: borderColor),
    ),
    child: onTap == null ? child : InkWell(onTap: onTap, child: child),
  );
}
