import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'DistributorStatusScreen.dart';
import '../../models/expense_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'distributor_expense_provider.dart';
import '../../utilities/date_formatter.dart';

class DistributorExpensesScreen extends StatefulWidget {
  const DistributorExpensesScreen({super.key});

  @override
  State<DistributorExpensesScreen> createState() =>
      _DistributorExpensesScreenState();
}

class _DistributorExpensesScreenState extends State<DistributorExpensesScreen> {
  DateTime selectedDate = DateTime.now();

  // Status filter: null means "All"
  String? _selectedStatusFilter;

  // Status options matching the workflow table
  final List<Map<String, String>> _statusOptions = [
    {'label': 'All', 'value': ''},
    {'label': 'Collected', 'value': 'collected'},
    {'label': 'SO (Submitted to AM)', 'value': 'so'},
    {'label': 'AM (Received from SO)', 'value': 'am'},
    {'label': 'Submitted', 'value': 'submitted'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DistributorExpenseProvider>(context, listen: false).init();
    });
  }

  String get formattedMonth {
    return DateFormat('MMMM yyyy').format(selectedDate);
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

  List<Expense> _filterExpenses(List<Expense> expenses) {
    if (_selectedStatusFilter == null || _selectedStatusFilter!.isEmpty) {
      return expenses;
    }
    return expenses.where((e) {
      final status = e.trackingStatus.toLowerCase().trim();
      if (_selectedStatusFilter == 'am') {
        return status == 'am' || status == 'asm' || status == 'received';
      }
      return status == _selectedStatusFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DistributorExpenseProvider>();
    final userRole = provider.userRole.toLowerCase();
    final filteredExpenses = _filterExpenses(provider.expenses);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // light grey background
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
            onPressed: () => provider.fetchExpenses(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month picker
          GestureDetector(
            onTap: _pickMonth,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.text.withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedMonth,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // ── Status Filter Row ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white.withValues(alpha: 0.6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusOptions.map((opt) {
                  final isSelected =
                      (_selectedStatusFilter ?? '') == opt['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        opt['label']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      checkmarkColor: Colors.white,
                      side: BorderSide(color: AppColors.primary),
                      onSelected: (_) {
                        setState(() {
                          _selectedStatusFilter = opt['value'];
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          if (provider.isLoading && provider.expenses.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (filteredExpenses.isEmpty)
            const Expanded(child: Center(child: Text("No expenses found")))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredExpenses.length,
                itemBuilder: (context, index) {
                  final expense = filteredExpenses[index];
                  return _buildExpenseCard(expense, provider);
                },
              ),
            ),
        ],
      ),
      floatingActionButton:
          (userRole.contains("so") || userRole.contains("sale"))
          ? FloatingActionButton(
              onPressed: () => _openAddExpensePopup(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: AppColors.white),
            )
          : null,
    );
  }

  Widget _buildExpenseCard(
    Expense expense,
    DistributorExpenseProvider provider,
  ) {
    return Card(
      color: Colors.white, // white card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
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
                    const Text(
                      "Employee",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense.employeeName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                    const Text(
                      "Expense Date",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(DateFormatter.formatDateTime(expense.expenseDate)),
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
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(expense.trackingStatus)
                        .withValues(alpha: 0.15),
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
                // Action buttons + Track Status
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DistributorStatusScreen(
                              expense: expense,
                              userRole: provider.userRole,
                            ),
                          ),
                        ).then((_) => provider.fetchExpenses());
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
    switch (status.toLowerCase().trim()) {
      case 'submitted':
        return Colors.green; // ← green for "Submitted"
      case 'received':
        return Colors.green;
      case 'pending':
      case 'so':
      case 'collected':
        return Colors.orange;
      case 'am':
      case 'asm':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  void _showFullScreenImage(File imageFile) {
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
              child: Image.file(
                imageFile,
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
            return Consumer<DistributorExpenseProvider>(
              builder: (context, provider, child) {
                return Dialog(
                  insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration:  BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Add Expense",
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: dateController,
                                      readOnly: true,
                                      decoration: const InputDecoration(
                                        labelText: "Date",
                                        suffixIcon: Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                        ),
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                      ),
                                      onTap: () async {
                                        DateTime? picked =
                                            await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime(2020),
                                              lastDate: DateTime(2100),
                                            );
                                        if (picked != null) {
                                          setPopupState(() {
                                            dateController.text =
                                                DateFormat(
                                                  'yyyy-MM-dd',
                                                ).format(picked);
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: expenseTypeController,
                                      decoration: const InputDecoration(
                                        labelText: "Type",
                                        hintText: "Fuel, Food...",
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: amountController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: "Amount (₹)",
                                        hintText: "0.00",
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: paymentModeController,
                                      decoration: const InputDecoration(
                                        labelText: "Payment",
                                        hintText: "Cash, UPI...",
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: descriptionController,
                                decoration: const InputDecoration(
                                  labelText: "Description",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Expense Bill",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () async {
                                  // If image already selected, show full screen on tap
                                  if (selectedImage != null) {
                                    _showFullScreenImage(selectedImage!);
                                    return;
                                  }
                                  final picker = ImagePicker();
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (ctx) => SafeArea(
                                      child: Wrap(
                                        children: [
                                          ListTile(
                                            leading: const Icon(
                                              Icons.photo_library,
                                            ),
                                            title: const Text('Gallery'),
                                            onTap: () async {
                                              Navigator.pop(ctx);
                                              final pickedFile =
                                                  await picker.pickImage(
                                                    source:
                                                        ImageSource.gallery,
                                                  );
                                              if (pickedFile != null) {
                                                setPopupState(() {
                                                  selectedImage = File(
                                                    pickedFile.path,
                                                  );
                                                });
                                              }
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.camera_alt,
                                            ),
                                            title: const Text('Camera'),
                                            onTap: () async {
                                              Navigator.pop(ctx);
                                              final pickedFile =
                                                  await picker.pickImage(
                                                    source: ImageSource.camera,
                                                  );
                                              if (pickedFile != null) {
                                                setPopupState(() {
                                                  selectedImage = File(
                                                    pickedFile.path,
                                                  );
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.5),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  // Show full image height when selected
                                  child: selectedImage == null
                                      ? Container(
                                          height: 80,
                                          alignment: Alignment.center,
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo,
                                                color: Colors.grey,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                "Upload bill",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.file(
                                                selectedImage!,
                                                fit: BoxFit.contain,
                                                width: double.infinity,
                                              ),
                                            ),
                                            // Change button
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () async {
                                                  final picker = ImagePicker();
                                                  showModalBottomSheet(
                                                    context: context,
                                                    builder: (ctx) => SafeArea(
                                                      child: Wrap(
                                                        children: [
                                                          ListTile(
                                                            leading: const Icon(
                                                              Icons.photo_library,
                                                            ),
                                                            title: const Text(
                                                              'Gallery',
                                                            ),
                                                            onTap: () async {
                                                              Navigator.pop(
                                                                ctx,
                                                              );
                                                              final p =
                                                                  await picker.pickImage(
                                                                    source:
                                                                        ImageSource.gallery,
                                                                  );
                                                              if (p != null) {
                                                                setPopupState(
                                                                  () =>
                                                                      selectedImage =
                                                                          File(
                                                                            p.path,
                                                                          ),
                                                                );
                                                              }
                                                            },
                                                          ),
                                                          ListTile(
                                                            leading: const Icon(
                                                              Icons.camera_alt,
                                                            ),
                                                            title: const Text(
                                                              'Camera',
                                                            ),
                                                            onTap: () async {
                                                              Navigator.pop(
                                                                ctx,
                                                              );
                                                              final p =
                                                                  await picker.pickImage(
                                                                    source:
                                                                        ImageSource.camera,
                                                                  );
                                                              if (p != null) {
                                                                setPopupState(
                                                                  () =>
                                                                      selectedImage =
                                                                          File(
                                                                            p.path,
                                                                          ),
                                                                );
                                                              }
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 3,
                                                      ),
                                                  child: const Text(
                                                    "Change",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: provider.isLoading
                                      ? null
                                      : () async {
                                          if (amountController.text.isEmpty ||
                                              expenseTypeController
                                                  .text.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Please enter amount and expense type",
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          final response = await provider
                                              .addExpense(
                                                distributorId: "1",
                                                expenseDate:
                                                    dateController.text,
                                                expenseAmount:
                                                    amountController.text,
                                                description:
                                                    descriptionController.text,
                                                expenseType:
                                                    expenseTypeController.text,
                                                paymentMode:
                                                    paymentModeController.text,
                                                expenseBill: selectedImage,
                                              );

                                          debugPrint(
                                            "ℹ️ INFO: Add Expense Response: $response",
                                          );

                                          if (response != null &&
                                              response['status'] == true) {
                                            Navigator.pop(context);
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  response?['message'] ??
                                                      "Failed to add expense",
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green, // green submit button
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: provider.isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          "SUBMIT",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
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
      },
    );
  }
}
