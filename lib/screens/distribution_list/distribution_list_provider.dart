import 'package:flutter/material.dart';
import '../../services/api_services.dart';

class DistributionListProvider extends ChangeNotifier {
  DistributionListProvider() {
    _selectedMonth = _months[DateTime.now().month - 1];
  }

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
  late String _selectedMonth;
  int _selectedYear = DateTime.now().year;

  List<String> get months => _months;
  String get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  void setSelectedMonth(String month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void setSelectedYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  Map<String, List<Map<String, dynamic>>> _submissions = {};
  Map<String, List<Map<String, dynamic>>> get submissions => _submissions;

  String? _submitStockError;
  String? get submitStockError => _submitStockError;

  void clearSubmitError() {
    _submitStockError = null;
    notifyListeners();
  }
  
  bool _isLoadingStock = false;
  bool get isLoadingStock => _isLoadingStock;

  // Distributor Selection and Creation State
  bool _isLoadingDistributors = false;
  bool get isLoadingDistributors => _isLoadingDistributors;

  List<dynamic> _distributors = [];
  List<dynamic> get distributors => _distributors;

  dynamic _selectedDistributor;
  dynamic get selectedDistributor => _selectedDistributor;

  int _selectedStockMonth = DateTime.now().month;
  int get selectedStockMonth => _selectedStockMonth;

  int _selectedStockYear = DateTime.now().year;
  int get selectedStockYear => _selectedStockYear;

  void selectDistributor(dynamic dist) {
    _selectedDistributor = dist;
    notifyListeners();
  }

  void setStockMonth(int month) {
    _selectedStockMonth = month;
    notifyListeners();
  }

  void setStockYear(int year) {
    _selectedStockYear = year;
    notifyListeners();
  }

  Future<void> fetchDistributorsList() async {
    _isLoadingDistributors = true;
    notifyListeners();

    final response = await ApiServices.getDistributors();
    if (response != null && response['status'] == true) {
      _distributors = response['data'] ?? [];
      if (_selectedDistributor != null) {
        final existingId = _selectedDistributor['distributor_id']?.toString();
        final match = _distributors.firstWhere(
          (d) => d['distributor_id']?.toString() == existingId,
          orElse: () => null,
        );
        if (match != null) {
          _selectedDistributor = match;
        } else {
          _selectedDistributor = _distributors.isNotEmpty ? _distributors.first : null;
        }
      } else if (_distributors.isNotEmpty) {
        _selectedDistributor = _distributors.first;
      }
    } else {
      _distributors = [];
      _selectedDistributor = null;
    }

    _isLoadingDistributors = false;
    notifyListeners();
  }

  Future<bool> createDistributor(Map<String, dynamic> payload) async {
    final response = await ApiServices.createDistributor(payload: payload);
    if (response != null && response['status'] == true) {
      await fetchDistributorsList();
      return true;
    }
    return false;
  }

  Future<void> fetchDistributorStock(int distributorId) async {
    _isLoadingStock = true;
    notifyListeners();

    // Map month name to number
    final monthMap = {
      "January": 1, "February": 2, "March": 3, "April": 4, "May": 5, "June": 6,
      "July": 7, "August": 8, "September": 9, "October": 10, "November": 11, "December": 12
    };
    final monthNum = monthMap[_selectedMonth] ?? DateTime.now().month;
    final year = _selectedYear;
    final lastDay = DateTime(year, monthNum + 1, 0).day;
    final fromDate = "$year-${monthNum.toString().padLeft(2, '0')}-01";
    final toDate = "$year-${monthNum.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}";

    final payload = {
      "distributor_id": distributorId,
      "from_date": fromDate,
      "to_date": toDate,
      "limit": 50,
      "offset": 0
    };

    final response = await ApiServices.getDistributorStockHistory(payload: payload);
    _submissions.clear();

    if (response != null && response['status'] == "success") {
      final data = response['data'] as List<dynamic>? ?? [];
      for (var record in data) {
        final createdAt = record['created_at']?.toString() ?? "";
        final recordYear = record['year']?.toString() ?? record['stock_year']?.toString();
        final recordMonth = record['month']?.toString() ?? record['stock_month']?.toString();
        final items = record['items'] as List<dynamic>? ?? [];
        if (createdAt.isNotEmpty) {
          final datePart = createdAt.split(' ')[0];
          try {
            final parsedDate = DateTime.parse(datePart);
            if (parsedDate.year == year && parsedDate.month == monthNum) {
              if (!_submissions.containsKey(datePart)) {
                _submissions[datePart] = [];
              }
              for (var item in items) {
                _submissions[datePart]!.add({
                  "product_id": item['product_id'],
                  "product_name": item['product_name'] ?? 'Unknown Product',
                  "sku_name": item['sku_name'] ?? item['sku_displayname'] ?? item['sku_id']?.toString() ?? 'Unknown SKU',
                  "qty": item['quantity']?.toString() ?? "0",
                  "distributor_name": record['distributor_name'] ?? "",
                  "stock_year": recordYear ?? parsedDate.year.toString(),
                  "stock_month": recordMonth ?? parsedDate.month.toString(),
                });
              }
            }
          } catch (_) {
            if (!_submissions.containsKey(datePart)) {
              _submissions[datePart] = [];
            }
            for (var item in items) {
              _submissions[datePart]!.add({
                "product_id": item['product_id'],
                "product_name": item['product_name'] ?? 'Unknown Product',
                "sku_name": item['sku_name'] ?? item['sku_displayname'] ?? item['sku_id']?.toString() ?? 'Unknown SKU',
                "qty": item['quantity']?.toString() ?? "0",
                "distributor_name": record['distributor_name'] ?? "",
                "stock_year": recordYear ?? year.toString(),
                "stock_month": recordMonth ?? monthNum.toString(),
              });
            }
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

  Future<bool> submitDistributorStock(int? distributorId) async {
    _submitStockError = null;
    final distId = _selectedDistributor != null
        ? int.tryParse(_selectedDistributor['distributor_id']?.toString() ?? '')
        : distributorId;

    if (distId == null) {
      _submitStockError = "Distributor ID is invalid";
      return false;
    }

    List<Map<String, dynamic>> items = [];

    _stockQuantities.forEach((key, quantity) {
      if (quantity > 0) {
        final parts = key.split('_');
        final productId = int.parse(parts[0]);
        final skuId = int.parse(parts[1]);
        
        items.add({
          "product_id": productId,
          "sku_id": skuId,
          "quantity": quantity,
        });
      }
    });

    if (items.isEmpty) {
      _submitStockError = "Please enter stock quantity for at least one item";
      return false; // Nothing to submit
    }

    final payload = {
      "distributor_id": distId,
      "month": DateTime.now().month,
      "year": DateTime.now().year,
      "items": items,
    };

    print("SUBMITTING DISTRIBUTOR STOCK DATA PAYLOAD: $payload");
    final response = await ApiServices.distributorStockInsert(payload: payload);
    
    if (response != null && response['status'] == "success") {
      _stockQuantities.clear();
      notifyListeners();
      return true;
    }

    if (response != null) {
      final message = response['message']?.toString().toLowerCase() ?? "";

      if (message.contains("stock already uploaded")) {
        _submitStockError =
        "Stock has already been submitted for the selected distributor.";
      } else {
        _submitStockError = response['message']?.toString() ?? "Failed to submit stock.";
      }
    } else {
      _submitStockError = "Failed to submit stock.";
    }

    notifyListeners();
    return false;
  }
}
