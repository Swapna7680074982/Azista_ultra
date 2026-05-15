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
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>?> updateStatus(String action, String expenseId) async {
    _isLoading = true;
    notifyListeners();
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
    _isLoading = false;
    notifyListeners();
    return response;
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
      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      }
    } catch (e) {
      // Fallback
      try {
        final response = await dio_pkg.Dio().get(
          url,
          options: dio_pkg.Options(responseType: dio_pkg.ResponseType.bytes),
        );
        if (response.statusCode == 200) {
          return Uint8List.fromList(response.data);
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
