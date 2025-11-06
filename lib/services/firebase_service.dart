import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _ready = false;
  bool get ready => _ready;

  late FirebaseAuth auth;
  late FirebaseFirestore firestore;

  Future<void> init() async {
    if (_ready) return;
    await Firebase.initializeApp();
    auth = FirebaseAuth.instance;
    firestore = FirebaseFirestore.instance;
  // messaging is optional and added when firebase_messaging is enabled/compatible
    _ready = true;
  }

  // Auth helpers
  Future<UserCredential> signUp(String email, String password) async {
    return await auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await auth.signInWithEmailAndPassword(email: email, password: password);
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

  // Admin methods
  Future<void> updateOrderStatus(String orderId, String status) async {
    await firestore.collection('orders').doc(orderId).update({'status': status});
  }

  Future<void> deleteOrder(String orderId) async {
    await firestore.collection('orders').doc(orderId).delete();
  }
}
