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

  Future<void> fetchProductsWithSkus() async {
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

  void updateStockQuantity(int productId, int skuId, String value) {
    int qty = int.tryParse(value) ?? 0;
    _stockQuantities["${productId}_$skuId"] = qty;
  }

  void updateSaleQuantity(int productId, int skuId, String value) {
    int qty = int.tryParse(value) ?? 0;
    _saleQuantities["${productId}_$skuId"] = qty;
  }

  void updateSamplingQuantity(int productId, int skuId, String value) {
    int qty = int.tryParse(value) ?? 0;
    _samplingQuantities["${productId}_$skuId"] = qty;
  }

  Future<Map<String, dynamic>?> submitPosTransaction(String posType, int outletId, int distributorId) async {
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
      "distributor_id": distributorId,
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

  Future<bool> submitPob(int outletId, int distributorId) async {
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

    final payload = {
      "outlet_id": outletId,
      "distributor_id": distributorId,
      "remarks": "",
      "items": items,
    };

    final response = await ApiServices.generatePob(payload: payload);
    
    if (response != null && response['status'] == "success") {
      _stockQuantities.clear();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> fetchPobHistory(int outletId, int distributorId) async {
    _isLoadingPobHistory = true;
    notifyListeners();

    final payload = {
      "outlet_id": outletId,
      "distributor_id": distributorId,
    };

    final response = await ApiServices.getPobHistory(payload: payload);
    if (response != null && response['status'] == "success") {
      final data = response['data'] as List<dynamic>? ?? [];
      _pendingPobs = data.where((pob) => pob['status'] == 'pending' || pob['status'] == 'partial').toList();
      _suppliedPobs = data.where((pob) => pob['status'] == 'supplied').toList();
    } else {
      _pendingPobs = [];
      _suppliedPobs = [];
    }

    _isLoadingPobHistory = false;
    notifyListeners();
  }
}
