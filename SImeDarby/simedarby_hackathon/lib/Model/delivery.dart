class Delivery {
  Delivery({
    required this.id,
    required this.items,
    required this.locker,
    required this.destination,
    required this.pickup,
    required this.scheduled,
    DateTime? createdAt,
    this.displayName,
    this.isDemo = false,
  }) : createdAt = createdAt ?? DateTime.now();

  final int id;
  final List<ParcelItem> items;
  final String locker;
  final String destination;
  final String pickup;
  final bool scheduled;
  final String? displayName;
  final bool isDemo;
  final DateTime createdAt;

  DateTime? completedAt;
  int progress = 0;
  int rating = 0;
  String feedback = '';
  DateTime? trackingStartedAt;

  String get title =>
      displayName ??
      (items.length == 1
          ? '${items.first.type} Delivery'
          : '${items.length} Items Delivery');

  String get proofImage {
    switch (id) {
      case 901:
        return 'assets/images/proof_mcd.png';
      case 902:
        return 'assets/images/proof_shopee.png';
      case 903:
        return 'assets/images/proof_generic_food.png';
      case 904:
        return 'assets/images/proof_tealive.png';
      case 905:
        return 'assets/images/proof_mixed.png';
      case 906:
        return 'assets/images/proof_box.png';
      default:
        if (items.length > 1) {
          return 'assets/images/proof_mixed.png';
        }

        return items.any((item) => item.type == 'Food')
            ? 'assets/images/proof_generic_food.png'
            : 'assets/images/proof_box.png';
    }
  }
}

class ParcelItem {
  ParcelItem({required this.type, required this.size});

  String type;
  String size;
}
