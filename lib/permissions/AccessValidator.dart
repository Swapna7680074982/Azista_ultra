import 'package:flutter/material.dart';

class AccessValidator {
  static bool validate({
    required BuildContext context,
    required bool isOnline,
    required bool hasDistributor,
    required bool isLeave,
  }) {
    if (!hasDistributor) {
      _show(context, "Please select a distributor to continue.");
      return false;
    }

    if (!isOnline && !isLeave) {
      _show(context, "Please turn on attendance to access this feature.");
      return false;
    }

    if (isOnline && isLeave) {
      _show(context, "Leave management is unavailable while attendance is active.");
      return false;
    }

    return true;
  }

  static bool validateTab({
    required BuildContext context,
    required bool isOnline,
    required bool hasDistributor,
    required int index,
  }) {
    if (!hasDistributor) {
      _show(context, "Please select a distributor to continue.");
      return false;
    }

    if (!isOnline && index != 0) {
      _show(context, "Please turn on attendance to access other sections.");
      return false;
    }

    return true;
  }

  static void _show(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}