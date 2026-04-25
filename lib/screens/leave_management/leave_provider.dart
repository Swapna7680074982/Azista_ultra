import 'package:flutter/material.dart';

class LeaveBalance {
  final String type;
  final String shortName;
  final int allocated;
  int used;
  int remaining;
  final int? maxLeave;
  final bool allowBackDate;

  LeaveBalance({
    required this.type,
    required this.shortName,
    required this.allocated,
    required this.used,
    required this.remaining,
    this.maxLeave,
    required this.allowBackDate,
  });
}
class LeaveRequest {
  final String fromDate;
  final String toDate;
  final String type;
  final String status;
  final String reason;

  LeaveRequest({
    required this.fromDate,
    required this.toDate,
    required this.type,
    required this.status,
    required this.reason,
  });
}

class Holiday {
  final String date;
  final String occasion;

  Holiday({required this.date, required this.occasion});
}

class LeaveProvider extends ChangeNotifier {
  final List<LeaveBalance> _leaveBalances = [
    LeaveBalance(
      type: 'CASUAL LEAVE',
      shortName: 'CL',
      allocated: 10,
      used: 0,
      remaining: 10,
      maxLeave: 3,
      allowBackDate: false,
    ),
    LeaveBalance(
      type: 'SICK LEAVE',
      shortName: 'SL',
      allocated: 10,
      used: 2,
      remaining: 8,
      maxLeave: 5,
      allowBackDate: true,
    ),
    LeaveBalance(
      type: 'EARNED LEAVE',
      shortName: 'EL',
      allocated: 30,
      used: 2,
      remaining: 28,
      maxLeave: 10,
      allowBackDate: false,
    ),
  ];


  final List<LeaveRequest> _leaveHistory = [
    LeaveRequest(fromDate: '03-Aug-2024', toDate: '04-Aug-2024', type: 'CL', status: 'Rejected', reason: 'Personal'),
    LeaveRequest(fromDate: '01-Aug-2024', toDate: '02-Aug-2024', type: 'SL', status: 'Approved', reason: 'Fever'),
    LeaveRequest(fromDate: '13-Sept-2024', toDate: '13-Sept-2024', type: 'CL', status: 'Pending', reason: 'Family event'),
    LeaveRequest(fromDate: '11-Sept-2024', toDate: '12-Sept-2024', type: 'EL', status: 'Pending', reason: 'Vacation'),
    LeaveRequest(fromDate: '09-Sept-2024', toDate: '09-Sept-2024', type: 'CL', status: 'Pending', reason: 'Urgent work'),
  ];

  final List<Holiday> _holidays = [
    Holiday(date: '01-Jan-2026', occasion: 'NEW YEAR'),
    Holiday(date: '15-Jan-2026', occasion: 'MAKARA SANKRANTHI'),
    Holiday(date: '26-Jan-2026', occasion: 'REPUBLIC DAY'),
    Holiday(date: '09-Apr-2026', occasion: 'UGADI'),
    Holiday(date: '01-May-2026', occasion: 'MAY DAY'),
    Holiday(date: '15-Aug-2026', occasion: 'INDEPENDENCE DAY'),
    Holiday(date: '19-Aug-2026', occasion: 'RAKSHA BANDHAN'),
    Holiday(date: '07-Sep-2026', occasion: 'GANESH CHATURTHI'),
    Holiday(date: '02-Oct-2026', occasion: 'GANDHI JAYANTI'),
    Holiday(date: '11-Oct-2026', occasion: 'DURGA POOJA'),
    Holiday(date: '12-Oct-2026', occasion: 'DURGA POOJA'),
    Holiday(date: '01-Nov-2026', occasion: 'DIWALI'),
  ];

  List<LeaveBalance> get leaveBalances => _leaveBalances;
  List<LeaveRequest> get leaveHistory => _leaveHistory;
  List<Holiday> get holidays => _holidays;

  String? validateLeave({
    required LeaveBalance balance,
    required DateTime fromDate,
    required DateTime toDate,
    required int days,
    required String reason,
  }) {
    if (reason.isEmpty) {
      return "Reason is required";
    }

    if (toDate.isBefore(fromDate)) {
      return "Invalid date range";
    }

    int actualDays = toDate.difference(fromDate).inDays + 1;

    if (days != actualDays) {
      return "Days should be $actualDays";
    }

    if (!balance.allowBackDate && fromDate.isBefore(DateTime.now())) {
      return "Backdate not allowed";
    }

    if (balance.maxLeave != null && days > balance.maxLeave!) {
      return "Max ${balance.maxLeave} days allowed";
    }

    if (days > balance.remaining) {
      return "Insufficient balance";
    }

    return null;
  }

  void applyLeave({
    required LeaveBalance balance,
    required LeaveRequest request,
    required int days,
  }) {
    balance.used += days;
    balance.remaining -= days;

    _leaveHistory.insert(0, request);
    notifyListeners();
  }
}
