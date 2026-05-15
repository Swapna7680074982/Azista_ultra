import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/expense_model.dart';
import 'distributor_expense_provider.dart';
import '../../utilities/date_formatter.dart';

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
  late String currentStatus;
  Uint8List? imageBytes;
  bool isImageLoading = false;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.expense.trackingStatus;
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() => isImageLoading = true);
    final provider = Provider.of<DistributorExpenseProvider>(
        context, listen: false);
    final bytes = await provider.loadImage(widget.expense.expenseBill);
    if (mounted) {
      setState(() {
        imageBytes = bytes;
        isImageLoading = false;
      });
    }
  }

  Future<void> _handleUpdate(String action) async {
    final provider = Provider.of<DistributorExpenseProvider>(
        context, listen: false);
    final response = await provider.updateStatus(
        action, widget.expense.expenseId);

    if (response != null && response['status'] == true) {
      setState(() {
        if (action == 'submit_to_am') currentStatus = 'SO';
        if (action == 'receive_from_so') currentStatus = 'ASM';
        if (action == 'submit_to_admin') currentStatus = 'Submitted';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? "Updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response?['message'] ?? "Update failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            "Expense Tracking", style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Consumer<DistributorExpenseProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExpenseHeader(),
                const SizedBox(height: 24),
                const Text(
                  "Tracking Timeline",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildTimeline(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpenseHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoColumn("Created On", DateFormatter.formatDateTime(widget.expense.createdOn)),
                const SizedBox(height: 16),
                _infoColumn("Expense Type ${widget.expense.expenseType}",
                    "₹${widget.expense.expenseAmount}"),
                const SizedBox(height: 16),
                _infoColumn("Comments",
                    widget.expense.description.isNotEmpty ? widget.expense
                        .description : "No comments"),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildBillThumbnail(),
        ],
      ),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildBillThumbnail() {
    return GestureDetector(
      onTap: () {
        if (imageBytes != null) {
          _showFullScreenImage(imageBytes!);
        }
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: isImageLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(imageBytes!, fit: BoxFit.cover),
                  )
                : const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
      ),
    );
  }

  void _showFullScreenImage(Uint8List bytes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(DistributorExpenseProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.text.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _statusStep(
            index: 0,
            title: "Collected from Distributor",
            subtitle: _getStepSubtitle(provider, 0, "Collected"),
            isCompleted: provider.isStepCompleted(currentStatus, 0),
            provider: provider,
          ),
          _statusStep(
            index: 1,
            title: "Submitted to ASM",
            subtitle: _getStepSubtitle(provider, 1, "SO"),
            isCompleted: provider.isStepCompleted(currentStatus, 1),
            showButton: (widget.userRole.toLowerCase().contains("so") ||
                    widget.userRole.toLowerCase().contains("sale")) &&
                (currentStatus.toLowerCase().trim() == 'pending' ||
                    currentStatus.toLowerCase().trim() == '0' ||
                    currentStatus.toLowerCase().trim() == 'collected'),
            onAction: () => _handleUpdate('submit_to_am'),
            provider: provider,
          ),
          _statusStep(
            index: 2,
            title: "Received from SO to ASM",
            subtitle: _getStepSubtitle(provider, 2, "ASM"),
            isCompleted: provider.isStepCompleted(currentStatus, 2),
            showButton: (widget.userRole.toLowerCase().contains("am") ||
                    widget.userRole.toLowerCase().contains("asm")) &&
                currentStatus.toLowerCase().trim() == 'so',
            onAction: () => _handleUpdate('receive_from_so'),
            provider: provider,
          ),
          _statusStep(
            index: 3,
            title: "Submitted to Admin",
            subtitle: _getStepSubtitle(provider, 3, "Submitted"),
            isCompleted: provider.isStepCompleted(currentStatus, 3),
            showButton: (widget.userRole.toLowerCase().contains("am") ||
                    widget.userRole.toLowerCase().contains("asm")) &&
                (currentStatus.toLowerCase().trim() == 'received' ||
                    currentStatus.toLowerCase().trim() == 'asm'),
            onAction: () => _handleUpdate('submit_to_admin'),
            provider: provider,
          ),
        ],
      ),
    );
  }

  String _getStepSubtitle(DistributorExpenseProvider provider, int index, String statusKey) {
    bool isCompleted = provider.isStepCompleted(currentStatus, index);
    if (!isCompleted) return "Pending";

    // Find the log entry for this status
    final log = widget.expense.trackingLogs.firstWhere(
      (l) => l.expenseStatus.toLowerCase().trim() == statusKey.toLowerCase().trim(),
      orElse: () => TrackingLog(
        logId: '',
        expenseStatus: '',
        remarks: '',
        actionBy: '',
        actionByName: '',
        actionRole: '',
        createdOn: index == 0 ? widget.expense.createdOn : '',
      ),
    );

    if (log.createdOn.isNotEmpty) {
      return DateFormatter.formatDateTime(log.createdOn);
    }

    return "Completed";
  }

  Widget _statusStep({
    required int index,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required DistributorExpenseProvider provider,
    bool showButton = false,
    VoidCallback? onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey.withValues(alpha:
                    0.3),
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            if (index < 3)
              Container(
                width: 2,
                height: 50,
                color: isCompleted ? Colors.green : Colors.grey.withValues(alpha:
                    0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
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
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (showButton)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 16),
                  child: SizedBox(
                    width: 200,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: provider.isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            "Update status",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
