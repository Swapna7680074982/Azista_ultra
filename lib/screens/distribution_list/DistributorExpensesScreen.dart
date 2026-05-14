import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api_services.dart';
import 'DistributorStatusScreen.dart';
import '../../models/expense_model.dart';
import '../../permissions/SessionManager.dart';
import '../../utilities/mylogger.dart';
import 'package:intl/intl.dart';

class DistributorExpensesScreen extends StatefulWidget {
  const DistributorExpensesScreen({super.key});

  @override
  State<DistributorExpensesScreen> createState() =>
      _DistributorExpensesScreenState();
}

class _DistributorExpensesScreenState
    extends State<DistributorExpensesScreen> {
  DateTime selectedDate = DateTime.now();
  List<Expense> expenses = [];
  bool isLoading = true;
  String userRole = "";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    userRole = await SessionManager.getUserRole();
    await _fetchExpenses();
  }

  String get formattedMonth {
    return DateFormat('MMMM yyyy').format(selectedDate);
  }

  Future<void> _fetchExpenses() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiServices.getExpenses();
      if (response != null && response['status'] == true) {
        final List data = response['data'] ?? [];
        setState(() {
          expenses = data.map((e) => Expense.fromJson(e)).toList();
        });
      } else {
        AppLogger.warning("Failed to fetch expenses: ${response?['message']}");
      }
    } catch (e) {
      AppLogger.error("Error fetching expenses", e);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickMonth() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          "Distribution Expenses",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchExpenses,
          ),
        ],
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: _pickMonth,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedMonth,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Icon(Icons.calendar_today,
                      size: 18, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : expenses.isEmpty
                    ? const Center(child: Text("No expenses found"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          return _buildExpenseCard(expenses[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: userRole == "SO"
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () {
                _openAddExpensePopup(context);
              },
              child: const Icon(Icons.add, color: AppColors.white),
            )
          : null,
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Employee", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(expense.employeeName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(
                  "₹${expense.expenseAmount}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Expense Date",
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(expense.expenseDate),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Type", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(expense.expenseType),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text("Description", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(expense.description),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(expense.trackingStatus)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    expense.trackingStatus,
                    style: TextStyle(
                      color: _getStatusColor(expense.trackingStatus),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    _buildActionButtons(expense),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DistributorStatusScreen(
                              expense: expense,
                              userRole: userRole,
                            ),
                          ),
                        ).then((_) => _fetchExpenses());
                      },
                      child: Text(
                        "Track Status",
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.blue;
      case 'received':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionButtons(Expense expense) {
    if (userRole == "SO" && expense.trackingStatus.toLowerCase() == "pending") {
      return TextButton(
        onPressed: () => _handleAction('submit_to_am', expense.expenseId),
        child: const Text("Submit to AM"),
      );
    } else if (userRole == "AM") {
      if (expense.trackingStatus.toLowerCase() == "submitted") {
        return TextButton(
          onPressed: () => _handleAction('receive_from_so', expense.expenseId),
          child: const Text("Receive"),
        );
      } else if (expense.trackingStatus.toLowerCase() == "received") {
        return TextButton(
          onPressed: () => _handleAction('submit_to_admin', expense.expenseId),
          child: const Text("Submit to Admin"),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Future<void> _handleAction(String action, String expenseId) async {
    setState(() => isLoading = true);
    Map<String, dynamic>? response;
    if (action == 'submit_to_am') {
      response = await ApiServices.submitToAm(expenseId);
    } else if (action == 'receive_from_so') {
      response = await ApiServices.receiveFromSo(expenseId);
    } else if (action == 'submit_to_admin') {
      response = await ApiServices.submitToAdmin(expenseId);
    }

    if (response != null && response['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? "Action successful")),
      );
      _fetchExpenses();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response?['message'] ?? "Action failed")),
      );
      setState(() => isLoading = false);
    }
  }

  void _openAddExpensePopup(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController expenseTypeController = TextEditingController();
    final TextEditingController paymentModeController = TextEditingController();
    final TextEditingController dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Add Expense",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.close, color: Colors.white),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _styledField("Expense Date (YYYY-MM-DD)", dateController),
                    _styledField("Expense Type (e.g. Fuel)", expenseTypeController),
                    _styledField("Amount", amountController,
                        keyboardType: TextInputType.number),
                    _styledField("Payment Mode (e.g. UPI)", paymentModeController),
                    _styledField("Description", descriptionController, maxLines: 2),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Upload Expense Bill",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            InkWell(
                              onTap: () async {
                                final picker = ImagePicker();
                                final pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (pickedFile != null) {
                                  setPopupState(() {
                                    selectedImage = File(pickedFile.path);
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.image,
                                    color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(selectedImage!, height: 100),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            if (amountController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter amount")),
                              );
                              return;
                            }
                            
                            final distributors = await SessionManager.getDistributors();
                            String distId = "1";
                            if (distributors.isNotEmpty) {
                              distId = distributors[0]['distributor_id']?.toString() ?? "1";
                            }

                            final response = await ApiServices.addExpense(
                              distributorId: distId,
                              expenseDate: dateController.text,
                              expenseAmount: amountController.text,
                              description: descriptionController.text,
                              expenseType: expenseTypeController.text,
                              paymentMode: paymentModeController.text,
                              expenseBill: selectedImage,
                            );

                            if (response != null && response['status'] == true) {
                              Navigator.pop(context);
                              _fetchExpenses();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Expense added successfully")),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(response?['message'] ?? "Failed to add expense")),
                              );
                            }
                          },
                          child: const Text(
                            "SUBMIT",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _styledField(
      String hint,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}