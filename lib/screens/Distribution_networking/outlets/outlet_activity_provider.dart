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
}
