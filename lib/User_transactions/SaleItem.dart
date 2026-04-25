import 'package:flutter/material.dart';

class SaleItem {
  final String name;
  final String quantity;

  SaleItem({required this.name, required this.quantity});
}

class TransactionProvider extends ChangeNotifier {
  List<SaleItem> saleItems = [
    SaleItem(name: "KWIK MINT BURST (BOXES)", quantity: "2 BOXES"),
    SaleItem(name: "KWIK MINT ZING (BOXES)", quantity: "3 BOXES"),
  ];
}