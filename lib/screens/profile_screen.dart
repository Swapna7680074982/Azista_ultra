import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../permissions/SessionManager.dart';
import '../../permissions/AppStateProvider.dart';
import 'Homes/HomeProvider.dart';
import '../../services/api_services.dart';
import 'login/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userInfo;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final info = await SessionManager.getUserInfo();
    setState(() {
      userInfo = info;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "PROFILE",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildInfoList(),
                  const SizedBox(height: 40),
                  _buildLogoutButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: statusBarHeight + kToolbarHeight + 15,
        bottom: 30,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.button,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
           const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 60, color: AppColors.button),
          ),
          const SizedBox(height: 15),
          Text(
            userInfo?['name'] ?? "Unknown",
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            "Emp ID: ${userInfo?['employee_id'] ?? "N/A"}",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Personal Information",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 15),
          _buildInfoTile(Icons.phone_android, "Mobile Number", userInfo?['mobile']),
          _buildInfoTile(Icons.email_outlined, "Email Address", userInfo?['email']),
          _buildInfoTile(Icons.work_outline, "Role", userInfo?['rolecode']),
          const Divider(height: 30),
          const Text(
            "Office Information",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 15),
          _buildInfoTile(Icons.location_on_outlined, "Regional Office", userInfo?['regionaloffice']),
          _buildInfoTile(Icons.supervisor_account, "Reporting Manager", userInfo?['reporting_manager_name']),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.button, size: 20),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              Text(
                value ?? "N/A",
                style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: () => _handleLogout(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.button.withValues(alpha: 0.1),
            foregroundColor: AppColors.button,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: AppColors.button.withValues(alpha: 0.2)),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout),
              SizedBox(width: 10),
              Text("Logout", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: AppColors.button)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Pre-capture providers and navigator before async operations
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final navigator = Navigator.of(context);

      // Call server-side logout first (same as SO)
      await ApiServices.logout();
      
      await SessionManager.clearSession();

      // Reset providers to prevent state leakage to next session
      appState.reset();
      homeProvider.reset();

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) =>  LoginScreen()),
        (route) => false,
      );
    }
  }
}
