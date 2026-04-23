import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import 'distribution_list_provider.dart';
class DistributorStatusScreen extends StatefulWidget {
  const DistributorStatusScreen({super.key});

  @override
  State<DistributorStatusScreen> createState() =>
      _DistributorStatusScreenState();
}

class _DistributorStatusScreenState
    extends State<DistributorStatusScreen> {

  @override
  Widget build(BuildContext context) {
    return Consumer<DistributionListProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text(
          "Distribution Expenses status",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Created On"),
                        SizedBox(height: 4),
                        Text("2026-04-23 09:50:37",
                            style: TextStyle(fontWeight: FontWeight.bold)),

                        SizedBox(height: 10),

                        Text("Payment Type Bvv"),
                        SizedBox(height: 4),
                        Text("₹99.00",
                            style: TextStyle(fontWeight: FontWeight.bold)),

                        SizedBox(height: 10),

                        Text("Comments"),
                        SizedBox(height: 4),
                        Text("Vv"),
                      ],
                    ),
                  ),
                  Container(
                    height: 90,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  )
                ],
              ),
            ),

            const Divider(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      _timelineIcon(provider.statusList[0]),
                      _dottedLine(),
                      _timelineIcon(provider.statusList[1]),
                      _dottedLine(),
                      _timelineIcon(provider.statusList[2]),
                      _dottedLine(),
                      _timelineIcon(provider.statusList[3]),
                    ],
                  ),

                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [

                        _statusCard(
                          provider,
                          index: 0,
                          title: "Collected from Distributor",
                          date: "2026-04-23 09:50:37",
                        ),

                        _statusCard(
                          provider,
                          index: 1,
                          title: "Submitted to ASM",
                          date: "0000-00-00 00:00:00",
                          showButton: true,
                        ),

                        _statusCard(
                          provider,
                          index: 2,
                          title: "Received from SO to ASM",
                          date: "0000-00-00 00:00:00",
                        ),

                        _statusCard(
                          provider,
                          index: 3,
                          title: "Submitted to Admin",
                          date: "0000-00-00 00:00:00",
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }
  Widget _timelineIcon(bool isCompleted) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Icon(
        isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
        color: isCompleted ? Colors.black : Colors.grey,
      ),
    );
  }
  Widget _dottedLine() {
    return SizedBox(
      height: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          6,
              (index) => Container(
            width: 2,
            height: 5,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
  Widget _statusCard(
    DistributionListProvider provider, {
    required int index,
    required String title,
    required String date,
    bool showButton = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: provider.statusList[index]
                        ? Colors.black
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          if (showButton)
            ElevatedButton(
              onPressed: provider.buttonEnabled[index]
                  ? () {
                      provider.updateStatus(index);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Updated successfully")),
                );
              }
                  : null,

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),

                child:  Text("Update",style: TextStyle(color: AppColors.white)),
              ),
        ],
      ),
    );
  }
}