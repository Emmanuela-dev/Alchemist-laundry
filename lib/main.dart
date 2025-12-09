import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/local_repo.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'models/models.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_order_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/admin_services_screen.dart';
import 'screens/customer_care_screen.dart';
import 'screens/map_view_screen.dart';

// Handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  // Handle background message
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService.instance.init();

  // initialize local persistent data
  await LocalRepo.instance.init();

  // initialize firebase (optional) for realtime features
  try {
    await FirebaseService.instance.init();
    print('Firebase initialized successfully');

    // Set up FCM background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.notification?.title}');
      if (message.notification != null) {
        NotificationService.instance.showNotification(
          message.notification!.title ?? 'Notification',
          message.notification!.body ?? '',
        );
      }
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened app: ${message.data}');
      // Handle navigation based on message data
    });

  } catch (e) {
    print('Firebase initialization failed: $e');
    // ignore Firebase init errors in dev until project config is added
  }

  // Determine initial route based on current user
  String initialRoute = '/login';
  final currentUser = LocalRepo.instance.currentUser;
  if (currentUser != null) {
    initialRoute = currentUser.role == UserRole.admin ? '/admin' : '/home';
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String? initialRoute;
  const MyApp({super.key, this.initialRoute});

  @override
  Widget build(BuildContext context) {
    // Professional blue colors palette
    final primaryBlue = const Color(0xFF2196F3); // Professional blue
    final lightBlue = const Color(0xFFBBDEFB); // Light blue
    final darkBlue = const Color(0xFF1976D2); // Dark blue
    final accentBlue = const Color(0xFF90CAF9); // Accent blue
    final surfaceBlue = const Color(0xFFE3F2FD); // Surface blue
    final backgroundBlue = const Color(0xFFF3F9FF); // Background blue

    return MaterialApp(
      title: 'Alchemist Laundry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: backgroundBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: accentBlue,
          tertiary: surfaceBlue,
          surface: Colors.white,
          background: backgroundBlue,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: darkBlue.withOpacity(0.3),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: backgroundBlue.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryBlue.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryBlue.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryBlue, width: 2),
          ),
          labelStyle: TextStyle(color: primaryBlue),
          hintStyle: TextStyle(color: primaryBlue.withOpacity(0.7)),
        ),
      ),
      initialRoute: initialRoute ?? '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const HomeScreen(),
        '/create-order': (_) => const CreateOrderScreen(),
        '/orders': (_) => const OrdersScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/admin': (_) => const AdminScreen(),
        '/admin-services': (_) => const AdminServicesScreen(),
        '/customer-care': (_) => const CustomerCareScreen(),
        '/map': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
          final lat = args == null ? null : (args['lat'] as double? ?? (args['lat'] is int ? (args['lat'] as int).toDouble() : null));
          final lng = args == null ? null : (args['lng'] as double? ?? (args['lng'] is int ? (args['lng'] as int).toDouble() : null));
          final label = args == null ? null : args['label'] as String?;
          return MapViewScreen(lat: lat, lng: lng, label: label);
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/order') {
          final args = settings.arguments as Map<String, dynamic>?;
          final orderId = args?['orderId'] as String?;
          if (orderId != null) {
            return MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: orderId));
          }
        }
        return null;
      },
    );
  }
}
