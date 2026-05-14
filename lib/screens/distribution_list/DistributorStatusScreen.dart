import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/expense_model.dart';
import '../../services/api_services.dart';

class DistributorStatusScreen extends StatefulWidget {
  final Expense expense;
  final String userRole;
  const DistributorStatusScreen({
    super.key,
    required this.expense,
    required this.userRole,
  });

  @override
  State<DistributorStatusScreen> createState() => _DistributorStatusScreenState();
}

class _DistributorStatusScreenState extends State<DistributorStatusScreen> {
  bool isLoading = false;
  late String currentStatus;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.expense.trackingStatus;
  }

  bool isStepCompleted(int step) {
    String status = currentStatus.toLowerCase();
    if (step == 0) return true; // Collected is always true if it exists
    if (step == 1) return status == 'submitted' || status == 'received' || status == 'submitted to admin';
    if (step == 2) return status == 'received' || status == 'submitted to admin';
    if (step == 3) return status == 'submitted to admin';
    return false;
  }

  Future<void> _updateStatus(String action) async {
    setState(() => isLoading = true);
    Map<String, dynamic>? response;

    if (action == 'submit_to_am') {
      response = await ApiServices.submitToAm(widget.expense.expenseId);
    } else if (action == 'receive_from_so') {
      response = await ApiServices.receiveFromSo(widget.expense.expenseId);
    } else if (action == 'submit_to_admin') {
      response = await ApiServices.submitToAdmin(widget.expense.expenseId);
    }

    if (response != null && response['status'] == true) {
      setState(() {
        if (action == 'submit_to_am') currentStatus = 'Submitted';
        if (action == 'receive_from_so') currentStatus = 'Received';
        if (action == 'submit_to_admin') currentStatus = 'Submitted to Admin';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? "Updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response?['message'] ?? "Update failed")),
      );
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Distribution Expenses status",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Created On", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(widget.expense.createdOn,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text("Expense Type", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(widget.expense.expenseType,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text("Amount", style: TextStyle(color: Colors.grey, fontSize: 12)),
                             SizedBox(height: 4),
                            Text("₹${widget.expense.expenseAmount}",
                                style:  TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
                            const SizedBox(height: 10),
                            Text("Description", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(widget.expense.description),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: widget.expense.expenseBill.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.expense.expenseBill,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image_not_supported, color: Colors.grey),
                                ),
                              )
                            : const Icon(Icons.image, color: Colors.grey),
                      )
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          _timelineIcon(isStepCompleted(0)),
                          _dottedLine(),
                          _timelineIcon(isStepCompleted(1)),
                          _dottedLine(),
                          _timelineIcon(isStepCompleted(2)),
                          _dottedLine(),
                          _timelineIcon(isStepCompleted(3)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _statusCard(
                              index: 0,
                              title: "Collected from Distributor",
                              date: widget.expense.createdOn,
                            ),
                            _statusCard(
                              index: 1,
                              title: "Submitted to ASM",
                              date: isStepCompleted(1) ? "Completed" : "Pending",
                              showButton: widget.userRole == "SO" && currentStatus.toLowerCase() == 'pending',
                              onButtonPressed: () => _updateStatus('submit_to_am'),
                            ),
                            _statusCard(
                              index: 2,
                              title: "Received from SO to ASM",
                              date: isStepCompleted(2) ? "Completed" : "Pending",
                              showButton: widget.userRole == "AM" && currentStatus.toLowerCase() == 'submitted',
                              onButtonPressed: () => _updateStatus('receive_from_so'),
                            ),
                            _statusCard(
                              index: 3,
                              title: "Submitted to Admin",
                              date: isStepCompleted(3) ? "Completed" : "Pending",
                              showButton: widget.userRole == "AM" && currentStatus.toLowerCase() == 'received',
                              onButtonPressed: () => _updateStatus('submit_to_admin'),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _timelineIcon(bool isCompleted) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Icon(
        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isCompleted ? AppColors.primary : Colors.grey,
        size: 24,
      ),
    );
  }

  Widget _dottedLine() {
    return Container(
      width: 2,
      height: 40,
      color: Colors.grey.shade300,
    );
  }

  Widget _statusCard({
    required int index,
    required String title,
    required String date,
    bool showButton = false,
    VoidCallback? onButtonPressed,
  }) {
    bool isCompleted = isStepCompleted(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (showButton)
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Update",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}