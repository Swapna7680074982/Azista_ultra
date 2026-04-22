import 'package:azista_ultra/permissions/AppStateProvider.dart';
import 'package:azista_ultra/screens/Distribution_networking/distribution_provider.dart';
import 'package:azista_ultra/screens/Distribution_networking/outlets/outlet_provider.dart';
import 'package:azista_ultra/screens/Homes/main_tab_provider.dart';
import 'package:azista_ultra/screens/attendance/attendance_provider.dart';
import 'package:azista_ultra/screens/login/login_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> providerCreateList = [
  ChangeNotifierProvider<LoginProvider>(
    create: (_) => LoginProvider(),
  ),
  ChangeNotifierProvider<MainTabProvider>(
    create: (_) => MainTabProvider(),
  ),
  ChangeNotifierProvider<AttendanceProvider>(
    create: (_) => AttendanceProvider(),
  ),
  ChangeNotifierProvider<DistributionProvider>(
    create: (_) => DistributionProvider(),
  ),
  ChangeNotifierProvider<OutletProvider>(
    create: (_) => OutletProvider(),
  ),
  ChangeNotifierProvider<AppStateProvider>(
    create: (_) => AppStateProvider(),
  ),
];