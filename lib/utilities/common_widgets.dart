import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class QtyBox extends StatelessWidget {
  final String? initialValue;
  final Function(String)? onChanged;
  final bool isEditable;
  final String? label;
  final bool isRed;

  const QtyBox({
    super.key,
    this.initialValue,
    this.onChanged,
    this.isEditable = true,
    this.label,
    this.isRed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEditable) {
      return Container(
        width: 60,
        height: 35,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          initialValue?.isEmpty ?? true ? "0" : initialValue!,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      );
    }

    return SizedBox(
      width: 60,
      height: 35,
      child: TextFormField(
        initialValue: initialValue,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: AppColors.white,
          hintText: "0",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: isRed ? AppColors.primary : AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: isRed ? AppColors.primary : AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: isRed ? AppColors.primary : AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ProductCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha:0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.primary,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
