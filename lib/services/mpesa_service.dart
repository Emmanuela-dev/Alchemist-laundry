import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'mpesa_config.dart';

class MpesaService {
  static final MpesaService _instance = MpesaService._internal();
  factory MpesaService() => _instance;
  MpesaService._internal();

  String? _accessToken;
  DateTime? _tokenExpiry;

  /// Generate OAuth access token
  Future<String?> _getAccessToken() async {
    // Check if we have a valid token
    if (_accessToken != null && _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)))) {
      return _accessToken;
    }

    try {
      final credentials = base64Encode(utf8.encode('${MpesaConfig.consumerKey}:${MpesaConfig.consumerSecret}'));

      final response = await http.get(
        Uri.parse('${MpesaConfig.baseUrl}${MpesaConfig.oauthEndpoint}?grant_type=client_credentials'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        // Token expires in 3599 seconds (1 hour), set expiry with some buffer
        _tokenExpiry = DateTime.now().add(const Duration(seconds: 3500));
        return _accessToken;
      } else {
        print('Failed to get access token: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting access token: $e');
      return null;
    }
  }

  /// Generate password for STK Push
  String _generatePassword(String timestamp) {
    final str = '${MpesaConfig.businessShortCode}${MpesaConfig.passKey}$timestamp';
    return base64Encode(utf8.encode(str));
  }

  /// Generate timestamp
  String _generateTimestamp() {
    return DateTime.now().toUtc().toString().replaceAll(RegExp(r'[-:.\s]'), '').substring(0, 14);
  }

  /// Initiate STK Push
  Future<Map<String, dynamic>?> initiateSTKPush({
    required String phoneNumber,
    required int amount,
    required String accountReference,
    String transactionDesc = MpesaConfig.transactionDesc,
  }) async {
    // Validate configuration
    final configError = MpesaConfig.validateConfig();
    if (configError != null) {
      throw Exception(configError);
    }

    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('Failed to obtain access token');
    }

    // Clean phone number (remove + and ensure it starts with 254)
    String cleanPhone = phoneNumber.replaceAll('+', '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '254${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('254')) {
      cleanPhone = '254$cleanPhone';
    }

    final timestamp = _generateTimestamp();
    final password = _generatePassword(timestamp);

    final payload = {
      'BusinessShortCode': MpesaConfig.businessShortCode,
      'Password': password,
      'Timestamp': timestamp,
      'TransactionType': 'CustomerPayBillOnline',
      'Amount': amount,
      'PartyA': cleanPhone,
      'PartyB': MpesaConfig.partyB,
      'PhoneNumber': cleanPhone,
      'CallBackURL': MpesaConfig.callbackUrl,
      'AccountReference': accountReference,
      'TransactionDesc': transactionDesc,
    };

    try {
      final response = await http.post(
        Uri.parse('${MpesaConfig.baseUrl}${MpesaConfig.stkPushEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['ResponseCode'] == '0') {
          return {
            'success': true,
            'merchantRequestId': responseData['MerchantRequestID'],
            'checkoutRequestId': responseData['CheckoutRequestID'],
            'responseCode': responseData['ResponseCode'],
            'responseDescription': responseData['ResponseDescription'],
            'customerMessage': responseData['CustomerMessage'],
          };
        } else {
          return {
            'success': false,
            'error': responseData['ResponseDescription'] ?? 'STK Push failed',
            'responseCode': responseData['ResponseCode'],
          };
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Query STK Push status
  Future<Map<String, dynamic>?> querySTKPushStatus({
    required String checkoutRequestId,
  }) async {
    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('Failed to obtain access token');
    }

    final timestamp = _generateTimestamp();
    final password = _generatePassword(timestamp);

    final payload = {
      'BusinessShortCode': MpesaConfig.businessShortCode,
      'Password': password,
      'Timestamp': timestamp,
      'CheckoutRequestID': checkoutRequestId,
    };

    try {
      final response = await http.post(
        Uri.parse('${MpesaConfig.baseUrl}${MpesaConfig.stkQueryEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'responseCode': responseData['ResponseCode'],
          'responseDescription': responseData['ResponseDescription'],
          'merchantRequestId': responseData['MerchantRequestID'],
          'checkoutRequestId': responseData['CheckoutRequestID'],
          'resultCode': responseData['ResultCode'],
          'resultDesc': responseData['ResultDesc'],
        };
      } else {
        return {
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'error': 'Network error: $e',
      };
    }
  }

  /// Process callback from M-Pesa (to be called from your backend/webhook)
  static Map<String, dynamic> processCallback(Map<String, dynamic> callbackData) {
    try {
      final body = callbackData['Body']?['stkCallback'];

      if (body == null) {
        return {'error': 'Invalid callback data'};
      }

      final resultCode = body['ResultCode'];
      final resultDesc = body['ResultDesc'];
      final merchantRequestId = body['MerchantRequestID'];
      final checkoutRequestId = body['CheckoutRequestID'];

      if (resultCode == 0) {
        // Success
        final callbackMetadata = body['CallbackMetadata']?['Item'] ?? [];
        String? mpesaReceiptNumber;
        String? transactionDate;
        int? amount;

        for (var item in callbackMetadata) {
          switch (item['Name']) {
            case 'MpesaReceiptNumber':
              mpesaReceiptNumber = item['Value'];
              break;
            case 'TransactionDate':
              transactionDate = item['Value'];
              break;
            case 'Amount':
              amount = item['Value'];
              break;
          }
        }

        return {
          'success': true,
          'resultCode': resultCode,
          'resultDesc': resultDesc,
          'merchantRequestId': merchantRequestId,
          'checkoutRequestId': checkoutRequestId,
          'mpesaReceiptNumber': mpesaReceiptNumber,
          'transactionDate': transactionDate,
          'amount': amount,
        };
      } else {
        // Failed
        return {
          'success': false,
          'resultCode': resultCode,
          'resultDesc': resultDesc,
          'merchantRequestId': merchantRequestId,
          'checkoutRequestId': checkoutRequestId,
        };
      }
    } catch (e) {
      return {'error': 'Callback processing error: $e'};
    }
  }
}