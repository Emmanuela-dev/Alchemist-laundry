import 'dart:async';
import 'mpesa_service.dart';
import 'mpesa_config.dart';
import 'firebase_service.dart';
import '../models/models.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  /// Initiate M-Pesa payment for an order (Send Money method)
  Future<Map<String, dynamic>> initiatePayment({
    required String orderId,
    required double amount,
    required String phoneNumber,
    required String userId,
  }) async {
    try {
      // Create payment record in Firestore
      final paymentId = DateTime.now().microsecondsSinceEpoch.toString();
      final payment = Payment(
        id: paymentId,
        orderId: orderId,
        userId: userId,
        amount: amount,
        phoneNumber: phoneNumber,
        status: PaymentStatus.pending,
      );

      await FirebaseService.instance.createPayment({
        'id': payment.id,
        'orderId': payment.orderId,
        'userId': payment.userId,
        'amount': payment.amount,
        'phoneNumber': payment.phoneNumber,
        'status': payment.status.name,
        'createdAt': payment.createdAt.toIso8601String(),
      });

      // Return success with send money instructions
      return {
        'success': true,
        'paymentId': paymentId,
        'message': 'Please send KES ${amount.toStringAsFixed(0)} to 0757952937 via M-Pesa. Include your order ID $orderId in the payment description.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Payment initiation failed: $e',
      };
    }
  }


  /// Update payment status in Firestore
  Future<void> _updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? mpesaReceiptNumber,
    String? transactionId,
    String? failureReason,
  }) async {
    final updateData = {
      'status': status.name,
      'completedAt': status == PaymentStatus.completed ? DateTime.now().toIso8601String() : null,
    };

    if (mpesaReceiptNumber != null) {
      updateData['mpesaReceiptNumber'] = mpesaReceiptNumber;
    }

    if (transactionId != null) {
      updateData['transactionId'] = transactionId;
    }

    if (failureReason != null) {
      updateData['failureReason'] = failureReason;
    }

    await FirebaseService.instance.firestore.collection('payments').doc(paymentId).update(updateData);

    // If payment completed, update order status
    if (status == PaymentStatus.completed) {
      final paymentDoc = await FirebaseService.instance.firestore.collection('payments').doc(paymentId).get();
      final orderId = paymentDoc.data()?['orderId'];
      if (orderId != null) {
        await FirebaseService.instance.updateOrderStatus(orderId, 'paid');
      }
    }
  }

  /// Get payment status for an order
  Future<Payment?> getPaymentForOrder(String orderId) async {
    try {
      final querySnapshot = await FirebaseService.instance.firestore
          .collection('payments')
          .where('orderId', isEqualTo: orderId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        return Payment(
          id: data['id'],
          orderId: data['orderId'],
          userId: data['userId'],
          amount: (data['amount'] as num).toDouble(),
          phoneNumber: data['phoneNumber'],
          status: PaymentStatus.values.firstWhere(
            (s) => s.name == data['status'],
            orElse: () => PaymentStatus.pending,
          ),
          mpesaReceiptNumber: data['mpesaReceiptNumber'],
          transactionId: data['transactionId'],
          createdAt: DateTime.parse(data['createdAt']),
          completedAt: data['completedAt'] != null ? DateTime.parse(data['completedAt']) : null,
          failureReason: data['failureReason'],
        );
      }
    } catch (e) {
      print('Error getting payment for order: $e');
    }
    return null;
  }


  /// Process M-Pesa callback (for backend integration)
  Future<void> processMpesaCallback(Map<String, dynamic> callbackData) async {
    final processedData = MpesaService.processCallback(callbackData);

    if (processedData['success'] == true) {
      final checkoutRequestId = processedData['checkoutRequestId'];
      final mpesaReceiptNumber = processedData['mpesaReceiptNumber'];

      // Find payment by checkoutRequestId
      final paymentQuery = await FirebaseService.instance.firestore
          .collection('payments')
          .where('transactionId', isEqualTo: checkoutRequestId)
          .get();

      if (paymentQuery.docs.isNotEmpty) {
        final paymentDoc = paymentQuery.docs.first;
        final paymentId = paymentDoc.id;
        await _updatePaymentStatus(
          paymentId: paymentId,
          status: PaymentStatus.completed,
          mpesaReceiptNumber: mpesaReceiptNumber,
          transactionId: checkoutRequestId,
        );
      }
    }
  }
}