import 'package:flutter/material.dart';

import 'package:simedarby_hackathon/app_theme.dart';
import 'package:simedarby_hackathon/Model/delivery.dart';
import 'package:simedarby_hackathon/widgets/convey_widgets.dart';

class SuccessPage extends StatelessWidget {
  const SuccessPage({required this.delivery, super.key});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
              children: [
                Image.asset(
                  'assets/images/request_success.png',
                  height: 245,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.check_circle_rounded,
                    size: 86,
                    color: green,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Request Sent!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    color: forest,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Your ${delivery.items.length} item(s) have been added to the delivery queue.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 24),
                Card(
                  color: softMint,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: SectionTitle('Delivery Details'),
                        ),
                        const SizedBox(height: 14),
                        detailRow('Request', '#${delivery.id}'),
                        detailRow('Locker Number', delivery.locker),
                        detailRow('Pickup Time', delivery.pickup),
                        detailRow('Items', '${delivery.items.length}'),
                        detailRow('Destination', delivery.destination),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  'BACK TO HOME',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
