import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../models/expense_model.dart';
import '../../permissions/SessionManager.dart';
import 'package:dio/dio.dart' as dio_pkg;

class DistributorExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String _userRole = "";

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String get userRole => _userRole;

  Future<void> init() async {
    _userRole = await SessionManager.getUserRole();
    await fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiServices.getExpenses();
      if (response != null && response['status'] == true) {
        final List data = response['data'] ?? [];
        _expenses = data.map((e) => Expense.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching expenses: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> addExpense({
    required String distributorId,
    required String expenseDate,
    required String expenseAmount,
    required String description,
    required String expenseType,
    required String paymentMode,
    File? expenseBill,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiServices.addExpense(
        distributorId: distributorId,
        expenseDate: expenseDate,
        expenseAmount: expenseAmount,
        description: description,
        expenseType: expenseType,
        paymentMode: paymentMode,
        expenseBill: expenseBill,
      );
      if (result != null && result['status'] == true) {
        await fetchExpenses();
      }
      return result;
    } catch (e) {
      debugPrint("Error adding expense: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> updateStatus(String action, String expenseId) async {
    _isLoading = true;
    notifyListeners();
    try {
      Map<String, dynamic>? response;

      if (action == 'submit_to_am') {
        response = await ApiServices.submitToAm(expenseId);
      } else if (action == 'receive_from_so') {
        response = await ApiServices.receiveFromSo(expenseId);
      } else if (action == 'submit_to_admin') {
        response = await ApiServices.submitToAdmin(expenseId);
      }

      if (response != null && response['status'] == true) {
        await fetchExpenses();
      }
      return response;
    } catch (e) {
      debugPrint("Error updating status: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isValidImageBytes(List<int> bytes) {
    if (bytes.length < 4) return false;
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return true;
    }
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }
    // GIF: 47 49 46
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return true;
    }
    // WEBP: RIFF ... WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return true;
    }
    return false;
  }

  // Image loading helper
  Future<Uint8List?> loadImage(String imageUrl) async {
    String url = imageUrl.trim();
    if (url.isEmpty || 
        url == "https://services.heterohcl.com/ultra-iris-v2/" || 
        url == "https://services.heterohcl.com/ultra-iris-v2") {
      return null;
    }
    
    if (!url.startsWith('http')) {
      url = "https://services.heterohcl.com/ultra-iris-v2/${url.startsWith('/') ? url.substring(1) : url}";
    }

    try {
      final token = await SessionManager.getToken();
      final response = await dio_pkg.Dio().get(
        url,
        options: dio_pkg.Options(
          responseType: dio_pkg.ResponseType.bytes,
          headers: {"Authorization": "Bearer $token"},
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        final bytes = response.data as List<int>;
        if (_isValidImageBytes(bytes)) {
          return Uint8List.fromList(bytes);
        } else {
          debugPrint("Downloaded bytes do not match expected image headers");
        }
      }
    } catch (e) {
      // Fallback
      try {
        final response = await dio_pkg.Dio().get(
          url,
          options: dio_pkg.Options(responseType: dio_pkg.ResponseType.bytes),
        );
        if (response.statusCode == 200 && response.data != null) {
          final bytes = response.data as List<int>;
          if (_isValidImageBytes(bytes)) {
            return Uint8List.fromList(bytes);
          } else {
            debugPrint("Downloaded bytes do not match expected image headers (fallback)");
          }
        }
      } catch (err) {
        debugPrint("Error fallback loading image: $err");
      }
    }
    return null;
  }

  bool isStepCompleted(String currentStatus, int step) {
    String status = currentStatus.toLowerCase().trim();
    if (step == 0) return true;
    if (step == 1) return status == 'submitted' || status == 'received' || status == 'submitted to admin' || status == 'so' || status == 'asm';
    if (step == 2) return status == 'submitted' || status == 'received' || status == 'submitted to admin' || status == 'asm';
    if (step == 3) return status == 'submitted' || status == 'submitted to admin';
    return false;
  }
}
