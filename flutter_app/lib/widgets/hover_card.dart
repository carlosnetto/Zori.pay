import 'package:flutter/material.dart';

class HoverCard extends StatefulWidget {
  final Widget child;
  final double hoverTranslateY;
  final double defaultElevation;
  final double hoverElevation;
  final BorderRadius? borderRadius;
  final Color? color;
  final Border? border;
  final Border? hoverBorder;

  const HoverCard({
    super.key,
    required this.child,
    this.hoverTranslateY = -8,
    this.defaultElevation = 0,
    this.hoverElevation = 12,
    this.borderRadius,
    this.color,
    this.border,
    this.hoverBorder,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          0,
          _hovering ? widget.hoverTranslateY : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(24),
          border: _hovering ? (widget.hoverBorder ?? widget.border) : widget.border,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovering ? 0.15 : 0.05),
              blurRadius: _hovering ? widget.hoverElevation : widget.defaultElevation,
              offset: Offset(0, _hovering ? 8 : 2),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
