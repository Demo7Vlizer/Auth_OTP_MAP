import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TwilioService {
  static TwilioService? _instance;
  TwilioFlutter? _twilioFlutter;
  bool _isInitialized = false;

  TwilioService._();

  static TwilioService get instance {
    _instance ??= TwilioService._();
    return _instance!;
  }

  TwilioFlutter get twilioFlutter {
    if (!_isInitialized) {
      _init();
    }
    return _twilioFlutter!;
  }

  void _init() {
    if (_isInitialized) return;

    final accountSid = dotenv.env['TWILIO_ACCOUNT_SID'];
    final authToken = dotenv.env['TWILIO_AUTH_TOKEN'];
    final twilioNumber = dotenv.env['TWILIO_PHONE_NUMBER'];

    if (accountSid == null || authToken == null || twilioNumber == null) {
      throw Exception('Missing Twilio credentials in .env file');
    }

    _twilioFlutter = TwilioFlutter(
      accountSid: accountSid,
      authToken: authToken,
      twilioNumber: twilioNumber,
    );
    
    _isInitialized = true;
  }

  Future<void> sendSMS(String toNumber, String message) async {
    try {
      String formattedNumber = toNumber.startsWith('+') ? toNumber : '+$toNumber';
      await twilioFlutter.sendSMS(
        toNumber: formattedNumber,
        messageBody: message,
      );
    } catch (e) {
      print('SMS sending error: $e');
      throw Exception('Failed to send SMS: $e');
    }
  }
}
