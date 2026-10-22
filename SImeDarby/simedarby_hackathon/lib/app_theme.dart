import 'package:flutter/material.dart';

const forest = Color(0xFF173F32);
const green = Color(0xFF267354);
const pale = Color(0xFFE9F1E9);
const canvas = Color(0xFFF7F8F4);
const softMint = Color(0xFFE7F0E3);
const softCream = Color(0xFFFAF7EA);
const muted = Color(0xFF78877D);

BoxDecoration softCard({double radius = 22}) {
  return BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFEAF2E6)],
    ),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: forest.withValues(alpha: .055),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

InputDecoration field(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.never,
    prefixIcon: Icon(icon, color: green),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
  );
}

String formatStamp(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final ampm = date.hour < 12 ? 'AM' : 'PM';

  return '${date.day}/${date.month}/${date.year}  '
      '$hour:$minute $ampm';
}

Widget detailRow(String name, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(name, style: const TextStyle(color: muted)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: forest, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}
