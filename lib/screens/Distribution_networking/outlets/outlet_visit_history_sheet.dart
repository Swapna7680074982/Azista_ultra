import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/api_services.dart';
import '../../../utilities/common_widgets.dart';
import '../../../utilities/date_formatter.dart';
import 'outlet_provider.dart';

class OutletVisitHistorySheet extends StatefulWidget {
  final int outletId;
  final String outletName;
  final List<VisitHistoryItem>? initialVisits;

  const OutletVisitHistorySheet({
    super.key,
    required this.outletId,
    required this.outletName,
    this.initialVisits,
  });

  static Future<void> show(
    BuildContext context, {
    required int outletId,
    required String outletName,
    List<VisitHistoryItem>? initialVisits,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OutletVisitHistorySheet(
        outletId: outletId,
        outletName: outletName,
        initialVisits: initialVisits,
      ),
    );
  }

  @override
  State<OutletVisitHistorySheet> createState() => _OutletVisitHistorySheetState();
}

class _OutletVisitHistorySheetState extends State<OutletVisitHistorySheet> {
  bool _isLoading = true;
  List<VisitHistoryItem> _visits = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialVisits != null && widget.initialVisits!.isNotEmpty) {
      _visits = List.from(widget.initialVisits!);
      _isLoading = false;
    }
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final res = await ApiServices.getOutletHistory(outletId: widget.outletId);
      if (!mounted) return;

      if (res != null &&
          (res['status'] == true ||
              res['status'] == 1 ||
              res['status'] == '1' ||
              res['status'] == 'success' ||
              res['status_code'] == 200)) {
        final rawVisits = (res['visit_history'] ??
            res['visits'] ??
            res['data']?['visit_history'] ??
            res['data']?['visits'] ??
            (res['data'] is List ? res['data'] : null) ??
            []) as List<dynamic>;

        final parsed = <VisitHistoryItem>[];
        for (var v in rawVisits) {
          if (v is Map) {
            parsed.add(VisitHistoryItem.fromJson(Map<String, dynamic>.from(v)));
          }
        }

        if (parsed.isEmpty && res['outlet_details'] is Map) {
          final details = Map<String, dynamic>.from(res['outlet_details']);
          final lvDate = details['last_visit_date'] ??
              details['last_visited_date'] ??
              details['last_visit'] ??
              details['visit_date'] ??
              details['last_visit_on'] ??
              details['last_visited_on'];
          final lvType = details['last_visit_type'] ?? details['visit_type'] ?? 'INDIVIDUAL';
          if (lvDate != null &&
              lvDate.toString().trim().isNotEmpty &&
              lvDate.toString() != 'null' &&
              lvDate.toString() != 'N/A' &&
              lvDate.toString() != '-') {
            parsed.add(VisitHistoryItem(
              visitId: (details['last_visit_id'] ?? details['visit_id'] ?? '').toString(),
              visitDate: lvDate.toString(),
              visitType: (lvType != null && lvType.toString().isNotEmpty) ? lvType.toString() : 'INDIVIDUAL',
              checkinTime: lvDate.toString(),
            ));
          }
        }

        setState(() {
          if (parsed.isNotEmpty) {
            _visits = parsed;
          }
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        if (_visits.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = res?['message']?.toString() ?? "Failed to load visit history";
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (_visits.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error loading visit history: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.outletName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            "OUTLET ID: ${widget.outletId}",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                          if (!_isLoading) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                "${_visits.length} ${_visits.length == 1 ? 'VISIT' : 'VISITS'}",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.black54),
                  tooltip: "Close",
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Expanded(
            child: _isLoading && _visits.isEmpty
                ? const Center(child: LogoProgressIndicator(size: 60))
                : _errorMessage != null && _visits.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Colors.red),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() => _isLoading = true);
                                  _fetchHistory();
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text("Retry"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _visits.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.pin_drop_outlined, size: 54, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "No Visit History Found",
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "No check-in or visit records are logged for this outlet.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(14),
                            itemCount: _visits.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _visits[index];
                              return _buildVisitCard(item, index);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitCard(VisitHistoryItem item, int index) {
    final isJoint = item.visitType.toUpperCase() == 'JOINT';
    final hasCheckout = item.checkoutTime != null &&
        item.checkoutTime!.isNotEmpty &&
        item.checkoutTime != 'null' &&
        item.checkoutTime != 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row of the visit card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isJoint ? Colors.teal.shade50 : Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isJoint ? Icons.group : Icons.person_pin_circle,
                      size: 16,
                      color: isJoint ? Colors.teal.shade800 : Colors.blue.shade800,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "VISIT #${item.visitId.isNotEmpty ? item.visitId : (index + 1).toString()}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isJoint ? Colors.teal.shade900 : Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isJoint ? Colors.teal.shade700 : Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.visitType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date & Time row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("VISIT DATE", style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            item.visitDate.isNotEmpty ? DateFormatter.formatDate(item.visitDate) : "N/A",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("CHECK-IN TIME", style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            item.checkinTime.isNotEmpty ? DateFormatter.formatDateTime(item.checkinTime) : "N/A",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Checkout & Remarks row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("CHECK-OUT TIME", style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            hasCheckout ? DateFormatter.formatDateTime(item.checkoutTime!) : "Active / Open",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: hasCheckout ? Colors.black87 : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.remarks.isNotEmpty)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("REMARKS", style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              item.remarks,
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Activity history if present
                if (item.activityHistory.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Text(
                    "ACTIVITIES (${item.activityHistory.length})",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: item.activityHistory.map((act) {
                      final actType = (act['activity_type'] ?? act['module_name'] ?? act['type'] ?? 'Activity').toString();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          actType.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
