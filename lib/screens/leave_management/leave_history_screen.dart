import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'leave_provider.dart';

class LeaveHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave History'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('From Date', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('To Date', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
          ),
          Expanded(
            child: Consumer<LeaveProvider>(
              builder: (context, provider, child) {
                return ListView.separated(
                  itemCount: provider.leaveHistory.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
                  itemBuilder: (context, index) {
                    final request = provider.leaveHistory[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(request.fromDate, style: const TextStyle(fontSize: 12)),
                          ),
                          Expanded(
                            child: Text(request.toDate, style: const TextStyle(fontSize: 12)),
                          ),
                          Expanded(
                            child: Text(request.type, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _buildStatusBadge(request.status),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (status) {
      case 'Rejected':
        backgroundColor = const Color(0xFFC62828);
        break;
      case 'Approved':
        backgroundColor = Colors.green;
        break;
      case 'Pending':
      default:
        backgroundColor = Colors.transparent;
        textColor = Colors.grey.shade700;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Text(
            status,
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
