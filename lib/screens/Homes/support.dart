import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/call_service.dart';
import '../../services/api_services.dart';
import '../../utilities/common_widgets.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late Future<Map<String, dynamic>?> _supportFuture;

  @override
  void initState() {
    super.initState();
    _loadSupportTeam();
  }

  void _loadSupportTeam() {
    setState(() {
      _supportFuture = ApiServices.getSupportTeam();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _supportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LogoProgressIndicator());
        }

        final data = snapshot.data?['data'] as List<dynamic>? ?? [];
        final techTeam = data.where((m) => m['support_type'] == 'TECH').toList();
        final productTeam = data.where((m) => m['support_type'] == 'PRODUCT').toList();

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.button,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              centerTitle: true,
              title: const Text(
                "SUPPORT",
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              iconTheme: const IconThemeData(
                color: AppColors.white,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sync, color: AppColors.white),
                  tooltip: "Refresh Support",
                  onPressed: () {
                    _loadSupportTeam();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Refreshing support team..."),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: const Color(0xFF8C7B87),
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: "TECH"),
                      Tab(text: "PRODUCT"),
                    ],
                  ),
                ),
              ),
            ),
            body: TabBarView(
              children: [
                _buildTeamList(techTeam),
                _buildTeamList(productTeam),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamList(List<dynamic> team) {
    if (team.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _loadSupportTeam(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Center(child: Text("NO SUPPORT MEMBERS FOUND")),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _loadSupportTeam(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: team.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final member = team[index];
          return ListTile(
            title: Text(
              (member['name'] ?? "").toString().toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(member['designation'] ?? ""),
            trailing: const Icon(Icons.call, color: AppColors.buttonBlue),
            onTap: () {
              CallService.makeCall(member['mobile']?.toString() ?? "");
            },
          );
        },
      ),
    );
  }
}
