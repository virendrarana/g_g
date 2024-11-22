import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> updateWalletAfterOrder(String userId, int earnedPoints) async {
  final walletRef = FirebaseFirestore.instance.collection('wallets').doc(userId);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(walletRef);

    if (snapshot.exists) {
      int currentPoints = snapshot['points'];
      transaction.update(walletRef, {'points': currentPoints + earnedPoints});
    }
  });

  // Optionally, add a transaction history entry
  await walletRef.update({
    'transactionHistory': FieldValue.arrayUnion([
      {
        'transactionId': 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        'pointsAdded': earnedPoints,
        'description': 'Points earned from order',
        'timestamp': FieldValue.serverTimestamp(),
      }
    ])
  });
}
