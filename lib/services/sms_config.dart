class SmsConfig {
  // Add your SMS provider credentials here (Twilio example). Keep secrets out
  // of source control in production. For development you can set these to null
  // and just use logs.
  static const enabled = false;
  static const accountSid = '';
  static const authToken = '';
  static const fromNumber = ''; // Twilio number

  // Admin numbers to notify (list of E.164 strings)
  static const adminNumbers = <String>[
    '+254700000000',
  ];
}
