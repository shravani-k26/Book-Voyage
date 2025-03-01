import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  final Razorpay _razorpay = Razorpay();

  void processPayment({
    required BuildContext context,
    required String userId,
    required String userEmail,
    required String bookId,
    required int price,
    required VoidCallback onSuccess,
  }) {
    var options = {
      'key': 'rzp_test_hbOeE6rm53Xns2', // Replace with your Razorpay Key ID
      'amount': price * 100, // Razorpay accepts amount in paise
      'currency': 'INR',
      'name': 'Book Voyage',
      'description': 'Purchase Book',
      'prefill': {
        'email': userEmail,
      },
      'theme': {'color': '#9B2226'},
    };

    _razorpay.open(options);

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) {
      _handlePaymentSuccess(response, userId, bookId, context, onSuccess);
    });

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
      _handlePaymentError(response, context);
    });

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (response) {
      _handleExternalWallet(response, context);
    });
  }

  void _handlePaymentSuccess(
      PaymentSuccessResponse response, String userId, String bookId, BuildContext context, VoidCallback onSuccess) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('purchases')
        .doc(bookId)
        .set(
        {
          'purchasedAt': DateTime.now(),
          'isPurchased': true,
        }
    ).then((_) {
      onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Successful!")));
    });
  }

  void _handlePaymentError(PaymentFailureResponse response, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Failed")));
  }

  void _handleExternalWallet(ExternalWalletResponse response, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Wallet Used: ${response.walletName}")));
  }

  void dispose() {
    _razorpay.clear();
  }
}
