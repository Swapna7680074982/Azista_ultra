import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/api_services.dart';
import '../../utilities/wavy_app_bar.dart';

class DirectCoordinateUpdateScreen extends StatefulWidget {
  final int? initialOutletId;
  final String? initialOutletName;
  final double? initialLat;
  final double? initialLng;

  const DirectCoordinateUpdateScreen({
    super.key,
    this.initialOutletId,
    this.initialOutletName,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<DirectCoordinateUpdateScreen> createState() => _DirectCoordinateUpdateScreenState();
}

class _DirectCoordinateUpdateScreenState extends State<DirectCoordinateUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _outletIdController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _isPreviewLoading = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _previewData;

  @override
  void initState() {
    super.initState();
    if (widget.initialOutletId != null) {
      _outletIdController.text = widget.initialOutletId.toString();
    }
    if (widget.initialLat != null) {
      _latController.text = widget.initialLat.toString();
    }
    if (widget.initialLng != null) {
      _lngController.text = widget.initialLng.toString();
    }
  }

  @override
  void dispose() {
    _outletIdController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _previewCoordinates() async {
    if (!_formKey.currentState!.validate()) return;

    final outletId = int.tryParse(_outletIdController.text.trim());
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (outletId == null || lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid Outlet ID and coordinates")),
      );
      return;
    }

    setState(() {
      _isPreviewLoading = true;
      _previewData = null;
    });

    try {
      final res = await ApiServices.previewOutletCoordinates(
        outletId: outletId,
        latitude: lat,
        longitude: lng,
      );

      if (mounted) {
        if (res != null && (res["status"] == "success" || res["status_code"] == 200) && res["data"] != null) {
          setState(() {
            _previewData = Map<String, dynamic>.from(res["data"]);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Coordinate preview loaded successfully")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res?["message"]?.toString() ?? "Failed to preview coordinates")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Preview error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isPreviewLoading = false);
    }
  }

  Future<void> _submitDirectUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final outletId = int.tryParse(_outletIdController.text.trim());
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final remarks = _remarksController.text.trim();

    if (outletId == null || lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid Outlet ID and coordinates")),
      );
      return;
    }

    if (remarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter remarks explaining this update")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final res = await ApiServices.updateOutletCoordinatesDirect(
        outletId: outletId,
        latitude: lat,
        longitude: lng,
        remarks: remarks,
      );

      if (mounted) {
        if (res != null && (res["status"] == "success" || res["status_code"] == 200)) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  const Text("Coordinates Updated"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(res["message"] ?? "Outlet coordinates updated successfully."),
                  const SizedBox(height: 12),
                  if (res["distance_km"] != null)
                    Text("Distance Shift: ${res["distance_km"]} km", style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (res["request_id"] != null)
                    Text("Record ID: #${res["request_id"]}", style: const TextStyle(color: Colors.grey)),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  child: const Text("DONE"),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res?["message"]?.toString() ?? "Failed to update coordinates")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WavyAppBar(
        title: "DIRECT COORDINATE UPDATE",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Directly override coordinates for an outlet. Use Preview to verify distance change before saving.",
                        style: TextStyle(fontSize: 12, height: 1.4, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Outlet ID Input
              const Text(
                "OUTLET ID",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _outletIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Enter Outlet ID (e.g. 1)",
                  prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Please enter Outlet ID";
                  if (int.tryParse(val.trim()) == null) return "Invalid Outlet ID";
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Latitude & Longitude Inputs
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "LATITUDE",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: InputDecoration(
                            hintText: "e.g. 17.42980000",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return "Required";
                            if (double.tryParse(val.trim()) == null) return "Invalid";
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "LONGITUDE",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: InputDecoration(
                            hintText: "e.g. 78.45210000",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return "Required";
                            if (double.tryParse(val.trim()) == null) return "Invalid";
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Remarks Input
              const Text(
                "REMARKS / REASON",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _remarksController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "e.g. Verified on-site, correcting outdated pin",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Please enter remarks for this update";
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Preview Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isPreviewLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.preview_outlined, size: 20),
                  label: const Text(
                    "PREVIEW COORDINATES",
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  onPressed: _isPreviewLoading ? null : _previewCoordinates,
                ),
              ),

              // Preview Results Card
              if (_previewData != null) ...[
                const SizedBox(height: 20),
                _buildPreviewCard(_previewData!),
              ],

              const SizedBox(height: 24),

              // Submit Direct Update Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined, size: 20),
                  label: const Text(
                    "UPDATE COORDINATES DIRECT",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                  ),
                  onPressed: _isSubmitting ? null : _submitDirectUpdate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(Map<String, dynamic> preview) {
    final outletName = preview["outlet_name"]?.toString() ?? "Outlet #${preview["outlet_id"]}";
    final prevLat = preview["previous_latitude"]?.toString() ?? "-";
    final prevLng = preview["previous_longitude"]?.toString() ?? "-";
    final newLat = preview["new_latitude"]?.toString() ?? "-";
    final newLng = preview["new_longitude"]?.toString() ?? "-";
    final distanceKm = preview["distance_km"]?.toString() ?? "-";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green.shade800, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "PREVIEW: $outletName".toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16, thickness: 1),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PREVIOUS COORDINATES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text("$prevLat, $prevLng", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("NEW COORDINATES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text("$newLat, $newLng", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.straighten, size: 16, color: Colors.black87),
                const SizedBox(width: 6),
                Text(
                  "Calculated Distance Shift: $distanceKm km",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
