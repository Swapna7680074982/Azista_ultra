import 'package:flutter/material.dart';

class LeaveBalance {
  final String type;
  final int allocated;
  int used;
  final int remaining;

  LeaveBalance({
    required this.type,
    required this.allocated,
    required this.used,
    required this.remaining,
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
  List<LeaveBalance> _leaveBalances = [
    LeaveBalance(type: 'CASUAL LEAVE', allocated: 10, used: 0, remaining: 10),
    LeaveBalance(type: 'SICK LEAVE', allocated: 10, used: 2, remaining: 8),
    LeaveBalance(type: 'EARNED LEAVE', allocated: 30, used: 2, remaining: 28),
  ];

  List<LeaveRequest> _leaveHistory = [
    LeaveRequest(fromDate: '03-Aug-2024', toDate: '04-Aug-2024', type: 'CL', status: 'Rejected', reason: 'Personal'),
    LeaveRequest(fromDate: '01-Aug-2024', toDate: '02-Aug-2024', type: 'SL', status: 'Approved', reason: 'Fever'),
    LeaveRequest(fromDate: '13-Sept-2024', toDate: '13-Sept-2024', type: 'CL', status: 'Pending', reason: 'Family event'),
    LeaveRequest(fromDate: '11-Sept-2024', toDate: '12-Sept-2024', type: 'EL', status: 'Pending', reason: 'Vacation'),
    LeaveRequest(fromDate: '09-Sept-2024', toDate: '09-Sept-2024', type: 'CL', status: 'Pending', reason: 'Urgent work'),
  ];

  List<Holiday> _holidays = [
    Holiday(date: '01-Jan-2024', occasion: 'NEW YEAR'),
    Holiday(date: '15-Jan-2024', occasion: 'MAKARA SANKRANTHI'),
    Holiday(date: '26-Jan-2024', occasion: 'REPUBLIC DAY'),
    Holiday(date: '09-Apr-2024', occasion: 'UGADI'),
    Holiday(date: '01-May-2024', occasion: 'MAY DAY'),
    Holiday(date: '15-Aug-2024', occasion: 'INDEPENDENCE DAY'),
    Holiday(date: '19-Aug-2024', occasion: 'RAKSHA BANDHAN'),
    Holiday(date: '07-Sep-2024', occasion: 'GANESH CHATURTHI'),
    Holiday(date: '02-Oct-2024', occasion: 'GANDHI JAYANTI'),
    Holiday(date: '11-Oct-2024', occasion: 'DURGA POOJA'),
    Holiday(date: '12-Oct-2024', occasion: 'DURGA POOJA'),
    Holiday(date: '01-Nov-2024', occasion: 'DIWALI'),
  ];

  List<LeaveBalance> get leaveBalances => _leaveBalances;
  List<LeaveRequest> get leaveHistory => _leaveHistory;
  List<Holiday> get holidays => _holidays;

  void addLeaveRequest(LeaveRequest request) {
    _leaveHistory.insert(0, request);
    notifyListeners();
  }
}
