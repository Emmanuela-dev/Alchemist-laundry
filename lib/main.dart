import 'package:flutter/material.dart';
import 'services/mock_repo.dart';
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
  // initialize mock data
  await MockRepo.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final babyBlue = const Color(0xFFB3E5FC);
    final babyPink = const Color(0xFFFFB6C1);
    return MaterialApp(
      title: 'Laundry App (MVP)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: babyBlue, primary: babyBlue, secondary: babyPink),
        appBarTheme: AppBarTheme(backgroundColor: babyBlue, foregroundColor: Colors.black),
        floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: babyPink),
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
