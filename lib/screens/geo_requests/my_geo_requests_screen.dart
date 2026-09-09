import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/api_services.dart';
import '../../utilities/wavy_app_bar.dart';
import '../../utilities/common_widgets.dart';
import '../../utilities/date_formatter.dart';

class MyGeoRequestsScreen extends StatefulWidget {
  final int? outletId;
  final String? initialStatus;

  const MyGeoRequestsScreen({
    super.key,
    this.outletId,
    this.initialStatus,
  });

  @override
  State<MyGeoRequestsScreen> createState() => _MyGeoRequestsScreenState();
}

class _MyGeoRequestsScreenState extends State<MyGeoRequestsScreen> {
  String _selectedStatus = "all";
  bool _isLoading = false;
  List<Map<String, dynamic>> _requests = [];
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusFilters = ["all", "pending", "approved", "rejected"];

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
      final res = await ApiServices.getMyOutletGeoRequests(
        outletId: widget.outletId,
        status: _selectedStatus == "all" ? null : _selectedStatus,
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
          SnackBar(content: Text("Error fetching requests: $e")),
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
      return name.contains(q) || id.contains(q) || outletId.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WavyAppBar(
        title: "MY GEO REQUESTS",
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
                              return _buildRequestCard(_filteredRequests[index]);
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusFilters.map((st) {
            final isSelected = _selectedStatus == st;
            final label = st.toUpperCase();
            Color activeColor;
            if (st == "approved") {
              activeColor = Colors.green.shade700;
            } else if (st == "rejected") {
              activeColor = Colors.red.shade700;
            } else if (st == "pending") {
              activeColor = Colors.orange.shade800;
            } else {
              activeColor = AppColors.primary;
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87,
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
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search by outlet name or request ID...",
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
              Icon(Icons.location_off_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "No Geo Requests Found",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedStatus == "all"
                    ? "You have not submitted any geo update requests yet."
                    : "No requests found with status: ${_selectedStatus.toUpperCase()}",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final status = (req["status"] ?? "pending").toString().toLowerCase();
    final requestId = req["request_id"]?.toString() ?? "-";
    final outletName = req["outlet_name"]?.toString() ?? "Outlet #${req["outlet_id"] ?? ""}";
    final outletId = req["outlet_id"]?.toString() ?? "-";
    final createdAt = req["created_at"]?.toString() ?? "";
    final prevLat = req["previous_latitude"]?.toString();
    final prevLng = req["previous_longitude"]?.toString();
    final reqLat = req["requested_latitude"]?.toString();
    final reqLng = req["requested_longitude"]?.toString();
    final distanceKm = req["computed_distance_km"] ?? req["distance_km"];
    final remarks = req["remarks"]?.toString();
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
      margin: const EdgeInsets.only(bottom: 10),
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
                        "Outlet ID: $outletId  •  Req #$requestId",
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

            // Coordinates Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "REQUESTED LOCATION",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.my_location, size: 14, color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "$reqLat, $reqLng",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (distanceKm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      "$distanceKm km diff",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ),
              ],
            ),

            if (prevLat != null && prevLng != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text(
                    "PREVIOUS: ",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  Text(
                    "$prevLat, $prevLng",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),

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
                      "Manager Remarks:",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      remarks,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    if (reviewedAt != null && reviewedAt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Reviewed: ${DateFormatter.formatDateTime(reviewedAt)}",
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
