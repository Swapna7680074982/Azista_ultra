import 'package:azista_ultra/screens/login/login_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> providerCreateList = [
  ChangeNotifierProvider<LoginProvider>(
    create: (_) => LoginProvider(),
  ),
];