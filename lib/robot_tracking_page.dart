import 'dart:math' as math;
import 'package:flutter/material.dart';

const _forest = Color(0xFF173F32);
const _green = Color(0xFF13A66B);
const _muted = Color(0xFF718077);

/// Functional prototype: movement is simulated on a conceptual map, not GPS.
class RobotTrackingPage extends StatefulWidget {
  const RobotTrackingPage({super.key, this.locker = 'B-08',
    this.destination = 'House A-12', this.deliveryId, this.startedAt,
    this.onComplete, this.previewOnly = false});
  final String locker, destination;
  final int? deliveryId;
  final DateTime? startedAt;
  final VoidCallback? onComplete;
  final bool previewOnly;

  @override
  State<RobotTrackingPage> createState() => _RobotTrackingPageState();
}

class _RobotTrackingPageState extends State<RobotTrackingPage>
    with SingleTickerProviderStateMixin {
  static const double mapW = 1536;
  static const double mapH = 1024;
  static const duration = Duration(minutes: 6);

  // Road-only waypoints on assets/images/community_map.png (1536x1024).
  // Start on the residential road, stop outside the Parcel Room (index 6),
  // follow the outer road northwest, turn at the marked intersection,
  // and finish at the curb outside a distant house entrance.
  // No rooftop shortcuts or driveway/parked-car endpoints.
  static const List<Offset> road = [
    Offset(1380, 760),
    Offset(1394, 725),
    Offset(1405, 692),
    Offset(1400, 663),
    Offset(1385, 646),
    Offset(1360, 630),
    Offset(1325, 609), // Parcel Room: stop on road
    Offset(1290, 586),
    Offset(1250, 562),
    Offset(1210, 539),
    Offset(1175, 513),
    Offset(1140, 486),
    Offset(1124, 461),
    Offset(1126, 431),
    Offset(1124, 399),
    Offset(1115, 366),
    Offset(1095, 335),
    Offset(1069, 307),
    Offset(1039, 280),
    Offset(1005, 249),
    Offset(971, 223),
    Offset(934, 194),
    Offset(899, 169),
    Offset(862, 143),
    Offset(830, 121),
    Offset(806, 133),
    Offset(786, 160),
    Offset(763, 185),
    Offset(742, 212),
    Offset(720, 239),
    Offset(699, 267),
    Offset(674, 297),
    Offset(649, 324),
    Offset(622, 352),
    Offset(596, 375),
    Offset(571, 398), // Destination: curb outside house entrance
  ];
  static const double parcelStopStart = .29;
  static const double parcelStopEnd = .43;
  static const Offset parcelRoom = Offset(1325, 609);

  late final AnimationController _controller;
  final TransformationController _mapController = TransformationController();
  late final DateTime _startedAt;
  bool _completed = false;
  Size? _lastViewport;
  double _minScale = .3;
  double _maxScale = 3;
  bool _followRobot = true;

  @override
  void initState() {
    super.initState();
    _startedAt = widget.startedAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(_startedAt);
    final initial = (elapsed.inMilliseconds / duration.inMilliseconds)
        .clamp(0.0, 1.0);
    _controller = AnimationController(vsync: this, duration: duration)
      ..value = initial;
    _controller.addListener(() {
      if (_controller.isCompleted && !_completed) _notifyCompleted();
      if (mounted) {
        final viewport = _lastViewport;
        if (!widget.previewOnly && _followRobot && viewport != null) {
          _setCamera(_mapController.value.getMaxScaleOnAxis(),
            _roadPosition(_routeFraction(_controller.value)), viewport);
        }
        setState(() {});
      }
    });
    if (widget.previewOnly) {
      _controller.value = 0;
    } else if (initial >= 1) {
      _notifyCompleted();
    } else {
      _controller.forward();
    }
  }

  void _notifyCompleted() {
    if (_completed) return;
    _completed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Clamp every programmatic camera change to the image bounds. The image
  // always covers the viewport, so there is no draggable white area.
  void _setCamera(double scale, Offset focus, Size viewport) {
    final minimum = math.max(viewport.width / mapW, viewport.height / mapH);
    final safeScale = scale.clamp(minimum, _maxScale).toDouble();
    final rawX = viewport.width / 2 - focus.dx * safeScale;
    final rawY = viewport.height / 2 - focus.dy * safeScale;
    final tx = rawX.clamp(viewport.width - mapW * safeScale, 0.0).toDouble();
    final ty = rawY.clamp(viewport.height - mapH * safeScale, 0.0).toDouble();
    _mapController.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(safeScale, safeScale, 1, 1);
  }

  void _fitMap(Size viewport) {
    if (viewport.width <= 0 || viewport.height <= 0) return;
    _minScale = math.max(viewport.width / mapW, viewport.height / mapH);
    _maxScale = math.max(3.0, _minScale * 5);
    // Preview: start near the middle so park and houses can be explored.
    // Tracking: show the residential road and the current robot.
    final focus = widget.previewOnly ? const Offset(740, 420)
        : _roadPosition(_routeFraction(_controller.value));
    _setCamera(_minScale * 1.6, focus, viewport);
  }

  void _zoom(double factor) {
    final viewport = _lastViewport;
    if (viewport == null) return;
    final current = _mapController.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(_minScale, _maxScale).toDouble();
    final center = Offset(viewport.width / 2, viewport.height / 2);
    final scenePoint = _mapController.toScene(center);
    _setCamera(next, scenePoint, viewport);
  }

  @override
  Widget build(BuildContext context) {
    final p = _controller.value;
    final done = !widget.previewOnly && p >= 1;
    final eta = done ? 0 : math.max(1, ((1 - p) * 6).ceil());
    final routeP = _routeFraction(p);
    final atParcelRoom = !widget.previewOnly &&
        p >= parcelStopStart && p < parcelStopEnd;
    final pos = _roadPosition(routeP);
    return Stack(children: [
      Positioned.fill(child: LayoutBuilder(builder: (context, bounds) {
        final viewport = Size(bounds.maxWidth, bounds.maxHeight);
        if (_lastViewport != viewport) {
          _lastViewport = viewport;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fitMap(viewport);
          });
        }
        return ClipRect(child: InteractiveViewer(
          transformationController: _mapController,
          constrained: false,
          boundaryMargin: EdgeInsets.zero,
          minScale: _minScale,
          maxScale: _maxScale,
          onInteractionStart: (_) => _followRobot = false,
          panEnabled: true,
          scaleEnabled: true,
          child: SizedBox(width: mapW, height: mapH,
            child: Stack(children: [
              Positioned.fill(child: Image.asset(
                'assets/images/community_map.png', fit: BoxFit.fill,
                errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Color(0xFFDDE8D8)))),
              if (!widget.previewOnly) Positioned.fill(child: CustomPaint(
                painter: _RoadPainter(road: road, progress: routeP))),
              if (!widget.previewOnly) Positioned(
                left: parcelRoom.dx - 17, top: parcelRoom.dy - 37,
                child: const Icon(Icons.inventory_2_rounded,
                  size: 30, color: Color(0xFFE3A22E),
                  shadows: [Shadow(color: Colors.white, blurRadius: 6)])),
              if (!widget.previewOnly) Positioned(
                left: road.last.dx - 10, top: road.last.dy - 30,
                child: const Icon(Icons.home_rounded, size: 20,
                  color: _forest, shadows: [Shadow(
                    color: Colors.white, blurRadius: 6)])),
              if (!widget.previewOnly) Positioned(left: pos.dx - 12, top: pos.dy - 12,
                child: Container(width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .85),
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(
                      color: Color(0x44000000), blurRadius: 7)]),
                  child: Image.asset('assets/images/convey_robot.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                      const Icon(Icons.smart_toy, color: _forest)))),
            ])),
        ));
      })),
      Positioned(left: 0, right: 0, top: 0,
        child: Container(height: 60, color: const Color(0xF7F8F8F3),
          child: Row(children: [
            IconButton(onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19)),
            Expanded(child: Text(widget.previewOnly ? 'Explore Our Community' : 'Live Tracking',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.w800, color: _forest))),
            const SizedBox(width: 48),
          ]))),
      Positioned(top: 75, right: 14, child: Column(children: [
        _mapButton(Icons.add, () => _zoom(1.3)),
        const SizedBox(height: 9),
        _mapButton(Icons.remove, () => _zoom(1 / 1.3)),
        const SizedBox(height: 9),
        _mapButton(Icons.my_location_rounded, () {
          final viewport = _lastViewport;
          if (viewport == null) return;
          final scale = _mapController.value.getMaxScaleOnAxis();
          final focus = widget.previewOnly ? const Offset(800, 410)
              : _roadPosition(_routeFraction(_controller.value));
          _followRobot = !widget.previewOnly;
          _setCamera(scale, focus, viewport);
        }),
      ])),
      if (widget.previewOnly) Positioned(left: 0, right: 0, bottom: 0,
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: const Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.map_outlined, color: _green, size: 28),
              SizedBox(height: 6),
              Text('No delivery on the move yet!',
                style: TextStyle(color: _forest, fontWeight: FontWeight.w800, fontSize: 17)),
              SizedBox(height: 5),
              Text('Explore the neighbourhood while your CONVY robot takes a break.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 12)),
            ]))))) ,
      if (!widget.previewOnly) Positioned(left: 0, right: 0, bottom: 0,
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Color(0x15000000), blurRadius: 20)]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 42, height: 5,
                decoration: BoxDecoration(color: const Color(0xFFD4D6D3),
                  borderRadius: BorderRadius.circular(9))),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft,
                child: Text(done ? 'Your delivery has arrived!'
                    : atParcelRoom ? 'CONVY is stopping at Parcel Room' : p < parcelStopStart ? 'CONVY is heading to Parcel Room' : 'CONVY is on the way to your home',
                  style: const TextStyle(fontSize: 19,
                    fontWeight: FontWeight.w900, color: _forest))),
              const SizedBox(height: 18),
              Row(children: [
                _stage(Icons.inventory_2_outlined, 'Collected', 'Done', true),
                Expanded(child: Container(height: 3, color: _green)),
                _stage(Icons.inventory_2_outlined, 'Parcel Room',
                  atParcelRoom ? 'Collecting' : p >= parcelStopEnd ? 'Done' : 'Next',
                  p >= parcelStopStart),
                Expanded(child: Container(height: 3,
                  color: done ? _green : const Color(0xFFE0E3E0))),
                _stage(Icons.home_rounded, done ? 'Arrived' : 'En Route',
                  done ? 'Done' : 'ETA $eta min', p >= parcelStopEnd),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Image.asset('assets/images/convey_robot.png',
                  width: 55, height: 55, fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.smart_toy,
                    size: 44, color: _forest)),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CONVY Robot #01',
                      style: TextStyle(fontWeight: FontWeight.w800, color: _forest)),
                    const SizedBox(height: 3),
                    Text(done ? 'Delivery completed' : atParcelRoom ? 'Collecting your items at Parcel Room' : p < parcelStopStart ? 'Heading to Parcel Room' : 'Carrying your items',
                      style: const TextStyle(color: _muted, fontSize: 12)),
                  ])),
                Container(padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFE8F3EC),
                    borderRadius: BorderRadius.circular(14)),
                  child: Column(children: [
                    Text(done ? 'STATUS' : 'ETA',
                      style: const TextStyle(fontSize: 11, color: _forest)),
                    Text(done ? 'Delivered' : '$eta min',
                      style: const TextStyle(fontSize: 20,
                        fontWeight: FontWeight.w900, color: _forest)),
                  ])),
              ]),
              const SizedBox(height: 10),
              const Text('Prototype tracking · Simulated robot location',
                style: TextStyle(color: _muted, fontSize: 10)),
            ]))))),
    ]);
  }

  Widget _mapButton(IconData icon, VoidCallback onPressed) => Material(
    color: Colors.white, elevation: 3, shape: const CircleBorder(),
    child: IconButton(onPressed: onPressed,
      icon: Icon(icon, color: _forest), iconSize: 21));

  Widget _stage(IconData icon, String label, String subtitle, bool active) =>
    SizedBox(width: 88, child: Column(children: [
      CircleAvatar(radius: 19,
        backgroundColor: active ? _green : const Color(0xFFE1E3E1),
        child: Icon(icon, color: active ? Colors.white : _muted, size: 20)),
      const SizedBox(height: 5),
      Text(label, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11,
          fontWeight: FontWeight.w700, color: _forest)),
      Text(subtitle, style: const TextStyle(fontSize: 10, color: _muted)),
    ]));

  static double _routeFraction(double time) {
    // Pause exactly at the Parcel Room waypoint, then continue.
    // Map progress by elapsed time rather than animation pause, so it survives navigation.
    final stop = _fractionToWaypoint(6);
    if (time <= parcelStopStart) return stop * time / parcelStopStart;
    if (time < parcelStopEnd) return stop;
    return stop + (1 - stop) * (time - parcelStopEnd) / (1 - parcelStopEnd);
  }

  static double _fractionToWaypoint(int waypoint) {
    var total = 0.0;
    var partial = 0.0;
    for (var i = 0; i < road.length - 1; i++) {
      final segment = (road[i + 1] - road[i]).distance;
      total += segment;
      if (i < waypoint) partial += segment;
    }
    return total == 0 ? 0 : partial / total;
  }

  static Offset _roadPosition(double t) {
    final lengths = <double>[];
    var total = 0.0;
    for (var i = 0; i < road.length - 1; i++) {
      final length = (road[i + 1] - road[i]).distance;
      lengths.add(length);
      total += length;
    }
    var remaining = total * t.clamp(0.0, 1.0);
    for (var i = 0; i < lengths.length; i++) {
      if (remaining <= lengths[i]) {
        return Offset.lerp(road[i], road[i + 1],
          lengths[i] == 0 ? 0 : remaining / lengths[i])!;
      }
      remaining -= lengths[i];
    }
    return road.last;
  }
}

class _RoadPainter extends CustomPainter {
  const _RoadPainter({required this.road, required this.progress});
  final List<Offset> road;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (road.length < 2) return;
    final path = Path()..moveTo(road.first.dx, road.first.dy);
    for (var i = 1; i < road.length; i++) {
      path.lineTo(road[i].dx, road[i].dy);
    }
    canvas.drawPath(path, Paint()
      ..color = Colors.white.withValues(alpha: .80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
    canvas.drawPath(path, Paint()
      ..color = _green.withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
    // Highlight the already-travelled part of the route.
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), Paint()
        ..color = const Color(0xFF8DE3B4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.road != road;
}
