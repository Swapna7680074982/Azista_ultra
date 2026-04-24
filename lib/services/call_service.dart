import 'package:url_launcher/url_launcher.dart';

class CallService {
  static Future<void> makeCall(String phone) async {
    final Uri uri = Uri.parse("tel:$phone");

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
}