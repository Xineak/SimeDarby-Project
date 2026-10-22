import 'package:flutter/material.dart';
import '../app_theme.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w900,
        color: forest,
        letterSpacing: -.4,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
    this.text, {
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 53,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: forest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: .4,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 10),
              Icon(icon, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyCard extends StatelessWidget {
  const EmptyCard(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: muted)),
      ),
    );
  }
}

class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        constraints: const BoxConstraints(minHeight: 90),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? pale : const Color(0xFFF8FAF7),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? green : const Color(0xFFE5E9E4),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: selected ? green : muted),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? forest : muted,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: muted),
              ),
          ],
        ),
      ),
    );
  }
}

class RobotArt extends StatelessWidget {
  const RobotArt({super.key, this.size = 100});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RobotPainter()),
    );
  }
}

class _RobotPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 100, s.height / 100);

    final shadow = Paint()..color = const Color(0x22000000);
    c.drawOval(const Rect.fromLTWH(9, 83, 84, 9), shadow);

    final wheel = Paint()..color = const Color(0xFF303B37);

    for (final x in [23.0, 75.0]) {
      c.drawCircle(Offset(x, 78), 12, wheel);
      c.drawCircle(Offset(x, 78), 6, Paint()..color = const Color(0xFF89BA95));
    }

    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(13, 16, 74, 66),
      const Radius.circular(20),
    );

    c.drawRRect(body, Paint()..color = const Color(0xFFFCFDF9));

    c.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFFB7C9BA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(19, 22, 62, 40),
        const Radius.circular(15),
      ),
      Paint()..color = const Color(0xFF1D2B29),
    );

    for (final x in [40.0, 61.0]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 35, 7, 15),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF8DF2A5),
      );
    }

    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(28, 8, 44, 10),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF3E4A46),
    );

    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(34, 69, 32, 5),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF54B976),
    );

    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
