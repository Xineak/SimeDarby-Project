import 'dart:async';
import 'package:flutter/material.dart';

import 'package:simedarby_hackathon/app_theme.dart';
import 'package:simedarby_hackathon/delivery_clock.dart';
import 'package:simedarby_hackathon/Model/delivery.dart';
import 'package:simedarby_hackathon/Model/notice.dart';
import 'package:simedarby_hackathon/robot_tracking_page.dart';
import 'package:simedarby_hackathon/widgets/convey_widgets.dart';

import 'notifications_page.dart';
import 'proof_page.dart';
import 'request_page.dart';
import 'success_page.dart';
import 'timeline_page.dart';

class ConveyHome extends StatefulWidget {
  const ConveyHome({super.key});

  @override
  State<ConveyHome> createState() => _ConveyHomeState();
}

class _ConveyHomeState extends State<ConveyHome> {
  final List<Delivery> deliveries = [];
  final List<Delivery> history = [
    Delivery(
      id: 901,
      items: [ParcelItem(type: 'Food', size: 'Small')],
      locker: 'B-08',
      destination: 'House A-12',
      pickup: 'Completed',
      scheduled: false,
      createdAt: DateTime(2026, 10, 15, 18, 18),
      displayName: 'Food Delivery',
      isDemo: true,
    )..progress = 3,
    Delivery(
      id: 902,
      items: [ParcelItem(type: 'Parcel', size: 'Medium')],
      locker: 'B-08',
      destination: 'House A-12',
      pickup: 'Completed',
      scheduled: false,
      createdAt: DateTime(2026, 10, 15, 10, 27),
      displayName: 'Parcel Delivery',
      isDemo: true,
    )..progress = 3,
    Delivery(
      id: 903,
      items: [ParcelItem(type: 'Food', size: 'Small')],
      locker: 'B-08',
      destination: 'House A-12',
      pickup: 'Completed',
      scheduled: false,
      createdAt: DateTime(2026, 10, 17, 20, 49),
      displayName: 'Food Delivery',
      isDemo: true,
    )..progress = 3,
  ];

  final List<Notice> notices = [
    Notice(
      'Welcome to Convey',
      'Your smart community delivery experience is ready.',
    ),
    Notice(
      'Robot A-01 is available',
      'Request a robot whenever you are ready.',
    ),
  ];

  Timer? _deliveryTimer;
  int tab = 0;
  int nextId = 1001;

  int get unread => notices.where((n) => !n.read).length;

  @override
  void initState() {
    super.initState();

    _deliveryTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;

      final finished = deliveries.where((delivery) {
        return delivery.trackingStartedAt != null &&
            DeliveryClock.fraction(delivery.trackingStartedAt!) >= 1;
      }).toList();

      for (final delivery in finished) {
        completeTracking(delivery);
      }

      if (finished.isEmpty &&
          deliveries.any((d) => d.trackingStartedAt != null)) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _deliveryTimer?.cancel();
    super.dispose();
  }

  Future<void> request() async {
    final result = await Navigator.push<Delivery>(
      context,
      MaterialPageRoute(builder: (_) => RequestPage(id: nextId)),
    );

    if (!mounted || result == null) return;

    setState(() {
      deliveries.insert(0, result);
      nextId++;

      notices.insert(
        0,
        Notice(
          'Request #${result.id} confirmed',
          '${result.items.length} item(s) from Locker '
              '${result.locker} to ${result.destination}.',
        ),
      );
    });

    if (result.scheduled) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => SuccessPage(delivery: result)),
      );
    } else {
      result.trackingStartedAt = DateTime.now();
      await openTracking(result);
    }
  }

  Future<void> openTracking(Delivery delivery) async {
    if (delivery.trackingStartedAt == null && !delivery.scheduled) {
      delivery.trackingStartedAt = DateTime.now();
    }

    if (delivery.trackingStartedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This delivery has not started yet.')),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: SafeArea(
            child: RobotTrackingPage(
              deliveryId: delivery.id,
              locker: delivery.locker,
              destination: delivery.destination,
              startedAt: delivery.trackingStartedAt,
              onComplete: () => completeTracking(delivery),
            ),
          ),
        ),
      ),
    );
  }

  void completeTracking(Delivery delivery) {
    if (!mounted || !deliveries.contains(delivery)) return;

    setState(() {
      deliveries.remove(delivery);
      delivery.completedAt = DateTime.now();
      delivery.progress = 3;

      history.insert(0, delivery);

      notices.insert(
        0,
        Notice(
          'Delivery #${delivery.id} completed',
          'Your items have arrived at ${delivery.destination}.',
          deliveryId: delivery.id,
        ),
      );
    });
  }

  void openDelivery(Delivery delivery) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TimelinePage(
          delivery: delivery,
          onTrack: () => openTracking(delivery),
          onComplete: () => completeTracking(delivery),
        ),
      ),
    );
  }

  void openNotices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsPage(
          notices: notices,
          changed: () => setState(() {}),
          onOpenDelivery: (id) {
            final matches = [
              ...deliveries,
              ...history,
            ].where((delivery) => delivery.id == id);

            if (matches.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProofPage(delivery: matches.first),
                ),
              );
            }
          },
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                if (tab != 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 20, 12),
                    child: Row(
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Convey',
                              style: TextStyle(
                                fontSize: 29,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.3,
                                color: forest,
                              ),
                            ),
                            Text(
                              'SMART COMMUNITY DELIVERY',
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w700,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Stack(
                          children: [
                            IconButton.filledTonal(
                              onPressed: openNotices,
                              style: IconButton.styleFrom(
                                backgroundColor: pale,
                              ),
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                color: forest,
                              ),
                            ),
                            if (unread > 0)
                              const Positioned(
                                right: 8,
                                top: 5,
                                child: CircleAvatar(
                                  radius: 5,
                                  backgroundColor: Color(0xFFD94E45),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: tab == 0
                      ? _home()
                      : tab == 2
                      ? _history()
                      : tab == 3
                      ? _profile()
                      : _track(),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: tab,
        backgroundColor: Colors.white,
        indicatorColor: pale,
        onDestinationSelected: (index) {
          if (index == 1 &&
              deliveries.isNotEmpty &&
              deliveries.first.trackingStartedAt != null) {
            openTracking(deliveries.first);
          } else {
            setState(() => tab = index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            label: 'Track',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _home() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 205,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/home_banner.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: pale,
                    child: const Center(
                      child: Icon(Icons.landscape, size: 70, color: green),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFFF8FAF3).withValues(alpha: .96),
                        const Color(0xFFF8FAF3).withValues(alpha: .65),
                        Colors.transparent,
                      ],
                      stops: const [0, .45, .83],
                    ),
                  ),
                ),
                const Positioned(
                  left: 20,
                  top: 34,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good evening,',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: forest,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Xing En',
                        style: TextStyle(
                          fontSize: 33,
                          fontWeight: FontWeight.w900,
                          color: forest,
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '⌂  House A-12',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: forest,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 26),
        Row(
          children: [
            const Expanded(child: SectionTitle('Current Delivery')),
            Text(
              '${deliveries.length} active',
              style: const TextStyle(color: green, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (deliveries.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: softMint,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                RobotArt(size: 85),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No current delivery',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: forest,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Ready when you are. Request a robot to get started.',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...deliveries.map(
            (delivery) => Card(
              color: softMint,
              child: ListTile(
                onTap: () => openDelivery(delivery),
                leading: const Icon(
                  Icons.local_shipping_outlined,
                  color: green,
                ),
                title: Text(delivery.title),
                subtitle: Text('Robot A-01 · Locker ${delivery.locker}'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),

        const SizedBox(height: 25),
        const SectionTitle('Robot Status'),
        const SizedBox(height: 12),
        InkWell(
          onTap: request,
          borderRadius: BorderRadius.circular(23),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: softCard(radius: 23),
            child: const Row(
              children: [
                RobotArt(size: 80),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready for delivery',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: forest,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Tap to request a robot',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.wifi_tethering_rounded,
                  color: Color(0xFF91BE91),
                  size: 40,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          'REQUEST ROBOT',
          onPressed: request,
          icon: Icons.arrow_forward_rounded,
        ),

        const SizedBox(height: 25),
        Row(
          children: [
            const Expanded(child: SectionTitle('Recent Deliveries')),
            TextButton(
              onPressed: () => setState(() => tab = 2),
              child: const Text('View All  ›', style: TextStyle(color: green)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (history.isEmpty)
          const EmptyCard('No recent deliveries yet')
        else
          ...history
              .take(3)
              .map(
                (delivery) => Card(
                  color: Colors.white,
                  child: ListTile(
                    onTap: () => openDelivery(delivery),
                    leading: const Icon(
                      Icons.inventory_2_outlined,
                      color: green,
                    ),
                    title: Text(delivery.title),
                    subtitle: Text(
                      formatStamp(delivery.completedAt ?? delivery.createdAt),
                    ),
                    trailing: const Text(
                      'Delivered',
                      style: TextStyle(
                        color: green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

        const SizedBox(height: 18),
        const Text(
          'Designed for smarter, easier community living.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _track() {
    if (deliveries.isEmpty || deliveries.first.trackingStartedAt == null) {
      return const RobotTrackingPage(
        key: ValueKey('community-preview'),
        previewOnly: true,
      );
    }

    final delivery = deliveries.first;

    return RobotTrackingPage(
      key: ValueKey(delivery.id),
      locker: delivery.locker,
      destination: delivery.destination,
      deliveryId: delivery.id,
      startedAt: delivery.trackingStartedAt,
      onComplete: () => completeTracking(delivery),
    );
  }

  Widget _history() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const SectionTitle('Delivery History'),
        const SizedBox(height: 15),
        if (history.isEmpty)
          const EmptyCard('No completed deliveries yet')
        else
          ...history.map(
            (delivery) => Card(
              color: Colors.white,
              child: ListTile(
                onTap: () => openDelivery(delivery),
                leading: const Icon(Icons.inventory_2_outlined, color: green),
                title: Text('Request #${delivery.id} · ${delivery.title}'),
                subtitle: Text(
                  'Delivered · ${formatStamp(delivery.completedAt ?? delivery.createdAt)}\n'
                  'View timeline, proof & feedback',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right_rounded, color: green),
              ),
            ),
          ),
      ],
    );
  }

  Widget _profile() {
    return const Padding(
      padding: EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RobotArt(size: 105),
          SectionTitle('My Profile'),
          SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Icon(Icons.person_outline, color: green),
              title: Text('Xing En'),
              subtitle: Text('House A-12 · Convey resident'),
            ),
          ),
        ],
      ),
    );
  }
}
