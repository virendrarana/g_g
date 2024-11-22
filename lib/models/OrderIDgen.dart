import 'dart:math';

String generateOrderId() {
  final now = DateTime.now();
  final random = Random();
  final orderId = 'ORD-${now.millisecondsSinceEpoch}-${random.nextInt(9999)}';
  return orderId;
}
