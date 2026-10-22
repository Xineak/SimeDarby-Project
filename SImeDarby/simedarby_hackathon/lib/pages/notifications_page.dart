import 'package:flutter/material.dart';

import 'package:simedarby_hackathon/app_theme.dart';
import 'package:simedarby_hackathon/Model/notice.dart';
import 'package:simedarby_hackathon/Model/delivery.dart';
import 'proof_page.dart';

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
  void mark(Notice notice) {
    setState(() => notice.read = true);
    widget.changed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: canvas,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (final notice in widget.notices) {
                  notice.read = true;
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
        children: widget.notices.map((notice) {
          return Card(
            color: notice.read ? Colors.white : const Color(0xFFEAF3E9),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: Stack(
                children: [
                  const CircleAvatar(
                    backgroundColor: pale,
                    child: Icon(Icons.notifications_none, color: forest),
                  ),
                  if (!notice.read)
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
                notice.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(notice.body),
              ),
              trailing: notice.read
                  ? const Icon(Icons.done, color: green)
                  : null,
              onTap: () {
                mark(notice);

                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(notice.title),
                    content: Text(notice.body),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Close'),
                      ),
                      if (notice.deliveryId != null)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            widget.onOpenDelivery(notice.deliveryId!);
                          },
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('View Proof of Delivery'),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
