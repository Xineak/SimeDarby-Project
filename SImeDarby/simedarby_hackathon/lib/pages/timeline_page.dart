import 'dart:async';
import 'package:flutter/material.dart';

import 'package:simedarby_hackathon/app_theme.dart';
import 'package:simedarby_hackathon/delivery_clock.dart';
import 'package:simedarby_hackathon/Model/delivery.dart';
import 'package:simedarby_hackathon/widgets/convey_widgets.dart';
import 'package:simedarby_hackathon/robot_tracking_page.dart';
import 'proof_page.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({
    required this.delivery,
    required this.onComplete,
    required this.onTrack,
    super.key,
  });

  final Delivery delivery;
  final VoidCallback onComplete;
  final VoidCallback onTrack;

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  Timer? _refresh;
  late final TextEditingController _feedbackController;

  static const steps = [
    'Request confirmed',
    'Robot assigned',
    'Items collected',
    'Out for delivery',
    'Delivered to your home',
  ];

  static const descriptions = [
    'Your request has been received',
    'CONVY Robot #01 has been assigned',
    'Your items have been collected from the locker',
    'Robot is travelling to your home',
    'Arrived at your destination',
  ];

  @override
  void initState() {
    super.initState();

    _feedbackController = TextEditingController(text: widget.delivery.feedback);

    _refresh = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delivery = widget.delivery;

    final progress =
        (delivery.completedAt != null ||
            (delivery.isDemo && delivery.progress >= 3))
        ? 4
        : delivery.trackingStartedAt == null
        ? 0
        : DeliveryClock.stage(delivery.trackingStartedAt!);

    final eta = delivery.trackingStartedAt == null
        ? 3
        : DeliveryClock.etaMinutes(delivery.trackingStartedAt!);

    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery #${delivery.id}'),
        backgroundColor: canvas,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Center(
                child: Image.asset(
                  'assets/images/request_success.png',
                  height: 145,
                  errorBuilder: (_, _, _) => const RobotArt(size: 145),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  delivery.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: forest,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Locker ${delivery.locker} → ${delivery.destination}',
                  style: const TextStyle(color: muted),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  progress == 4
                      ? 'Delivered'
                      : delivery.trackingStartedAt == null
                      ? 'Awaiting robot'
                      : 'En Route · ETA $eta min',
                  style: const TextStyle(
                    color: green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              const SectionTitle('Delivery Timeline'),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: softCard(radius: 22),
                child: Column(
                  children: [
                    for (int i = 0; i < steps.length; i++)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Icon(
                                i <= progress
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 26,
                                color: i <= progress ? green : muted,
                              ),
                              if (i != steps.length - 1)
                                Container(
                                  width: 2,
                                  height: 64,
                                  color: i < progress ? green : pale,
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    steps[i],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: i <= progress ? forest : muted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    descriptions[i],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: muted,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    i <= progress
                                        ? formatStamp(
                                            i == 0
                                                ? delivery.createdAt
                                                : i == 4
                                                ? (delivery.completedAt ??
                                                      delivery.createdAt)
                                                : (delivery.trackingStartedAt ??
                                                          delivery.createdAt)
                                                      .add(
                                                        Duration(
                                                          milliseconds:
                                                              (DeliveryClock
                                                                          .duration
                                                                          .inMilliseconds *
                                                                      DeliveryClock.stageThreshold(
                                                                        i,
                                                                      ))
                                                                  .round(),
                                                        ),
                                                      ),
                                          )
                                        : 'Pending',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: i <= progress ? green : muted,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              if (progress == 4) ...[
                const SizedBox(height: 22),
                const SectionTitle('Proof of Delivery'),
                const SizedBox(height: 10),
                const Text(
                  'Parcel has been delivered.',
                  style: TextStyle(color: green, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                PrimaryButton(
                  'VIEW PROOF OF DELIVERY',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProofPage(delivery: delivery),
                      ),
                    );
                  },
                  icon: Icons.photo_camera_outlined,
                ),
                const SizedBox(height: 22),

                const SectionTitle('Rate your delivery'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        onPressed: () {
                          setState(() => delivery.rating = i);
                        },
                        icon: Icon(
                          i <= delivery.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFF1B544),
                          size: 34,
                        ),
                      ),
                  ],
                ),
                TextField(
                  controller: _feedbackController,
                  onChanged: (value) => delivery.feedback = value,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Tell us how your delivery went...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  'SAVE FEEDBACK',
                  onPressed: () {
                    delivery.feedback = _feedbackController.text;
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback saved for this demo session!'),
                      ),
                    );
                  },
                  icon: Icons.favorite_outline_rounded,
                ),
              ],

              const SizedBox(height: 20),
              const Text(
                'Prototype · Delivery stages and locations are simulated.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 18),

              if (delivery.trackingStartedAt != null &&
                  delivery.completedAt == null)
                PrimaryButton(
                  'TRACK ROBOT',
                  onPressed: widget.onTrack,
                  icon: Icons.location_on_outlined,
                ),

              if (delivery.trackingStartedAt == null &&
                  delivery.completedAt == null)
                const EmptyCard(
                  'Robot tracking will be available when delivery starts.',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
