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
}
