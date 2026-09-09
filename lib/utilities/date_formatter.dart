import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == 'N/A' || dateString == '-') {
      return dateString ?? 'N/A';
    }

    try {
      String cleanedDate = dateString.trim();
      
      // If the string is just a date like "2026-09-08" without time, format as date only
      final hasTime = cleanedDate.contains(':') || cleanedDate.contains('T');

      DateTime? dateTime = DateTime.tryParse(cleanedDate);
      
      if (dateTime == null) {
        try {
          dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(cleanedDate);
        } catch (e) {
          try {
            dateTime = DateFormat("yyyy-MM-dd").parse(cleanedDate);
          } catch (_) {
            try {
              dateTime = DateFormat("dd-MM-yyyy HH:mm:ss").parse(cleanedDate);
            } catch (_) {
              try {
                dateTime = DateFormat("dd-MM-yyyy").parse(cleanedDate);
              } catch (_) {
                return dateString;
              }
            }
          }
        }
      }
      
      if (hasTime) {
        return DateFormat('d MMM yyyy h:mm a').format(dateTime);
      } else {
        return DateFormat('d MMM yyyy').format(dateTime);
      }
    } catch (e) {
      return dateString;
    }
  }

  static String formatTimeOnly(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == 'N/A' || dateString == '-') {
      return '--:--';
    }

    try {
      String cleaned = dateString.trim();
      if (!cleaned.contains(':') && !cleaned.contains('T')) {
        return '--:--';
      }
      DateTime? dateTime = DateTime.tryParse(cleaned);
      if (dateTime == null) {
        try {
          dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(cleaned);
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
    if (dateString == null || dateString.isEmpty || dateString == 'N/A' || dateString == '-') {
      return 'N/A';
    }

    try {
      String cleaned = dateString.trim();
      DateTime? dateTime = DateTime.tryParse(cleaned);
      if (dateTime == null) {
        try {
          dateTime = DateFormat("yyyy-MM-dd").parse(cleaned);
        } catch (e) {
          try {
            dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(cleaned);
          } catch (_) {
            return dateString;
          }
        }
      }
      return DateFormat('d MMM yyyy').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }
}
