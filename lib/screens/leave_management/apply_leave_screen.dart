import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'leave_provider.dart';

class ApplyLeaveScreen extends StatefulWidget {
  @override
  _ApplyLeaveScreenState createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  String? _selectedLeaveType;
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();
  final _emailController = TextEditingController(text: 'priyanka.akasapu@heterohealthcare.com');
  final _reasonController = TextEditingController();
  final _daysApplicableController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with first leave type
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LeaveProvider>(context, listen: false);
      if (provider.leaveBalances.isNotEmpty) {
        setState(() {
          _selectedLeaveType = provider.leaveBalances.first.type;
        });
      }
    });
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    _emailController.dispose();
    _reasonController.dispose();
    _daysApplicableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Leave'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<LeaveProvider>(
          builder: (context, provider, child) {
            LeaveBalance? selectedBalance;
            if (_selectedLeaveType != null) {
              try {
                selectedBalance = provider.leaveBalances.firstWhere(
                  (b) => b.type == _selectedLeaveType,
                );
              } catch (e) {
                // Ignore if not found
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.list),
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedLeaveType,
                  items: provider.leaveBalances.map((balance) {
                    return DropdownMenuItem<String>(
                      value: balance.type,
                      child: Text(balance.type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLeaveType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Leave',
                  style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold),
                ),
                const Divider(thickness: 1, color: Colors.grey),
                if (selectedBalance != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem('Allocated', selectedBalance.allocated.toString()),
                        _buildSummaryItem('Used', selectedBalance.used.toString()),
                        _buildSummaryItem('Remaining', selectedBalance.remaining.toString()),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _fromDateController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today),
                    labelText: 'From Date',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    // Implement date picker
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _toDateController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today),
                    labelText: 'To Date',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    // Implement date picker
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.notes),
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _daysApplicableController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today),
                    labelText: 'Days applicable',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Implement submit logic
                    if (_selectedLeaveType != null) {
                      String typeCode = '';
                      if (_selectedLeaveType == 'CASUAL LEAVE') typeCode = 'CL';
                      else if (_selectedLeaveType == 'SICK LEAVE') typeCode = 'SL';
                      else if (_selectedLeaveType == 'EARNED LEAVE') typeCode = 'EL';
                      
                      provider.addLeaveRequest(
                        LeaveRequest(
                          fromDate: _fromDateController.text.isNotEmpty ? _fromDateController.text : 'Today',
                          toDate: _toDateController.text.isNotEmpty ? _toDateController.text : 'Today',
                          type: typeCode,
                          status: 'Pending',
                          reason: _reasonController.text,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('SUBMIT', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
