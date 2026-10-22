import 'dart:async';

import 'package:flutter/material.dart';

import 'robot_tracking_page.dart';
import 'delivery_clock.dart';
import 'auth/profile_page.dart';

import 'package:http/http.dart' as http;

import 'dart:convert';

import '../api_config.dart';

const forest = Color(0xFF173F32);
const green = Color(0xFF267354);
const pale = Color(0xFFE9F1E9);
const canvas = Color(0xFFF7F8F4);
const softMint = Color(0xFFE7F0E3);
const softCream = Color(0xFFFAF7EA);

BoxDecoration softCard({double radius = 22}) => BoxDecoration(
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
const muted = Color(0xFF78877D);

class Delivery {
  Delivery({
    required this.id,
    required this.items,
    required this.locker,
    required this.destination,
    required this.pickup,
    required this.scheduled,
    DateTime? createdAt,
    DateTime? completedAt,
    this.displayName,
    this.isDemo = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       completedAt = completedAt;

  final int id;
  final List<ParcelItem> items;
  final String locker, destination, pickup;
  final bool scheduled;
  final String? displayName;
  final bool isDemo;
  final DateTime createdAt;
  DateTime? completedAt;
  int progress = 0;
  int rating = 0;
  String feedback = '';

  String get proofImage {
    if (id == 901) return 'assets/images/proof_mcd.png';
    if (id == 902) return 'assets/images/proof_shopee.png';
    if (id == 903) return 'assets/images/proof_generic_food.png';
    if (id == 904) return 'assets/images/proof_tealive.png';
    if (id == 905) return 'assets/images/proof_mixed.png';
    if (id == 906) return 'assets/images/proof_box.png';
    if (items.length > 1) return 'assets/images/proof_mixed.png';
    return items.any((i) => i.type == 'Food')
        ? 'assets/images/proof_generic_food.png'
        : 'assets/images/proof_box.png';
  }

  DateTime? trackingStartedAt;
  String get title =>
      displayName ??
      (items.length == 1
          ? '${items.first.type} Delivery'
          : '${items.length} Items Delivery');
}

class ParcelItem {
  ParcelItem({required this.type, required this.size});
  String type, size;
}

class Notice {
  Notice(this.title, this.body, {this.read = false, this.deliveryId});
  final int? deliveryId;
  String title, body;
  bool read;
}

class ConvyHome extends StatefulWidget {
  final String username;
  final String fullName;
  final String houseNo;

  const ConvyHome({
    required this.username,
    super.key,
    required this.fullName,
    required this.houseNo,
  });

  @override
  State<ConvyHome> createState() => _ConvyHomeState();
}

class _ConvyHomeState extends State<ConvyHome> {
  final List<Delivery> deliveries = [];
  List<Delivery> history = [];
  Timer? _deliveryTimer;

  Future<void> _fetchHistoryFromDatabase() async {
    try {
      final url = Uri.parse(
        '$apiBaseUrl/api/history/${Uri.encodeComponent(widget.username)}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true) {
          final List serverHistory = (data['history'] as List?) ?? [];
          if (!mounted) return;
          setState(() {
            history = serverHistory
                .map(
                  (item) => Delivery(
                    id: item['id'] ?? 0,
                    items:
                        (item['items'] as List?)
                            ?.map(
                              (x) => ParcelItem(
                                type: x['type'] ?? 'Parcel',
                                size: x['size'] ?? 'Medium',
                              ),
                            )
                            .toList() ??
                        [],
                    locker: item['locker'] ?? 'B-08',
                    destination: item['destination'] ?? widget.houseNo,
                    pickup: item['pickup'] ?? 'Completed',
                    scheduled: item['scheduled'] ?? false,
                    // 完美解析本地真实时间
                    createdAt: item['createdAt'] != null
                        ? DateTime.parse(item['createdAt']).toLocal()
                        : DateTime.now(),
                    completedAt: item['createdAt'] != null
                        ? DateTime.parse(item['createdAt']).toLocal()
                        : null,
                    displayName: item['displayName'] ?? 'Delivery',
                  ),
                )
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching history from database: $e");
    }
  }

  // 联通后端删除历史订单
  Future<void> _deleteHistoryFromDatabase(Delivery d) async {
    try {
      final url = Uri.parse(
        '$apiBaseUrl/api/history/${Uri.encodeComponent(widget.username)}/${d.id}',
      );
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        setState(() {
          history.remove(d);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History item deleted successfully')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete from database')),
        );
      }
    } catch (e) {
      debugPrint("Error deleting history: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchHistoryFromDatabase();
    _deliveryTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      final finished = deliveries
          .where(
            (d) =>
                d.trackingStartedAt != null &&
                DeliveryClock.fraction(d.trackingStartedAt!) >= 1,
          )
          .toList();
      for (final d in finished) {
        completeTracking(d);
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

  final List<Notice> notices = [
    Notice(
      'Welcome to CONVY',
      'Your smart community delivery experience is ready.',
    ),
    Notice(
      'Robot A-01 is available',
      'Request a robot whenever you are ready.',
    ),
  ];
  int tab = 0, nextId = 1001;
  int get unread => notices.where((n) => !n.read).length;

  void request() async {
    final result = await Navigator.push<Delivery>(
      context,
      MaterialPageRoute(
        builder: (_) => RequestPage(
          id: nextId,
          username: widget.username,
          userHouseNo: widget.houseNo,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      deliveries.insert(0, result);
      nextId++;
      notices.insert(
        0,
        Notice(
          'Request #${result.id} confirmed',
          '${result.items.length} item(s) from Locker ${result.locker} to ${result.destination}.',
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

  Future<void> openTracking(Delivery d) async {
    if (d.trackingStartedAt == null && !d.scheduled) {
      d.trackingStartedAt = DateTime.now();
    }
    if (d.trackingStartedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This delivery has not started yet.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: SafeArea(
            child: RobotTrackingPage(
              deliveryId: d.id,
              locker: d.locker,
              destination: d.destination,
              startedAt: d.trackingStartedAt,
              onComplete: () => completeTracking(d),
            ),
          ),
        ),
      ),
    );
  }

  void completeTracking(Delivery d) {
    if (!mounted || !deliveries.contains(d)) return;
    setState(() {
      deliveries.remove(d);
      d.completedAt = DateTime.now();
      d.progress = 3;
      history.insert(0, d);
      notices.insert(
        0,
        Notice(
          'Delivery #${d.id} completed',
          'Your items have arrived at ${d.destination}.',
          deliveryId: d.id,
        ),
      );
    });
  }

  void openDelivery(Delivery d) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TimelinePage(
        delivery: d,
        onTrack: () => openTracking(d),
        onComplete: () => completeTracking(d),
      ),
    ),
  );

  void openNotices() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => NotificationsPage(
        notices: notices,
        changed: () => setState(() {}),
        onOpenDelivery: (id) {
          final matches = [...deliveries, ...history].where((d) => d.id == id);
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
  );

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
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CONVY',
                                  style: TextStyle(
                                    fontSize: 31,
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
                          ),
                        ),
                        const SizedBox(width: 8),
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
                              Positioned(
                                right: 8,
                                top: 5,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD94E45),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: canvas,
                                      width: 1.5,
                                    ),
                                  ),
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
                      : tab == 1
                      ? _track()
                      : tab == 2
                      ? _history()
                      : ProfilePage(username: widget.username),
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
        onDestinationSelected: (i) {
          if (i == 1) {
            if (deliveries.isNotEmpty &&
                deliveries.first.trackingStartedAt != null) {
              openTracking(deliveries.first);
            } else {
              setState(() => tab = 1);
            }
          } else {
            setState(() => tab = i);
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
            selectedIcon: Icon(Icons.track_changes),
            label: 'Track',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _home() => ListView(
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
                alignment: Alignment.center,
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
              Positioned(
                left: 20,
                top: 34,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Good evening,',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: forest,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.fullName,
                      style: const TextStyle(
                        fontSize: 33,
                        fontWeight: FontWeight.w900,
                        color: forest,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .86),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.home_outlined,
                            size: 18,
                            color: forest,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.houseNo,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
          child: Row(
            children: [
              Image.asset(
                'assets/images/robot_message.png',
                width: 85,
                height: 85,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No current delivery',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: forest,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
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
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => openDelivery(d),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: softMint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: pale,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.asset(
                        d.items.any((x) => x.type == 'Food')
                            ? 'assets/images/food_bag.png'
                            : 'assets/images/parcel_box.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'CONVY Robot #01  •  Locker ${d.locker}',
                            style: const TextStyle(fontSize: 12, color: muted),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            d.scheduled
                                ? 'Scheduled • ${d.pickup}'
                                : 'ETA ${d.trackingStartedAt == null ? 6 : DeliveryClock.etaMinutes(d.trackingStartedAt!)} min • Prototype',
                            style: const TextStyle(
                              fontSize: 12,
                              color: green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      const SizedBox(height: 25),
      Row(
        children: [
          const Expanded(child: SectionTitle('Robot Status')),
          const Icon(Icons.circle, color: green, size: 9),
          const SizedBox(width: 6),
          const Text(
            'A-01  Available',
            style: TextStyle(
              color: green,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      InkWell(
        onTap: request,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 16, 12),
          decoration: softCard(radius: 23),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/images/robot_message.png',
                  width: 90,
                  height: 82,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const RobotArt(size: 80),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
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
              const Icon(
                Icons.wifi_tethering_rounded,
                color: Color(0xFF91BE91),
                size: 47,
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
            child: const Text('View All', style: TextStyle(color: green)),
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
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Dismissible(
                  key: ValueKey(d.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteHistoryFromDatabase(d),
                  child: Container(
                    decoration: softCard(radius: 19),
                    child: ListTile(
                      onTap: () => openDelivery(d),
                      leading: Image.asset(
                        d.items.any((x) => x.type == 'Food')
                            ? 'assets/images/food_bag.png'
                            : 'assets/images/parcel_box.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.inventory_2_outlined),
                      ),
                      title: Text(
                        d.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${formatStamp(d.completedAt ?? d.createdAt)}${d.isDemo ? ' • Demo' : ''}',
                        style: const TextStyle(fontSize: 11, color: muted),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDEFD8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Delivered',
                          style: TextStyle(
                            color: green,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
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

  Widget _track() {
    if (deliveries.isEmpty) {
      return const RobotTrackingPage(
        key: ValueKey('community-preview'),
        previewOnly: true,
      );
    }
    final d = deliveries.first;
    if (d.trackingStartedAt == null) {
      return const RobotTrackingPage(
        key: ValueKey('community-preview'),
        previewOnly: true,
      );
    }
    return RobotTrackingPage(
      key: ValueKey(d.id),
      locker: d.locker,
      destination: d.destination,
      deliveryId: d.id,
      startedAt: d.trackingStartedAt,
      onComplete: () => completeTracking(d),
    );
  }

  String historyFilter = 'All';

  Widget _history() {
    final filtered = history
        .where(
          (d) =>
              historyFilter == 'All' ||
              d.items.any((item) => item.type == historyFilter),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        const SectionTitle('Delivery History'),
        const SizedBox(height: 14),
        Row(
          children: ['All', 'Parcel', 'Food']
              .map(
                (filter) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(filter, textAlign: TextAlign.center),
                      ),
                      selected: historyFilter == filter,
                      showCheckmark: false,
                      selectedColor: forest,
                      backgroundColor: const Color(0xFFEBEEEA),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: historyFilter == filter ? Colors.white : forest,
                      ),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (_) => setState(() => historyFilter = filter),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const EmptyCard('No deliveries in this category yet')
        else
          ...filtered.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Dismissible(
                key: ValueKey(d.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteHistoryFromDatabase(d),
                child: Container(
                  decoration: softCard(radius: 19),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    onTap: () => openDelivery(d),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        d.proofImage,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.inventory_2_outlined),
                      ),
                    ),
                    title: Text(
                      d.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: forest,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          formatStamp(d.completedAt ?? d.createdAt),
                          style: const TextStyle(fontSize: 12, color: muted),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Delivered',
                          style: TextStyle(
                            fontSize: 12,
                            color: green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteHistoryFromDatabase(d),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: forest),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w900,
      color: forest,
      letterSpacing: -.4,
    ),
  );
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
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 53,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: forest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

class EmptyCard extends StatelessWidget {
  const EmptyCard(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
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

class RobotArt extends StatelessWidget {
  const RobotArt({super.key, this.size = 100});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _RobotPainter()),
  );
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

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    required this.notices,
    required this.changed,
    required this.onOpenDelivery,
    super.key,
  });
  final ValueChanged<int> onOpenDelivery;
  final List<Notice> notices;
  final VoidCallback changed;
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  void mark(Notice n) {
    setState(() => n.read = true);
    widget.changed();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      backgroundColor: canvas,
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              for (final n in widget.notices) {
                n.read = true;
              }
            });
            widget.changed();
          },
          child: const Text('Mark all as read'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: widget.notices
          .map(
            (n) => Card(
              color: n.read ? Colors.white : const Color(0xFFEAF3E9),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: Stack(
                  children: [
                    const CircleAvatar(
                      backgroundColor: pale,
                      child: Icon(Icons.notifications_none, color: forest),
                    ),
                    if (!n.read)
                      const Positioned(
                        right: 0,
                        top: 0,
                        child: CircleAvatar(
                          radius: 5,
                          backgroundColor: Color(0xFFD94E45),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  n.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(n.body),
                ),
                trailing: n.read ? const Icon(Icons.done, color: green) : null,
                onTap: () {
                  mark(n);
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      title: Text(n.title),
                      content: Text(n.body),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Close'),
                        ),
                        if (n.deliveryId != null)
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              widget.onOpenDelivery(n.deliveryId!);
                            },
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('View Proof of Delivery'),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          )
          .toList(),
    ),
  );
}

class RequestPage extends StatefulWidget {
  const RequestPage({
    required this.id,
    required this.username,
    required this.userHouseNo,
    super.key,
  });

  final int id;
  final String username;
  final String userHouseNo;

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final form = GlobalKey<FormState>();
  late final TextEditingController locker;
  late final TextEditingController destination;
  final List<ParcelItem> items = [ParcelItem(type: 'Parcel', size: 'Medium')];
  bool schedule = false;
  bool isSubmitting = false;
  DateTime? date;
  TimeOfDay? time;

  @override
  void initState() {
    super.initState();
    locker = TextEditingController(text: 'B-08');
    destination = TextEditingController(text: widget.userHouseNo);
  }

  @override
  void dispose() {
    locker.dispose();
    destination.dispose();
    super.dispose();
  }

  Future<void> chooseDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (!mounted || pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: time ?? TimeOfDay.now(),
    );
    if (!mounted || pickedTime == null) return;
    setState(() {
      date = pickedDate;
      time = pickedTime;
    });
  }

  Future<void> submit() async {
    if (isSubmitting) return;
    if (!form.currentState!.validate()) return;

    if (schedule && (date == null || time == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup date and time.')),
      );
      return;
    }

    if (schedule) {
      final chosen = DateTime(
        date!.year,
        date!.month,
        date!.day,
        time!.hour,
        time!.minute,
      );
      if (!chosen.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please choose a future pickup time.')),
        );
        return;
      }
    }

    final when = schedule
        ? '${date!.day}/${date!.month}/${date!.year}  ${time!.format(context)}'
        : 'As soon as possible';

    final delivery = Delivery(
      id: widget.id,
      items: items.map((x) => ParcelItem(type: x.type, size: x.size)).toList(),
      locker: locker.text.trim(),
      destination: destination.text.trim(),
      pickup: when,
      scheduled: schedule,
    );

    setState(() => isSubmitting = true);

    try {
      final uri = Uri.parse('$apiBaseUrl/api/requests');
      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': widget.username,
              'id': delivery.id,
              'items': delivery.items
                  .map((item) => {'type': item.type, 'size': item.size})
                  .toList(),
              'locker': delivery.locker,
              'destination': delivery.destination,
              'pickup': delivery.pickup,
              'scheduled': delivery.scheduled,
              'createdAt': delivery.createdAt.toIso8601String(),
              'displayName': delivery.title,
            }),
          )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> result = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) result = decoded;
      } catch (_) {}

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          result['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context, delivery);
        return;
      }

      final message =
          result['message'] ??
          result['error'] ??
          'Server rejected the request (HTTP ${response.statusCode}).';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save request: $message')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not connect to the server. Check the backend and try again. ($e)',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Request a Robot'),
      backgroundColor: canvas,
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Image.asset(
            'assets/images/robot_message.png',
            height: 135,
            fit: BoxFit.contain,
          ),
          const Text(
            "Let's get your items moving.",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: forest,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Fill in the details below to request a delivery robot.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Pickup details'),
          const SizedBox(height: 12),
          TextFormField(
            controller: locker,
            decoration: field('Locker number', Icons.lock_outline),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter a locker number' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: destination,
            decoration: field('Destination', Icons.home_outlined),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter a destination' : null,
          ),
          const SizedBox(height: 24),
          const SectionTitle('Pickup time'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChoiceTile(
                  icon: Icons.bolt_rounded,
                  title: 'As soon as',
                  subtitle: 'possible',
                  selected: !schedule,
                  onTap: () => setState(() => schedule = false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceTile(
                  icon: Icons.calendar_month_outlined,
                  title: 'Schedule',
                  subtitle: 'Choose a time',
                  selected: schedule,
                  onTap: () {
                    setState(() => schedule = true);
                    chooseDateTime();
                  },
                ),
              ),
            ],
          ),
          if (schedule)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: chooseDateTime,
                icon: const Icon(Icons.event),
                label: Text(
                  date == null || time == null
                      ? 'Choose another date & time'
                      : '${date!.day}/${date!.month}/${date!.year}  ${time!.format(context)}',
                ),
              ),
            ),
          const SizedBox(height: 25),
          Row(
            children: [
              const Expanded(child: SectionTitle('Items to collect')),
              Text(
                '${items.length} item(s)',
                style: const TextStyle(
                  color: green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(
            items.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: softCard(radius: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ITEM ${i + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: forest,
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        if (items.length > 1)
                          IconButton(
                            onPressed: () => setState(() => items.removeAt(i)),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFB85C55),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Center(
                      child: Image.asset(
                        items[i].type == 'Food'
                            ? 'assets/images/food_bag.png'
                            : 'assets/images/parcel_box.png',
                        height: 82,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const Text(
                      'Delivery type',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceTile(
                            icon: Icons.inventory_2_outlined,
                            title: 'Parcel',
                            selected: items[i].type == 'Parcel',
                            onTap: () =>
                                setState(() => items[i].type = 'Parcel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceTile(
                            icon: Icons.lunch_dining_outlined,
                            title: 'Food',
                            selected: items[i].type == 'Food',
                            onTap: () => setState(() => items[i].type = 'Food'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Item size',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        for (final size in ['Small', 'Medium', 'Large']) ...[
                          Expanded(
                            child: ChoiceTile(
                              icon: size == 'Small'
                                  ? Icons.check_box_outline_blank
                                  : size == 'Medium'
                                  ? Icons.crop_square_rounded
                                  : Icons.inventory_2_outlined,
                              title: size,
                              subtitle: size == 'Small'
                                  ? 'Up to 1 kg'
                                  : size == 'Medium'
                                  ? '1 - 5 kg'
                                  : '5 - 10 kg',
                              selected: items[i].size == size,
                              onTap: () => setState(() => items[i].size = size),
                            ),
                          ),
                          if (size != 'Large') const SizedBox(width: 7),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => setState(
              () => items.add(ParcelItem(type: 'Parcel', size: 'Medium')),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add another item'),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            isSubmitting ? 'SAVING REQUEST...' : 'CONFIRM REQUEST',
            onPressed: isSubmitting ? null : submit,
            icon: isSubmitting ? Icons.hourglass_top : Icons.arrow_forward,
          ),
          const SizedBox(height: 12),
          const Text(
            'Demo only - Robot capacity and locker availability are not verified',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

InputDecoration field(String label, IconData icon) => InputDecoration(
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
  Widget build(BuildContext context) => InkWell(
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

String formatStamp(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final ampm = date.hour < 12 ? 'AM' : 'PM';
  return '${date.day}/${date.month}/${date.year}  $hour:$minute $ampm';
}

class SuccessPage extends StatelessWidget {
  const SuccessPage({required this.delivery, super.key});
  final Delivery delivery;
  @override
  Widget build(BuildContext context) => Scaffold(
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

Widget detailRow(String name, String value) => Padding(
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
    _refresh = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  DateTime _milestoneTime(Delivery d, int index) {
    if (index == 0) return d.createdAt;

    if (d.isDemo) {
      const offsets = [0, 1, 3, 4, 7];
      return d.createdAt.add(Duration(minutes: offsets[index]));
    }

    final started = d.trackingStartedAt ?? d.createdAt;
    if (index == 4 && d.completedAt != null) return d.completedAt!;

    final targetOffset =
        (DeliveryClock.duration.inMilliseconds *
                DeliveryClock.stageThreshold(index))
            .round();

    return started.add(Duration(milliseconds: targetOffset));
  }

  String _timelineStamp(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    final suffix = value.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute:$second $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.delivery;

    final progress = (d.completedAt != null || (d.isDemo && d.progress >= 3))
        ? 4
        : d.trackingStartedAt == null
        ? 0
        : DeliveryClock.stage(d.trackingStartedAt!);

    final eta = d.trackingStartedAt == null
        ? 6
        : DeliveryClock.etaMinutes(d.trackingStartedAt!);

    return Scaffold(
      appBar: AppBar(title: Text('Delivery #${d.id}'), backgroundColor: canvas),
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
                  errorBuilder: (context, error, stackTrace) {
                    return const RobotArt(size: 145);
                  },
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  d.title,
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
                  'Locker ${d.locker} • ${d.destination}',
                  style: const TextStyle(color: muted),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  progress == 4
                      ? 'Delivered'
                      : d.trackingStartedAt == null
                      ? 'Awaiting robot'
                      : 'En Route • ETA $eta min',
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
                                        ? _timelineStamp(_milestoneTime(d, i))
                                        : 'Pending',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: i <= progress ? green : muted,
                                    ),
                                  ),
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
                      MaterialPageRoute(builder: (_) => ProofPage(delivery: d)),
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
                          setState(() {
                            d.rating = i;
                          });
                        },
                        icon: Icon(
                          i <= d.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFF1B544),
                          size: 34,
                        ),
                      ),
                  ],
                ),

                TextFormField(
                  key: ValueKey('feedback_${d.id}'),
                  initialValue: d.feedback,
                  onChanged: (value) {
                    d.feedback = value;
                  },
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
                    setState(() {});

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feedback saved!')),
                    );

                    Navigator.pop(context);
                  },
                  icon: Icons.favorite_outline_rounded,
                ),
              ],

              const SizedBox(height: 20),

              const Text(
                'Prototype • Delivery stages and locations are simulated.',
                style: TextStyle(color: muted, fontSize: 12),
              ),

              const SizedBox(height: 18),

              if (d.trackingStartedAt != null && d.completedAt == null)
                PrimaryButton(
                  'TRACK ROBOT',
                  onPressed: widget.onTrack,
                  icon: Icons.location_on_outlined,
                ),

              if (d.trackingStartedAt == null && d.completedAt == null)
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

class ProofPage extends StatelessWidget {
  const ProofPage({required this.delivery, super.key});
  final Delivery delivery;
  @override
  Widget build(BuildContext context) => Scaffold(
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
          child: Image.asset(delivery.proofImage, fit: BoxFit.contain),
        ),
        const SizedBox(height: 12),
        Text(
          'Photo proof • ${formatStamp(delivery.completedAt ?? delivery.createdAt)}',
          style: const TextStyle(color: muted),
        ),
        const SizedBox(height: 8),
        const Text(
          'Prototype only • This is a simulated delivery photo, not a live robot capture.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ],
    ),
  );
}
