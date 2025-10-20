import 'package:flutter/material.dart';
import 'services/local_repo.dart';
import 'services/firebase_service.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_order_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize local persistent data
  await LocalRepo.instance.init();
    // initialize firebase (optional) for realtime features
    try {
      await FirebaseService.instance.init();
    } catch (_) {
      // ignore Firebase init errors in dev until project config is added
    }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Beautiful baby colors palette
    final babyPink = const Color(0xFFFFC1CC); // Soft baby pink
    final babyPinkLight = const Color(0xFFFFD1DC); // Lighter baby pink
    final babyPinkDark = const Color(0xFFFFA8B8); // Darker baby pink
    final babyBlue = const Color(0xFFB8E6FF); // Soft baby blue
    final babyPurple = const Color(0xFFE1BEE7); // Soft baby purple
    final babyGreen = const Color(0xFFC8E6C9); // Soft baby green
    final babyYellow = const Color(0xFFFFF9C4); // Soft baby yellow

    return MaterialApp(
      title: 'Bubble Laundry',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        primaryColor: babyPink,
        scaffoldBackgroundColor: babyYellow.withOpacity(0.1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: babyPink,
          primary: babyPink,
          secondary: babyBlue,
          tertiary: babyPurple,
          surface: Colors.white,
          background: babyYellow.withOpacity(0.05),
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: babyPink,
          foregroundColor: Colors.black87,
          elevation: 2,
          shadowColor: babyPinkDark.withOpacity(0.3),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: babyPink,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: babyPink,
            foregroundColor: Colors.black87,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: babyYellow.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: babyPink.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: babyPink.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: babyPink, width: 2),
          ),
          labelStyle: TextStyle(color: babyPinkDark),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const HomeScreen(),
        '/create-order': (_) => const CreateOrderScreen(),
        '/orders': (_) => const OrdersScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/admin': (_) => const AdminScreen(),
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
