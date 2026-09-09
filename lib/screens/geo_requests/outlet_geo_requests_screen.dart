import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/api_services.dart';
import '../../utilities/wavy_app_bar.dart';
import '../../utilities/common_widgets.dart';
import '../../utilities/date_formatter.dart';
import 'direct_coordinate_update_screen.dart';

class OutletGeoRequestsScreen extends StatefulWidget {
  final String? initialStatus;

  const OutletGeoRequestsScreen({
    super.key,
    this.initialStatus,
  });

  @override
  State<OutletGeoRequestsScreen> createState() => _OutletGeoRequestsScreenState();
}

class _OutletGeoRequestsScreenState extends State<OutletGeoRequestsScreen> {
  String _selectedStatus = "pending";
  bool _isLoading = false;
  List<Map<String, dynamic>> _requests = [];
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusFilters = ["pending", "approved", "rejected"];

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null && _statusFilters.contains(widget.initialStatus!.toLowerCase())) {
      _selectedStatus = widget.initialStatus!.toLowerCase();
    }
    _fetchRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiServices.getListOutletGeoRequests(
        status: _selectedStatus,
      );

      if (mounted) {
        if (res != null && res["data"] is List) {
          final list = List<Map<String, dynamic>>.from(res["data"].map((e) => Map<String, dynamic>.from(e)));
          setState(() {
            _requests = list;
          });
        } else {
          setState(() {
            _requests = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading requests: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_searchQuery.trim().isEmpty) return _requests;
    final q = _searchQuery.trim().toLowerCase();
    return _requests.where((r) {
      final name = (r["outlet_name"] ?? "").toString().toLowerCase();
      final id = (r["request_id"] ?? "").toString().toLowerCase();
      final outletId = (r["outlet_id"] ?? "").toString().toLowerCase();
      final distributorId = (r["distributor_id"] ?? "").toString().toLowerCase();
      final routeId = (r["route_id"] ?? "").toString().toLowerCase();
      return name.contains(q) || id.contains(q) || outletId.contains(q) || distributorId.contains(q) || routeId.contains(q);
    }).toList();
  }

  void _showReviewDialog(Map<String, dynamic> req, String action) {
    final requestId = int.tryParse(req["request_id"]?.toString() ?? "0") ?? 0;
    final isApprove = action == "approve";
    final outletName = req["outlet_name"]?.toString() ?? "Outlet #${req["outlet_id"]}";
    final remarksController = TextEditingController(
      text: isApprove ? "Location verified, distance within acceptable range" : "",
    );

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    isApprove ? Icons.check_circle : Icons.cancel,
                    color: isApprove ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isApprove ? "Approve Geo Request" : "Reject Geo Request",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Outlet: $outletName",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Request ID: #$requestId  •  Outlet ID: ${req["outlet_id"]}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isApprove ? "Approval Remarks:" : "Rejection Reason / Remarks:",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: remarksController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: isApprove
                          ? "e.g. Location verified, distance within acceptable range"
                          : "e.g. Location does not match actual store location",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isApprove ? Colors.green.shade700 : Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final remarks = remarksController.text.trim();
                          if (remarks.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter remarks")),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          try {
                            final res = await ApiServices.reviewOutletGeoRequest(
                              requestId: requestId,
                              action: action,
                              remarks: remarks,
                            );

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                            if (mounted) {
                              if (res != null && (res["status"] == "success" || res["status_code"] == 200)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res["message"] ?? "Request $action" "d successfully",
                                    ),
                                    backgroundColor: isApprove ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                );
                                _fetchRequests();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res?["message"]?.toString() ?? "Failed to review request"),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (dialogCtx.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isApprove ? "APPROVE" : "REJECT"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WavyAppBar(
        title: "OUTLET GEO REQUESTS",
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt_outlined, color: Colors.white),
            tooltip: "Direct Coordinate Override",
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const DirectCoordinateUpdateScreen(),
                ),
              );
              if (updated == true && mounted) {
                _fetchRequests();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(),

          // Search Field
          _buildSearchBar(),

          // Request List
          Expanded(
            child: _isLoading
                ? const Center(child: LogoProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchRequests,
                    child: _filteredRequests.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                            itemCount: _filteredRequests.length,
                            itemBuilder: (context, index) {
                              return _buildManagerRequestCard(_filteredRequests[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey.shade50,
      child: Row(
        children: _statusFilters.map((st) {
          final isSelected = _selectedStatus == st;
          final label = st.toUpperCase();
          Color activeColor;
          if (st == "approved") {
            activeColor = Colors.green.shade700;
          } else if (st == "rejected") {
            activeColor = Colors.red.shade700;
          } else {
            activeColor = Colors.orange.shade800;
          }

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                selected: isSelected,
                selectedColor: activeColor,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? activeColor : Colors.grey.shade300,
                  ),
                ),
                showCheckmark: false,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedStatus = st);
                    _fetchRequests();
                  }
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search by outlet, request ID, distributor...",
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
        onChanged: (val) {
          setState(() => _searchQuery = val);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "No ${_selectedStatus.toUpperCase()} Requests",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "There are currently no geo update requests with status '${_selectedStatus.toUpperCase()}'.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagerRequestCard(Map<String, dynamic> req) {
    final status = (req["status"] ?? "pending").toString().toLowerCase();
    final requestId = req["request_id"]?.toString() ?? "-";
    final outletName = req["outlet_name"]?.toString() ?? "Outlet #${req["outlet_id"] ?? ""}";
    final outletId = req["outlet_id"]?.toString() ?? "-";
    final distributorId = req["distributor_id"]?.toString();
    final routeId = req["route_id"]?.toString();
    final requestedBy = req["requested_by"]?.toString() ?? "-";
    final createdAt = req["created_at"]?.toString() ?? "";
    final prevLat = req["previous_latitude"]?.toString();
    final prevLng = req["previous_longitude"]?.toString();
    final reqLat = req["requested_latitude"]?.toString();
    final reqLng = req["requested_longitude"]?.toString();
    final distanceKm = req["computed_distance_km"] ?? req["distance_km"];
    final remarks = req["remarks"]?.toString();
    final reviewedBy = req["reviewed_by"]?.toString();
    final reviewedAt = req["reviewed_at"]?.toString();

    Color statusColor;
    IconData statusIcon;
    if (status == "approved") {
      statusColor = Colors.green.shade700;
      statusIcon = Icons.check_circle_outline;
    } else if (status == "rejected") {
      statusColor = Colors.red.shade700;
      statusIcon = Icons.cancel_outlined;
    } else {
      statusColor = Colors.orange.shade800;
      statusIcon = Icons.hourglass_top_outlined;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Outlet Name + Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        outletName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Req #$requestId  •  Outlet ID: $outletId${distributorId != null ? '  •  Dist: $distributorId' : ''}${routeId != null ? '  •  Route: $routeId' : ''}",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 18, thickness: 1),

            // Coordinates comparison
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "PREVIOUS REGISTERED",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (prevLat != null && prevLng != null) ? "$prevLat, $prevLng" : "Not Set",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "REQUESTED LOCATION",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$reqLat, $reqLng",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Distance Shift badge + SO info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_pin_circle_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      "By SO #$requestedBy",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                if (distanceKm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      "Shift: $distanceKm km",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // Submission Date
            Row(
              children: [
                Icon(Icons.schedule, size: 13, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  "Submitted: ${createdAt.isNotEmpty ? DateFormatter.formatDateTime(createdAt) : "-"}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),

            // Remarks / Review Details if any
            if (remarks != null && remarks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: status == "approved"
                      ? Colors.green.shade50
                      : status == "rejected"
                          ? Colors.red.shade50
                          : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: status == "approved"
                        ? Colors.green.shade200
                        : status == "rejected"
                            ? Colors.red.shade200
                            : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Review Remarks (by #${reviewedBy ?? '-'}):",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                    const SizedBox(height: 2),
                    Text(remarks, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    if (reviewedAt != null && reviewedAt.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text("At: ${DateFormatter.formatDateTime(reviewedAt)}", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                    ],
                  ],
                ),
              ),
            ],

            // Action Buttons for Pending Requests
            if (status == "pending") ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _showReviewDialog(req, "reject"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _showReviewDialog(req, "approve"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
