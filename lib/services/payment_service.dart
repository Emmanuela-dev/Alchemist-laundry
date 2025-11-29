import 'dart:async';
import 'mpesa_service.dart';
import 'mpesa_config.dart';
import 'firebase_service.dart';
import '../models/models.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  Timer? _statusCheckTimer;
  int _checkAttempts = 0;

  /// Initiate M-Pesa payment for an order
  Future<Map<String, dynamic>> initiatePayment({
    required String orderId,
    required double amount,
    required String phoneNumber,
    required String userId,
  }) async {
    try {
      // Validate configuration
      final configError = MpesaConfig.validateConfig();
      if (configError != null) {
        return {
          'success': false,
          'error': configError,
        };
      }

      // Create payment record in Firestore
      final paymentId = DateTime.now().microsecondsSinceEpoch.toString();
      final payment = Payment(
        id: paymentId,
        orderId: orderId,
        userId: userId,
        amount: amount,
        phoneNumber: phoneNumber,
        status: PaymentStatus.processing,
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

      // Initiate STK Push
      final stkResult = await MpesaService().initiateSTKPush(
        phoneNumber: phoneNumber,
        amount: amount.toInt(),
        accountReference: MpesaConfig.generateAccountReference(orderId),
      );

      if (stkResult != null && stkResult['success'] == true) {
        // Update payment with STK details
        await FirebaseService.instance.firestore.collection('payments').doc(paymentId).update({
          'transactionId': stkResult['checkoutRequestId'],
          'status': 'processing',
        });

        // Start monitoring payment status
        _monitorPaymentStatus(paymentId, stkResult['checkoutRequestId']);

        return {
          'success': true,
          'paymentId': paymentId,
          'checkoutRequestId': stkResult['checkoutRequestId'],
          'message': stkResult['customerMessage'] ?? 'STK Push sent successfully',
        };
      } else {
        // Update payment status to failed
        await FirebaseService.instance.firestore.collection('payments').doc(paymentId).update({
          'status': 'failed',
          'failureReason': stkResult?['error'] ?? 'STK Push failed',
        });

        return {
          'success': false,
          'error': stkResult?['error'] ?? 'Failed to initiate payment',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Payment initiation failed: $e',
      };
    }
  }

  /// Monitor payment status by periodically checking with M-Pesa
  void _monitorPaymentStatus(String paymentId, String checkoutRequestId) {
    _checkAttempts = 0;
    _statusCheckTimer?.cancel();

    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: MpesaConfig.queryInterval),
      (timer) async {
        _checkAttempts++;

        try {
          final statusResult = await MpesaService().querySTKPushStatus(
            checkoutRequestId: checkoutRequestId,
          );

          if (statusResult != null) {
            final resultCode = statusResult['resultCode'];

            if (resultCode == '0') {
              // Payment successful
              await _updatePaymentStatus(
                paymentId: paymentId,
                status: PaymentStatus.completed,
                mpesaReceiptNumber: statusResult['mpesaReceiptNumber'],
                transactionId: checkoutRequestId,
              );
              timer.cancel();
            } else if (resultCode != null && resultCode != '1032' && resultCode != '1037') {
              // Payment failed (1032 = Timeout, 1037 = DS timeout)
              await _updatePaymentStatus(
                paymentId: paymentId,
                status: PaymentStatus.failed,
                failureReason: statusResult['resultDesc'] ?? 'Payment failed',
              );
              timer.cancel();
            }
          }

          // Stop checking after max attempts
          if (_checkAttempts >= MpesaConfig.maxQueryAttempts) {
            await _updatePaymentStatus(
              paymentId: paymentId,
              status: PaymentStatus.pending,
              failureReason: 'Payment status check timeout',
            );
            timer.cancel();
          }
        } catch (e) {
          print('Error checking payment status: $e');
          if (_checkAttempts >= MpesaConfig.maxQueryAttempts) {
            timer.cancel();
          }
        }
      },
    );
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

  /// Cancel payment monitoring
  void cancelPaymentMonitoring() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
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