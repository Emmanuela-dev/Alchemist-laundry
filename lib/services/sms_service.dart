import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sms_config.dart';
import 'admin_numbers.dart';

class SmsService {
  SmsService._();
  static final SmsService instance = SmsService._();

  Future<void> notifyAdmins(String message) async {
    // If SMS is not enabled, simply log (stdout) — in real app use secure storage
    if (!SmsConfig.enabled) {
      // ignore: avoid_print
      print('[SmsService] SMS disabled — would notify admins:');
      // ignore: avoid_print
      print(message);
      return;
    }

    final from = SmsConfig.fromNumber;

    final uriBase = Uri.parse('https://api.twilio.com/2010-04-01/Accounts/${SmsConfig.accountSid}/Messages.json');

  final admins = await AdminNumbers.load();
  final targets = admins.isNotEmpty ? admins : SmsConfig.adminNumbers;
  for (final to in targets) {
      final body = {'From': from, 'To': to, 'Body': message};
      final resp = await http.post(uriBase, headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('${SmsConfig.accountSid}:${SmsConfig.authToken}'))}',
        'Content-Type': 'application/x-www-form-urlencoded'
      }, body: body);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        // ignore: avoid_print
        print('[SmsService] Sent SMS to $to');
      } else {
        // ignore: avoid_print
        print('[SmsService] Failed to send SMS to $to: ${resp.statusCode} ${resp.body}');
      }
    }
  }
}
