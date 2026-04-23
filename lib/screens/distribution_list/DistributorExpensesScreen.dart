import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'DistributorStatusScreen.dart';
class DistributorExpensesScreen extends StatefulWidget {
  const DistributorExpensesScreen({super.key});

  @override
  State<DistributorExpensesScreen> createState() =>
      _DistributorExpensesScreenState();
}

class _DistributorExpensesScreenState
    extends State<DistributorExpensesScreen> {

  DateTime selectedDate = DateTime.now();
  String get formattedMonth {
    return "${_monthName(selectedDate.month)} ${selectedDate.year}";
  }

  String _monthName(int month) {
    const months = [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ];
    return months[month - 1];
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
                   Icon(Icons.calendar_today, size: 18,color: AppColors.primary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text("Created On",
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    const Text("Apr 22, 2026 02:35 pm"),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Payment Type",
                                style: TextStyle(color: Colors.grey)),
                            SizedBox(height: 4),
                            Text("Card"),
                          ],
                        ),
                        Text(
                          "₹18.00",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const Text("Comments",
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    const Text("hi"),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DistributorStatusScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Track Status",
                          style: TextStyle(
                            color: Colors.red,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          _openAddExpensePopup(context);
        },
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
  void _openAddExpensePopup(BuildContext context) {
    final TextEditingController paymentTypeController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController commentController = TextEditingController();

    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                            "Collect from Distributor",
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
                    _styledField("Payment Type", paymentTypeController),
                    _styledField("Amount", amountController,
                        keyboardType: TextInputType.number),
                    _styledField("Comment", commentController, maxLines: 2),

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
                              "Upload Payment Photo",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            InkWell(
                              onTap: () async {
                                final picker = ImagePicker();

                                showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                  ),
                                  builder: (context) {
                                    return SafeArea(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: const Icon(
                                                Icons.camera_alt_outlined),
                                            title: const Text("Camera"),
                                            onTap: () async {
                                              Navigator.pop(context);
                                              final pickedFile =
                                              await picker.pickImage(
                                                source: ImageSource.camera,
                                              );
                                              if (pickedFile != null) {
                                                setState(() {
                                                  selectedImage =
                                                      File(pickedFile.path);
                                                });
                                              }
                                            },
                                          ),
                                          ListTile(
                                            leading:
                                            const Icon(Icons.photo_outlined),
                                            title: const Text("Gallery"),
                                            onTap: () async {
                                              Navigator.pop(context);
                                              final pickedFile =
                                              await picker.pickImage(
                                                source: ImageSource.gallery,
                                              );
                                              if (pickedFile != null) {
                                                setState(() {
                                                  selectedImage =
                                                      File(pickedFile.path);
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha:0.1),
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
                          onPressed: () {
                            Navigator.pop(context);
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