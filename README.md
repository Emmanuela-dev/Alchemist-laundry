# Bubble Laundry - Flutter App

A comprehensive laundry service management app built with Flutter, featuring customer ordering, admin management, and M-Pesa payment integration.

## Features

### Customer Features
- **Phone Authentication**: Login/signup with phone number and OTP verification
- **Service Selection**: Choose from Wash & Fold, Dry Clean, and Ironing services
- **Cart Functionality**: Add multiple items to cart with quantity controls
- **Order Scheduling**: Set pickup and delivery dates
- **Location Services**: Pin pickup/delivery locations
- **M-Pesa Payments**: Secure STK Push payment integration
- **Order Tracking**: Real-time order status updates
- **Push Notifications**: Order status notifications

### Admin Features
- **Dashboard**: Overview of orders, revenue, and tasks
- **Order Management**: Update order statuses and manage logistics
- **Service Management**: Add/edit/delete laundry services
- **Payment Monitoring**: Track payment statuses
- **Driver Management**: Route optimization and navigation

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (3.9.2+)
- Firebase project
- M-Pesa Daraja API credentials
- Android Studio / VS Code

### 2. Firebase Setup

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Enable Authentication with Phone provider
4. Enable Firestore Database
5. Add your app (Android/iOS/Web)

#### Configure Firebase Options
Update `lib/firebase_options.dart` with your Firebase config:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'your-web-api-key',
  appId: 'your-web-app-id',
  messagingSenderId: 'your-messaging-sender-id',
  projectId: 'your-project-id',
  authDomain: 'your-project-id.firebaseapp.com',
  storageBucket: 'your-project-id.appspot.com',
  measurementId: 'your-measurement-id',
);
```

### 3. M-Pesa Daraja API Setup

#### Get M-Pesa Credentials
1. Visit [Safaricom Developer Portal](https://developer.safaricom.co.ke/)
2. Create an account and app
3. Get your Consumer Key and Consumer Secret
4. Get your Business Short Code and Pass Key

#### Configure M-Pesa Credentials
Update `lib/services/mpesa_config.dart`:

```dart
class MpesaConfig {
  // Replace with your actual credentials
  static const String consumerKey = 'your_actual_consumer_key';
  static const String consumerSecret = 'your_actual_consumer_secret';
  static const String businessShortCode = 'your_short_code'; // e.g., '174379'
  static const String passKey = 'your_actual_pass_key'; // From Daraja portal

  // For production, change to 'production'
  static const String environment = 'sandbox';

  // Your callback URL (must be HTTPS for production)
  static const String callbackUrl = 'https://your-domain.com/mpesa/callback';
}
```

#### Environment Setup
- **Sandbox**: Use for testing with test credentials
- **Production**: Use live credentials and HTTPS callback URL

### 4. Firestore Security Rules

The app includes comprehensive security rules in `firestore.rules`:

### 6. Testing M-Pesa Integration

#### Sandbox Testing
1. Use sandbox credentials
2. Test phone numbers: `254708374149`, `254728031465`
3. Test amounts: Keep under KES 100 for testing

#### Production Testing
1. Use production credentials
2. Test with small amounts first
3. Ensure callback URL is accessible

## Architecture

### Services Layer
- **FirebaseService**: Firebase Auth and Firestore operations
- **MpesaService**: M-Pesa Daraja API integration
- **PaymentService**: Payment processing and monitoring
- **LocalRepo**: Local storage for offline functionality

### Models
- **UserProfile**: User information and roles
- **Service**: Laundry service definitions
- **Order**: Customer orders with items and status
- **Payment**: M-Pesa payment tracking
- **OrderItem**: Individual order line items

### Screens
- **Login/Signup**: Phone authentication
- **Home**: Service selection and cart
- **CreateOrder**: Order review and payment
- **Orders**: Order history and tracking
- **Admin**: Administrative functions

## API Endpoints

### M-Pesa Integration
- **OAuth**: `GET /oauth/v1/generate`
- **STK Push**: `POST /mpesa/stkpush/v1/processrequest`
- **Query Status**: `POST /mpesa/stkpushquery/v1/query`

### Callback Handling
Set up a webhook endpoint to receive M-Pesa callbacks:

```javascript
// Example callback handler
app.post('/mpesa/callback', (req, res) => {
  const callbackData = req.body;
  // Process callback using PaymentService.processMpesaCallback()
});
```

## Troubleshooting

### Common Issues

#### M-Pesa Configuration
- Ensure all credentials are correct
- Check environment (sandbox vs production)
- Verify callback URL is accessible

#### Firebase Issues
- Check Firebase configuration
- Ensure security rules are deployed
- Verify authentication providers are enabled

#### Payment Failures
- Check M-Pesa account balance
- Verify phone number format
- Check STK Push timeout settings

### Logs and Debugging
- Enable verbose logging in development
- Check Firebase console for errors
- Monitor M-Pesa callback logs

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Contact the development team
- Check the documentation

---

**Note**: This app is designed for the Kenyan market with M-Pesa integration. For other markets, payment providers would need to be adapted accordingly.
