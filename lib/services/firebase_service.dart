import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _ready = false;
  bool get ready => _ready;

  late FirebaseAuth auth;
  late FirebaseFirestore firestore;
  late FirebaseMessaging messaging;

  Future<void> init() async {
    if (_ready) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    auth = FirebaseAuth.instance;
    firestore = FirebaseFirestore.instance;
    messaging = FirebaseMessaging.instance;

    // Request permission for notifications
    try {
      await messaging.requestPermission();
      // Get FCM token
      final token = await messaging.getToken();
      print('FCM Token: $token');
    } catch (e) {
      print('Error setting up FCM: $e');
    }

    _ready = true;
  }

  // Auth helpers
  Future<UserCredential> signUp(String email, String password) async {
    return await auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Phone authentication
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String verificationId) onCodeSent,
    Function(PhoneAuthCredential credential) onVerificationCompleted,
    Function(FirebaseAuthException error) onVerificationFailed,
  ) async {
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    return await auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithSmsCode(String verificationId, String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await signInWithPhoneCredential(credential);
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  // Firestore helpers
  Future<void> createUserDoc(String uid, Map<String, dynamic> data) async {
    await firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<DocumentReference> createOrder(Map<String, dynamic> order) async {
    final ref = await firestore.collection('orders').add(order);
    return ref;
  }

  Stream<DocumentSnapshot> orderStream(String orderId) {
    return firestore.collection('orders').doc(orderId).snapshots();
  }

  Stream<QuerySnapshot> listOrdersForUser(String userId) {
    return firestore.collection('orders').where('userId', isEqualTo: userId).snapshots();
  }

  Stream<QuerySnapshot> listAllOrders() {
    return firestore.collection('orders').snapshots();
  }

  // Additional methods for complete Firebase integration

  // User profile methods
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await firestore.collection('users').doc(uid).update(data);
  }

  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await firestore.collection('users').doc(uid).get();
  }

  // Services methods
  Future<void> createService(Map<String, dynamic> service) async {
    await firestore.collection('services').add(service);
  }

  Stream<QuerySnapshot> listServices() {
    return firestore.collection('services').snapshots();
  }

  // Comments/Reviews methods
  Future<void> addComment(String orderId, Map<String, dynamic> comment) async {
    await firestore.collection('orders').doc(orderId).collection('comments').add(comment);
  }

  Stream<QuerySnapshot> getCommentsForOrder(String orderId) {
    return firestore.collection('orders').doc(orderId).collection('comments').snapshots();
  }

  // Payments methods
  Future<void> createPayment(Map<String, dynamic> payment) async {
    await firestore.collection('payments').add(payment);
  }

  Future<void> updatePaymentStatus(String paymentId, String status) async {
    await firestore.collection('payments').doc(paymentId).update({'status': status});
  }

  Stream<QuerySnapshot> getPaymentsForOrder(String orderId) {
    return firestore.collection('payments').where('orderId', isEqualTo: orderId).snapshots();
  }

  // Admin codes methods
  Future<bool> validateAdminCode(String code) async {
    try {
      final querySnapshot = await firestore
          .collection('admin_codes')
          .where('code', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error validating admin code: $e');
      return false;
    }
  }

  Future<void> createAdminCode(String code, String description) async {
    await firestore.collection('admin_codes').add({
      'code': code,
      'description': description,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': auth.currentUser?.uid,
    });
  }

  Future<void> deactivateAdminCode(String codeId) async {
    await firestore.collection('admin_codes').doc(codeId).update({
      'isActive': false,
      'deactivatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Admin methods
  Future<void> updateOrderStatus(String orderId, String status) async {
    await firestore.collection('orders').doc(orderId).update({'status': status});
  }

  Future<void> deleteOrder(String orderId) async {
    await firestore.collection('orders').doc(orderId).delete();
  }

  // Notification methods
  Future<String?> getFCMToken() async {
    try {
      return await messaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await messaging.subscribeToTopic(topic);
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  // Update user FCM token
  Future<void> updateUserFCMToken(String userId, String token) async {
    await firestore.collection('users').doc(userId).update({
      'fcmToken': token,
      'lastTokenUpdate': DateTime.now().toIso8601String(),
    });
  }
}

