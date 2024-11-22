import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear(); // Clean up the instance
    super.dispose();
  }

  void openCheckout() {
    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Replace with your API key
      'amount': 50000, // Amount in paise (500 INR)
      'name': 'Test Payment',
      'description': 'Order #1234',
      'prefill': {'contact': '9876543210', 'email': 'test@example.com'},
      'theme': {'color': '#3399cc'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('Payment successful: ${response.paymentId}');
    // Perform further actions like order confirmation
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External wallet selected: ${response.walletName}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Razorpay Payment')),
      body: Center(
        child: ElevatedButton(
          onPressed: openCheckout,
          child: Text('Pay Now'),
        ),
      ),
    );
  }
}
