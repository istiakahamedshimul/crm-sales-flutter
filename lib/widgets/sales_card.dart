import 'package:flutter/material.dart';

class SalesCard extends StatelessWidget {
  const SalesCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfff1f5f9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0f172a).withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xff0f172a).withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      );
    }
    return card;
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  Color _resolveColor(BuildContext context) {
    if (color != null) return color!;
    final lower = label.toLowerCase().trim();

    // Map typical status strings to modern, harmonious palette colors
    if (['new', 'assigned', 'contacted', 'interested'].contains(lower)) {
      return const Color(0xff2563eb); // Professional blue
    }
    if (['follow-up', 'site visit', 'visited', 'negotiation', 'proposal'].contains(lower)) {
      return const Color(0xff7c3aed); // Royal purple
    }
    if (['booked', 'approved', 'paid', 'success', 'active'].contains(lower)) {
      return const Color(0xff0f766e); // Deep teal
    }
    if (['lost', 'not interested', 'rejected', 'cancelled', 'failed'].contains(lower)) {
      return const Color(0xffe11d48); // Rose red
    }
    if (['pending', 'hold', 'waiting'].contains(lower)) {
      return const Color(0xffd97706); // Amber orange
    }

    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = _resolveColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: effectiveColor.withOpacity(0.12), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: effectiveColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 20, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? const Color(0xff22c55e);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Icon(
            Icons.chat_bubble_rounded,
            size: size,
            color: themeColor,
          ),
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0.1, -0.15), // Offset slightly to center inside the bubble body
              child: Icon(
                Icons.phone_rounded,
                size: size * 0.45,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

