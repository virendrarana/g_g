// import 'package:quantupi/quantupi.dart';
//
// class PaymentService {
//   // UPI payment using quantupi
//   Future<String?> startUpiPayment({
//     required String upiId,
//     required String receiverName,
//     required double amount,
//     required String transactionNote,
//   }) async {
//     try {
//       // Initialize the UPI payment
//       Quantupi upi = Quantupi(
//         receiverUpiId: upiId,
//         receiverName: receiverName,
//         transactionRefId: 'Order${DateTime.now().millisecondsSinceEpoch}',
//         transactionNote: transactionNote,
//         amount: amount,
//       );
//
//       // Initiate the payment
//       final response = await upi.startTransaction();
//       return response;
//     } catch (e) {
//       throw Exception('UPI payment failed: $e');
//     }
//   }
// }
