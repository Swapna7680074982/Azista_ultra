import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/call_service.dart';
import '../../services/api_services.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ApiServices.getSupportTeam(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data?['data'] as List<dynamic>? ?? [];
        final techTeam = data.where((m) => m['support_type'] == 'TECH').toList();
        final productTeam = data.where((m) => m['support_type'] == 'PRODUCT').toList();

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              title: const Text(
                "SUPPORT",
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              iconTheme: const IconThemeData(
                color: AppColors.white,
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
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
      return const Center(child: Text("NO SUPPORT MEMBERS FOUND"));
    }
    return ListView.separated(
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
    );
  }
}
