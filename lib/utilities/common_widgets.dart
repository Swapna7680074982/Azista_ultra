import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/image_constants.dart';

class QtyBox extends StatelessWidget {
  final String? initialValue;
  final Function(String)? onChanged;
  final bool isEditable;
  final String? label;
  final bool isRed;
  final bool isGreen;

  const QtyBox({
    super.key,
    this.initialValue,
    this.onChanged,
    this.isEditable = true,
    this.label,
    this.isRed = false,
    this.isGreen = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEditable) {
      return Container(
        width: 60,
        height: 35,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          initialValue?.isEmpty ?? true ? "0" : initialValue!,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
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
        scrollPadding: const EdgeInsets.only(bottom: 220),
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
            borderSide: BorderSide(
              color: isGreen
                  ? Colors.green
                  : (isRed ? AppColors.primary : AppColors.border),
              width: isGreen ? 1.5 : 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: isGreen
                  ? Colors.green
                  : (isRed ? AppColors.primary : AppColors.border),
              width: isGreen ? 1.5 : 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: isGreen
                  ? Colors.green.shade700
                  : (isRed ? AppColors.primary : AppColors.primary),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class FocusedBrandTag extends StatelessWidget {
  final double fontSize;
  final double iconSize;

  const FocusedBrandTag({
    super.key,
    this.fontSize = 10,
    this.iconSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars, color: Colors.amber, size: iconSize),
          const SizedBox(width: 4),
          Text(
            "FOCUSED BRAND",
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isFocused;

  const ProductCard({
    super.key,
    required this.title,
    required this.children,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isFocused ? const Color(0xFFE8F5E9) : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? Colors.green.shade500 : AppColors.primary.withValues(alpha: 0.1),
          width: isFocused ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isFocused
                ? Colors.green.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isFocused) ...[
                  const FocusedBrandTag(),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isFocused ? const Color(0xFF1B5E20) : AppColors.primary,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class LogoProgressIndicator extends StatelessWidget {
  final double size;
  final String? message;
  final TextStyle? messageStyle;

  const LogoProgressIndicator({
    super.key,
    this.size = 60,
    this.message = "Please wait, loading...",
    this.messageStyle,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        Image.asset(
          ImageConstants.appLogo,
          width: size * 0.55,
          height: size * 0.55,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ],
    );

    if (message != null && message!.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            indicator,
            const SizedBox(height: 14),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: messageStyle ??
                  TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 0.3,
                  ),
            ),
          ],
        ),
      );
    }

    return Center(child: indicator);
  }
}

typedef AppLoadingWidget = LogoProgressIndicator;
typedef InbuiltLoadingWidget = LogoProgressIndicator;

class LoadingDialog {
  static void show(BuildContext context, {String message = "Please wait..."}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LogoProgressIndicator(size: 70, message: null),
                    const SizedBox(height: 20),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}

class SuccessDialog {
  static void show(BuildContext context, {required String message, VoidCallback? onDismiss}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Logo in the middle
                Image.asset(
                  ImageConstants.appLogo,
                  width: 70,
                  height: 70,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                     Icons.check_circle,
                     color: Colors.green,
                     size: 70,
                   ),
                 ),
                 const SizedBox(height: 16),
                 
                 // Checked success icon
                 const Icon(
                   Icons.check_circle_outline,
                   color: Colors.green,
                   size: 40,
                 ),
                const SizedBox(height: 12),

                // Success message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                // OK Button
                SizedBox(
                  width: 120,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (onDismiss != null) {
                        onDismiss();
                      }
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
  }
}
