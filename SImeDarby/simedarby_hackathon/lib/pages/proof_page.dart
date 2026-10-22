import 'package:flutter/material.dart';

import 'package:simedarby_hackathon/app_theme.dart';
import 'package:simedarby_hackathon/Model/delivery.dart';

class ProofPage extends StatelessWidget {
  const ProofPage({required this.delivery, super.key});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Evidence'),
        backgroundColor: canvas,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Order #${delivery.id}',
            style: const TextStyle(
              color: forest,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Delivered to ${delivery.destination}',
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              delivery.proofImage,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Padding(
                padding: EdgeInsets.all(30),
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 70,
                  color: muted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Photo proof · ${formatStamp(delivery.completedAt ?? delivery.createdAt)}',
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 8),
          const Text(
            'Prototype only · This is a simulated delivery photo, not a live robot capture.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
