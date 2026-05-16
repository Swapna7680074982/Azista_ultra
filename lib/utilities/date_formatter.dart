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

  static String formatTimeOnly(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == 'N/A') {
      return '--:--';
    }

    try {
      DateTime? dateTime = DateTime.tryParse(dateString.trim());
      if (dateTime == null) {
        try {
          dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateString.trim());
        } catch (e) {
          return dateString;
        }
      }
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  static String formatDateOnly(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == 'N/A') {
      return 'N/A';
    }

    try {
      DateTime? dateTime = DateTime.tryParse(dateString.trim());
      if (dateTime == null) {
        try {
          dateTime = DateFormat("yyyy-MM-dd").parse(dateString.trim());
        } catch (e) {
          return dateString;
        }
      }
      return DateFormat('d MMM yyyy').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }
}
