import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == 'N/A') {
      return 'N/A';
    }

    try {
      String cleanedDate = dateString.trim();
      DateTime? dateTime = DateTime.tryParse(cleanedDate);
      
      if (dateTime == null) {
        try {
          dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(cleanedDate);
        } catch (e) {
          return dateString;
        }
      }
      
      return DateFormat('d MMM yyyy h:mm a').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }
}
