import 'package:flutter/cupertino.dart';

import '../../permissions/SessionManager.dart';

class HomeProvider extends ChangeNotifier {
  List distributors = [];
  String? selectedDistributor;

  Future<void> loadDistributors() async {
    distributors = await SessionManager.getDistributors();
    notifyListeners();
  }
}