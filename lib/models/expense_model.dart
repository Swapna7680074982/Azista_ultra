class Expense {
  final String expenseId;
  final String employeeName;
  final String employeeId;
  final String role;
  final String reportingManager;
  final String expenseDate;
  final String expenseType;
  final String expenseAmount;
  final String description;
  final String paymentMode;
  final String expenseBill;
  final String trackingStatus;
  final String createdOn;

  Expense({
    required this.expenseId,
    required this.employeeName,
    required this.employeeId,
    required this.role,
    required this.reportingManager,
    required this.expenseDate,
    required this.expenseType,
    required this.expenseAmount,
    required this.description,
    required this.paymentMode,
    required this.expenseBill,
    required this.trackingStatus,
    required this.createdOn,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      expenseId: json['expense_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      reportingManager: json['reporting_manager']?.toString() ?? '',
      expenseDate: json['expense_date']?.toString() ?? '',
      expenseType: json['expense_type']?.toString() ?? '',
      expenseAmount: json['expense_amount']?.toString() ?? '0.00',
      description: json['description']?.toString() ?? '',
      paymentMode: json['payment_mode']?.toString() ?? '',
      expenseBill: json['expense_bill']?.toString() ?? '',
      trackingStatus: json['tracking_status']?.toString() ?? '',
      createdOn: json['created_on']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expense_id': expenseId,
      'employee_name': employeeName,
      'employee_id': employeeId,
      'role': role,
      'reporting_manager': reportingManager,
      'expense_date': expenseDate,
      'expense_type': expenseType,
      'expense_amount': expenseAmount,
      'description': description,
      'payment_mode': paymentMode,
      'expense_bill': expenseBill,
      'tracking_status': trackingStatus,
      'created_on': createdOn,
    };
  }
}
