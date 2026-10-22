import 'package:flutter/material.dart';

import 'package:simedarby_hackathon/app_theme.dart';
import 'package:simedarby_hackathon/Model/delivery.dart';
import 'package:simedarby_hackathon/widgets/convey_widgets.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({required this.id, super.key});

  final int id;

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final form = GlobalKey<FormState>();
  final locker = TextEditingController(text: 'B-08');
  final destination = TextEditingController(text: 'House A-12');

  final List<ParcelItem> items = [ParcelItem(type: 'Parcel', size: 'Medium')];

  bool schedule = false;
  DateTime? date;
  TimeOfDay? time;

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

  void submit() {
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
        ? '${date!.day}/${date!.month}/${date!.year}  '
              '${time!.format(context)}'
        : 'As soon as possible';

    final delivery = Delivery(
      id: widget.id,
      items: items
          .map((item) => ParcelItem(type: item.type, size: item.size))
          .toList(),
      locker: locker.text.trim(),
      destination: destination.text.trim(),
      pickup: when,
      scheduled: schedule,
    );

    Navigator.pop(context, delivery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              'Let’s get your items moving.',
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
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a locker number'
                  : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: destination,
              decoration: field('Destination', Icons.home_outlined),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a destination'
                  : null,
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
                        : '${date!.day}/${date!.month}/${date!.year}  '
                              '${time!.format(context)}',
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

            ...List.generate(items.length, (index) {
              final item = items[index];

              return Padding(
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
                            'ITEM ${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: forest,
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          if (items.length > 1)
                            IconButton(
                              onPressed: () {
                                setState(() => items.removeAt(index));
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Color(0xFFB85C55),
                              ),
                            ),
                        ],
                      ),

                      Center(
                        child: Image.asset(
                          item.type == 'Food'
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
                              selected: item.type == 'Parcel',
                              onTap: () => setState(() => item.type = 'Parcel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceTile(
                              icon: Icons.lunch_dining_outlined,
                              title: 'Food',
                              selected: item.type == 'Food',
                              onTap: () => setState(() => item.type = 'Food'),
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
                                    ? '1–5 kg'
                                    : '5–10 kg',
                                selected: item.size == size,
                                onTap: () => setState(() => item.size = size),
                              ),
                            ),
                            if (size != 'Large') const SizedBox(width: 7),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            OutlinedButton.icon(
              onPressed: () => setState(
                () => items.add(ParcelItem(type: 'Parcel', size: 'Medium')),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add another item'),
            ),

            const SizedBox(height: 24),

            PrimaryButton(
              'CONFIRM REQUEST',
              onPressed: submit,
              icon: Icons.arrow_forward,
            ),

            const SizedBox(height: 12),
            const Text(
              'Demo only · Robot capacity and locker availability are not verified.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
