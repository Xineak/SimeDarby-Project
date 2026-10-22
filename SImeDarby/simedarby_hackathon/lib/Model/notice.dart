class Notice {
  Notice(this.title, this.body, {this.read = false, this.deliveryId});

  final int? deliveryId;
  String title;
  String body;
  bool read;
}
