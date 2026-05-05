import 'package:flutter/material.dart';
import '../../services/api_services.dart';

class DistributionListProvider extends ChangeNotifier {
  // DistributorStatusScreen State
  List<bool> _statusList = [true, false, false, false];
  List<bool> _buttonEnabled = [false, true, false, false];

  List<bool> get statusList => _statusList;
  List<bool> get buttonEnabled => _buttonEnabled;

  void updateStatus(int index) {
    _statusList[index] = true;
    _buttonEnabled[index] = false;
    if (index + 1 < _buttonEnabled.length) {
      _buttonEnabled[index + 1] = true;
    }
    notifyListeners();
  }

  // StockOnHandScreen State
  final List<String> _months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];
  String _selectedMonth = "April";

  List<String> get months => _months;
  String get selectedMonth => _selectedMonth;

  void setSelectedMonth(String month) {
    _selectedMonth = month;
    notifyListeners();
  }

  Map<String, List<Map<String, dynamic>>> _submissions = {};
  Map<String, List<Map<String, dynamic>>> get submissions => _submissions;
  
  bool _isLoadingStock = false;
  bool get isLoadingStock => _isLoadingStock;

  Future<void> fetchDistributorStock(int distributorId) async {
    _isLoadingStock = true;
    notifyListeners();

    final response = await ApiServices.getDistributorStock(distributorId: distributorId);
    _submissions.clear();

    if (response != null && response['status'] == true) {
      final data = response['data'] as List<dynamic>? ?? [];
      for (var product in data) {
        final skus = product['skus'] as List<dynamic>? ?? [];
        for (var sku in skus) {
          final createdOn = sku['created_on']?.toString() ?? "";
          if (createdOn.isNotEmpty) {
            // e.g. "2026-05-05 10:12:07" -> "2026-05-05"
            final datePart = createdOn.split(' ')[0]; 
            if (!_submissions.containsKey(datePart)) {
              _submissions[datePart] = [];
            }
            _submissions[datePart]!.add({
              "name": sku['display_name'] ?? 'Unknown SKU',
              "qty": sku['stock_qty']?.toString() ?? "0",
            });
          }
        }
      }
    }

    _isLoadingStock = false;
    notifyListeners();
  }

  // DistributorStockScreen State
  bool _isLoadingProducts = false;
  bool get isLoadingProducts => _isLoadingProducts;

  List<dynamic> _productsWithSkus = [];
  List<dynamic> get productsWithSkus => _productsWithSkus;

  // Map to hold stock quantities: key is "productId_skuId", value is quantity
  final Map<String, int> _stockQuantities = {};
  Map<String, int> get stockQuantities => _stockQuantities;

  Future<void> fetchProductsWithSkus() async {
    _isLoadingProducts = true;
    notifyListeners();

    final response = await ApiServices.getProductsWithSkus();
    if (response != null && response['status'] == true) {
      _productsWithSkus = response['data'] ?? [];
      _stockQuantities.clear();
    }

    _isLoadingProducts = false;
    notifyListeners();
  }

  void updateStockQuantity(int productId, int skuId, String value) {
    int qty = int.tryParse(value) ?? 0;
    _stockQuantities["${productId}_$skuId"] = qty;
  }

  Future<bool> submitDistributorStock(int distributorId) async {
    List<Map<String, dynamic>> stocks = [];

    _stockQuantities.forEach((key, quantity) {
      if (quantity > 0) {
        final parts = key.split('_');
        final productId = int.parse(parts[0]);
        final skuId = int.parse(parts[1]);
        
        stocks.add({
          "product_id": productId,
          "sku_id": skuId,
          "quantity": quantity,
        });
      }
    });

    if (stocks.isEmpty) {
      return false; // Nothing to submit
    }

    final payload = {
      "distributor_id": distributorId,
      "stocks": stocks,
    };

    final response = await ApiServices.insertDistributorStock(payload: payload);
    
    if (response != null && response['status'] == true) {
      _stockQuantities.clear();
      notifyListeners();
      return true;
    }
    return false;
  }
}
