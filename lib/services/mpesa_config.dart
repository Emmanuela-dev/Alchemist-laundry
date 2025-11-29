class MpesaConfig {
  // Replace these with your actual Daraja API credentials
  static const String consumerKey = 'cEPGXPd63YKv70uyrnpQSbcANNkI0mxu8xHae2KaTKp4D88B';
  static const String consumerSecret = 'qL3GJ9iVV9EngrD9KZ7S4kWQ59IEfFXHzbtY30APUMjh1H8bhNsd6AH1Ee4jNRT8';

  // Environment - use 'sandbox' for testing, 'production' for live
  static const String environment = 'production'; // Changed to production for real phone numbers

  // Base URLs
  static const String _sandboxBaseUrl = 'https://sandbox.safaricom.co.ke';
  static const String _productionBaseUrl = 'https://api.safaricom.co.ke';

  static String get baseUrl => environment == 'production' ? _productionBaseUrl : _sandboxBaseUrl;

  // Endpoints
  static const String oauthEndpoint = '/oauth/v1/generate';
  static const String stkPushEndpoint = '/mpesa/stkpush/v1/processrequest';
  static const String stkQueryEndpoint = '/mpesa/stkpushquery/v1/query';

  // Your business details - UPDATE THESE VALUES
  static const String businessShortCode = '174379'; // Sandbox test short code
  static const String passKey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919'; // Sandbox test passkey
  static const String callbackUrl = ' https://unarraigned-nonuniquely-alannah.ngrok-free.dev '; // Replace with your ngrok URL

  // Party B (usually same as short code for PayBill)
  static String get partyB => businessShortCode;

  // Account Reference (can be order ID or customer reference)
  static String generateAccountReference(String orderId) => 'BL-$orderId'; // BL for Bubble Laundry

  // Transaction Description
  static const String transactionDesc = 'Alchemist Laundry Service Payment';

  // Timeout and other settings
  static const int stkPushTimeout = 30; // seconds
  static const int queryInterval = 5; // seconds between status checks
  static const int maxQueryAttempts = 12; // maximum status check attempts

  // Validation
  static bool get isConfigured =>
       consumerKey.isNotEmpty && consumerKey != 'cEPGXPd63YKv70uyrnpQSbcANNkI0mxu8xHae2KaTKp4D88B' &&
       consumerSecret.isNotEmpty && consumerSecret != 'qL3GJ9iVV9EngrD9KZ7S4kWQ59IEfFXHzbtY30APUMjh1H8bhNsd6AH1Ee4jNRT8' &&
       businessShortCode.isNotEmpty && businessShortCode != 'YOUR_BUSINESS_SHORT_CODE' &&
       passKey.isNotEmpty && passKey != 'YOUR_PASS_KEY' &&
       callbackUrl.isNotEmpty && callbackUrl != 'https://your-ngrok-url.ngrok.io/mpesa/callback';

  static String? validateConfig() {
    if (!isConfigured) {
      return 'M-Pesa configuration incomplete. Please update your production credentials in mpesa_config.dart';
    }
    return null;
  }
}