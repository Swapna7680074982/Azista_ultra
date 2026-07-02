import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../services/api_services.dart';

class OutletActivityProvider extends ChangeNotifier {
  bool _isLoadingProducts = false;
  bool get isLoadingProducts => _isLoadingProducts;

  List<dynamic> _productsWithSkus = [];
  List<dynamic> get productsWithSkus => _productsWithSkus;

  List<String> get products {
    return _productsWithSkus.map<String>((p) => p['product_name']?.toString() ?? 'Unknown').toList();
  }

  // Map to hold stock quantities: key is "productId_skuId", value is quantity
  final Map<String, int> _stockQuantities = {};
  Map<String, int> get stockQuantities => _stockQuantities;

  final Map<String, int> _saleQuantities = {};
  Map<String, int> get saleQuantities => _saleQuantities;

  final Map<String, int> _samplingQuantities = {};
  Map<String, int> get samplingQuantities => _samplingQuantities;

  bool _isLoadingDistributorStock = false;
  bool get isLoadingDistributorStock => _isLoadingDistributorStock;

  final Map<String, int> _distributorStock = {};
  Map<String, int> get distributorStock => _distributorStock;

  bool _isLoadingPobHistory = false;
  bool get isLoadingPobHistory => _isLoadingPobHistory;

  List<dynamic> _pendingPobs = [];
  List<dynamic> get pendingPobs => _pendingPobs;

  List<dynamic> _suppliedPobs = [];
  List<dynamic> get suppliedPobs => _suppliedPobs;

  Future<void> fetchDistributorStock(int distributorId) async {
    _isLoadingDistributorStock = true;
    notifyListeners();

    final response = await ApiServices.getDistributorStock(distributorId: distributorId);
    if (response != null && response['status'] == true) {
      _distributorStock.clear();
      final data = response['data'] as List<dynamic>? ?? [];
      for (var product in data) {
        final productId = product['product_id'];
        final skus = product['skus'] as List<dynamic>? ?? [];
        for (var sku in skus) {
          final skuId = sku['sku_id'];
          final stockQty = sku['stock_qty'] ?? 0;
          _distributorStock["${productId}_$skuId"] = stockQty is int ? stockQty : int.tryParse(stockQty.toString()) ?? 0;
        }
      }
    }

    _isLoadingDistributorStock = false;
    notifyListeners();
  }

  Future<void> fetchProductsWithSkus({bool forceRefresh = false}) async {
    if (_productsWithSkus.isNotEmpty && !forceRefresh) {
      _stockQuantities.clear();
      _saleQuantities.clear();
      _samplingQuantities.clear();
      notifyListeners();
      return;
    }

    _isLoadingProducts = true;
    notifyListeners();

    final response = await ApiServices.getProductsWithSkus();
    if (response != null && response['status'] == true) {
      _productsWithSkus = response['data'] ?? [];
      _stockQuantities.clear();
      _saleQuantities.clear();
      _samplingQuantities.clear();
    }

    _isLoadingProducts = false;
    notifyListeners();
  }

  void clearQuantities() {
    _stockQuantities.clear();
    _saleQuantities.clear();
    _samplingQuantities.clear();
    notifyListeners();
  }

  void updateStockQuantity(int productId, int skuId, String value) {
    int qty = int.tryParse(value) ?? 0;
    _stockQuantities["${productId}_$skuId"] = qty;
    notifyListeners();
  }

  void updateSaleQuantity(int productId, int skuId, String value) {
    int qty = int.tryParse(value) ?? 0;
    _saleQuantities["${productId}_$skuId"] = qty;
    notifyListeners();
  }

  void updateSamplingQuantity(int productId, int skuId, String value) {
    int qty = int.tryParse(value) ?? 0;
    _samplingQuantities["${productId}_$skuId"] = qty;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> submitPosTransaction(String posType, int outletId, {int? distributorId}) async {
    Map<String, int> targetMap;
    if (posType == "sale") {
      targetMap = _saleQuantities;
    } else if (posType == "sampling") {
      targetMap = _samplingQuantities;
    } else {
      targetMap = _stockQuantities;
    }

    List<Map<String, dynamic>> items = [];

    targetMap.forEach((key, quantity) {
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
      return {"status": false, "message": "Please enter quantities"};
    }

    final payload = {
      "pos_type": posType,
      if (distributorId != null) "distributor_id": distributorId,
      "outlet_id": outletId,
      "items": items,
    };

    final response = await ApiServices.submitPosTransaction(payload: payload);
    
    if (response != null && response['status'] == "success") {
      targetMap.clear();
      notifyListeners();
      return {"status": true, "message": response['message'] ?? "$posType transaction success"};
    }
    return {"status": false, "message": "Transaction failed"};
  }

  Future<bool> submitPob(int outletId, {int? distributorId, File? imageFile, String remarks = ""}) async {
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
      return false; 
    }

    final response = await ApiServices.generatePob(
      outletId: outletId.toString(),
      distributorId: distributorId?.toString(),
      itemsJson: jsonEncode(items),
      remarks: remarks,
      orderCopy: imageFile,
    );
    
    if (response != null && response['status'] == "success") {
      _stockQuantities.clear();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> fetchPobHistory(int outletId, {int? distributorId}) async {
    _isLoadingPobHistory = true;
    notifyListeners();

    final payload = {
      "outlet_id": outletId,
    };

    final response = await ApiServices.getPobHistory(payload: payload);
    if (response != null && response['status'] == "success") {
      final data = response['data'] as List<dynamic>? ?? [];
      final List<dynamic> normalizedData = [];
      for (var pob in data) {
        if (pob is Map) {
          final pobMap = Map<String, dynamic>.from(pob);
          final items = pobMap['items'] as List<dynamic>? ?? [];
          bool allItemsSupplied = false;
          if (items.isNotEmpty) {
            allItemsSupplied = true;
            for (var item in items) {
              final double quantity = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
              final double remainingQty = double.tryParse(item['remaining_qty']?.toString() ?? '0') ?? 0;
              final double suppliedQty = double.tryParse(item['supplied_qty']?.toString() ?? '0') ?? 0;
              
              if (item['remaining_qty'] != null) {
                if (remainingQty > 0) {
                  allItemsSupplied = false;
                  break;
                }
              } else {
                if (suppliedQty < quantity) {
                  allItemsSupplied = false;
                  break;
                }
              }
            }
          }
          if (allItemsSupplied || pobMap['status'] == 'supplied') {
            pobMap['status'] = 'supplied';
          }
          normalizedData.add(pobMap);
        } else {
          normalizedData.add(pob);
        }
      }
      _pendingPobs = normalizedData.where((pob) => pob['status'] == 'pending' || pob['status'] == 'partial').toList();
      _suppliedPobs = normalizedData.where((pob) => pob['status'] == 'supplied').toList();
    } else {
      _pendingPobs = [];
      _suppliedPobs = [];
    }

    _isLoadingPobHistory = false;
    notifyListeners();
  }

  List<dynamic> _activityTypes = [];
  List<dynamic> get activityTypes => _activityTypes;
  bool _isLoadingActivityTypes = false;
  bool get isLoadingActivityTypes => _isLoadingActivityTypes;

  Future<void> fetchActivityTypes() async {
    _isLoadingActivityTypes = true;
    notifyListeners();

    try {
      final response = await ApiServices.getActivityTypes();
      if (response != null && response['status'] == true) {
        _activityTypes = response['data'] ?? [];
      } else {
        _activityTypes = [];
      }
    } catch (e) {
      _activityTypes = [];
    }

    if (_activityTypes.isEmpty) {
      _activityTypes = [
        {"activity_type_id": "13", "activity_name": "Branding"},
        {"activity_type_id": "10", "activity_name": "Banner"},
        {"activity_type_id": "11", "activity_name": "Poster"},
        {"activity_type_id": "12", "activity_name": "Pamphlet"},
        {"activity_type_id": "7", "activity_name": "Collection"},
        {"activity_type_id": "5", "activity_name": "Competitor Activity"},
        {"activity_type_id": "8", "activity_name": "Feedback"},
        {"activity_type_id": "9", "activity_name": "New Outlet Registration"},
        {"activity_type_id": "1", "activity_name": "POB"},
        {"activity_type_id": "2", "activity_name": "POS Sale"},
        {"activity_type_id": "3", "activity_name": "POS Sampling"},
        {"activity_type_id": "4", "activity_name": "POS Stock"},
        {"activity_type_id": "6", "activity_name": "Product Display"}
      ];
    }

    _isLoadingActivityTypes = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> submitOutletActivity({
    required int visitId,
    required String activityTypeId,
    required String remarks,
    required List<File> files,
    int? productId,
    int? skuId,
  }) async {
    try {
      final response = await ApiServices.createOutletActivity(
        visitId: visitId.toString(),
        activityTypeId: activityTypeId,
        remarks: remarks,
        productId: productId?.toString(),
        skuId: skuId?.toString(),
        attachments: files,
      );

      if (response != null && response['status'] == true) {
        return {
          "status": true,
          "message": response['message'] ?? "Activity created successfully",
          "activity_id": response['activity_id'],
        };
      }
      return {
        "status": false,
        "message": response?['message'] ?? "Failed to create activity",
      };
    } catch (e) {
      return {
        "status": false,
        "message": "Submission error: $e",
      };
    }
  }

  List<dynamic> _activityHistory = [];
  List<dynamic> get activityHistory => _activityHistory;
  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  Future<void> fetchOutletHistory(int outletId) async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      final response = await ApiServices.getOutletHistory(outletId: outletId);
      if (response != null && response['status'] == true) {
        final visitHistory = response['visit_history'] as List<dynamic>? ?? [];
        final List<dynamic> allActivities = [];
        for (var visit in visitHistory) {
          final activities = visit['activity_history'] as List<dynamic>? ?? [];
          for (var act in activities) {
            allActivities.add({
              ...act,
              "visit_date": visit['visit_date'],
            });
          }
        }
        allActivities.sort((a, b) {
          final dateA = a['activity_date']?.toString() ?? '';
          final dateB = b['activity_date']?.toString() ?? '';
          return dateB.compareTo(dateA);
        });
        _activityHistory = allActivities;
      } else {
        _activityHistory = [];
      }
    } catch (e) {
      _activityHistory = [];
    }

    _isLoadingHistory = false;
    notifyListeners();
  }
}
