import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../constants/app_colors.dart';
import '../../../services/api_services.dart';
import '../../../services/location_service.dart';

class NewOutletScreen extends StatefulWidget {
  final int routeId;
  final String routeName;

  const NewOutletScreen({
    super.key,
    required this.routeId,
    required this.routeName,
  });

  @override
  State<NewOutletScreen> createState() => _NewOutletScreenState();
}

class _NewOutletScreenState extends State<NewOutletScreen> {
  GoogleMapController? _mapController;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController landlineController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController footTrafficController = TextEditingController();
  final TextEditingController yearLaunchedController = TextEditingController();

  final TextEditingController altNameController = TextEditingController();
  final TextEditingController altMobileController = TextEditingController();
  final TextEditingController altPositionController = TextEditingController();
  final TextEditingController altEmailController = TextEditingController();
  String selectedType = "Retailer";
  String gender = "Male";
  String vicinityType = "Near";
  String outletShape = "Square";
  String stockPosition = "Shelf Display";
  String isStoreLaunched = "Yes";

  TimeOfDay? openingTime;
  TimeOfDay? closingTime;

  LatLng currentPosition = const LatLng(20.5937, 78.9629);
  Marker? marker;
  bool isLoadingLocation = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }


  Future<void> _loadCurrentLocation() async {
    try {
      final coords = await LocationService.getCoordinates();

      final lat = double.parse(coords[0]);
      final lng = double.parse(coords[1]);

      final pos = LatLng(lat, lng);

      if (mounted) {
        setState(() {
          currentPosition = pos;
          marker = Marker(
            markerId: const MarkerId("current"),
            position: pos,
          );
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(pos, 16),
        );
      }
    } catch (e) {
      print("Location error: $e");
    }
  }
  Future<void> submitOutlet() async {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill required fields")),
      );
      return;
    }

    if (phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid phone number")),
      );
      return;
    }

    if (marker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select location on map")),
      );
      return;
    }

    if (isSubmitting) return;

    setState(() => isSubmitting = true);

    final payload = {
      "route_id": widget.routeId,
      "outlet_type": selectedType,
      "outlet_name": nameController.text.trim(),
      "owner_name": contactController.text.trim(),
      "mobile": phoneController.text.trim(),
      "whatsapp_mobile": whatsappController.text.trim(),
      "date_of_birth": dobController.text,
      "gender": gender,
      "address": addressController.text.trim(),
      "landmark": landmarkController.text.trim(),
      "email": emailController.text.trim(),
      "opening_time": _formatTime(openingTime),
      "closing_time": _formatTime(closingTime),
      "gst": gstController.text.trim(),
      "area": areaController.text.trim(),
      "vicinity_type": vicinityType,
      "outlet_shape": outletShape,
      "stock_position": stockPosition,
      "store_year_launched": yearLaunchedController.text,
      "daily_foot_traffic":
      int.tryParse(footTrafficController.text) ?? 0,
      "latitude": marker!.position.latitude,
      "longitude": marker!.position.longitude,
      "alt_name": altNameController.text.trim(),
      "alt_mobile": altMobileController.text.trim(),
      "alt_position": altPositionController.text.trim(),
      "alt_email": altEmailController.text.trim(),
    };

    final res = await ApiServices.registerOutlet(payload: payload);

    setState(() => isSubmitting = false);

    final message = res?["message"]?.toString() ?? "Registration failed";
    final status = res?["status"] == true;

    if (status) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
  String _formatTime(TimeOfDay? time) {
    if (time == null) return "";
    final hour = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    return "$hour:$min";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "REGISTRATION",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "ROUTE",
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.routeName),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 200,
            child: isLoadingLocation
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentPosition,
                zoom: 14,
              ),
              markers: marker != null ? {marker!} : {},
              myLocationEnabled: true,
              onTap: (latLng) {
                setState(() {
                  marker = Marker(
                    markerId: const MarkerId("selected"),
                    position: latLng,
                  );
                });
              },
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.yellow.shade100,
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Registration has to be done only at the Outlet Location.",
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [

                  _dropdownField(
                      value: selectedType,
                      list: ["Outlet Types", "Retailer", "Pharmacy"],
                      icon: Icons.list,
                      onChanged: (v) => setState(() => selectedType = v)),

                  _textField(nameController, "Outlet Name", Icons.store),
                  _textField(contactController, "Contact Person", Icons.person),
                  _textField(phoneController, "Phone", Icons.phone),

                  _textField(whatsappController, "WhatsApp Number", Icons.chat),
                  _buildField(
                    child: TextField(
                      controller: dobController,
                      readOnly: true,
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          dobController.text =
                          picked.toString().split(" ")[0];
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: "Date of Birth",
                        prefixIcon: Icon(Icons.calendar_today),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        const Center(
                          child: Text(
                            "SELECT GENDER",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        RadioListTile<String>(
                          value: "Male",
                          groupValue: gender,
                          activeColor: Colors.green,
                          title: const Text("Male"),
                          onChanged: (v) => setState(() => gender = v!),
                        ),

                        RadioListTile<String>(
                          value: "Female",
                          groupValue: gender,
                          activeColor: Colors.green,
                          title: const Text("Female"),
                          onChanged: (v) => setState(() => gender = v!),
                        ),

                        RadioListTile<String>(
                          value: "other",
                          groupValue: gender,
                          activeColor: Colors.green,
                          title: const Text("other"),
                          onChanged: (v) => setState(() => gender = v!),
                        ),
                      ],
                    ),
                  ),
                  _textField(addressController, "Address", Icons.location_on),
                  _textField(landmarkController, "Landmark", Icons.place),
                  _textField(landlineController, "Landline", Icons.phone),
                  _textField(emailController, "Email", Icons.email),
                  _timeField("Opening Time", true),
                  _timeField("Closing Time", false),

                  _textField(gstController, "GST", Icons.receipt),
                  _textField(areaController, "Area (sq ft)", Icons.square_foot),

                  _dropdownField(
                      value: vicinityType,
                      list: ["vicinity Type", "ON", "Near","Far"],
                      icon: Icons.map,
                      onChanged: (v) => setState(() => vicinityType = v)),

                  _dropdownField(
                      value: outletShape,
                      list: ["Outlet Shape", "Square", "Rectangle"],
                      icon: Icons.crop_square,
                      onChanged: (v) => setState(() => outletShape = v)),

                  _dropdownField(
                      value: stockPosition,
                      list: ["Stock Position", "Shelf Display", "Store room", "Both"],
                      icon: Icons.inventory,
                      onChanged: (v) => setState(() => stockPosition = v)),

                  _buildField(
                    child: TextField(
                      controller: yearLaunchedController,
                      readOnly: true,
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                          initialDatePickerMode: DatePickerMode.year,
                        );

                        if (picked != null) {
                          yearLaunchedController.text = picked.year.toString();
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: "Year Store Launched",
                        prefixIcon: Icon(Icons.calendar_today),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  _textField(
                      footTrafficController, "Average daily foot traffic", Icons.people),

                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text("ALTERNATIVE CONTACT DETAILS",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),

                  _textField(altNameController, "Name", Icons.person),
                  _textField(altMobileController, "Mobile", Icons.phone),
                  _textField(altPositionController, "Position", Icons.work),
                  _textField(altEmailController, "Email", Icons.email),

                  const SizedBox(height: 80),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: submitOutlet,
              child: Container(
                height: 50,
                color: Colors.green,
                child: const Center(
                  child: Text("CONFIRM",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    ));
  }
  Widget _textField(controller, hint, icon) {
    return _buildField(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _dropdownField(
      {required String value,
        required List<String> list,
        required IconData icon,
        required Function(String) onChanged}) {
    return _buildField(
      child: DropdownButtonFormField(
        value: value,
        items: list
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => onChanged(v.toString()),
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _timeField(String title, bool isOpening) {
    return _buildField(
      child: ListTile(
        leading: const Icon(Icons.access_time),
        title: Text(isOpening
            ? (openingTime?.format(context) ?? title)
            : (closingTime?.format(context) ?? title)),
        onTap: () async {
          TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (picked != null) {
            setState(() {
              if (isOpening) {
                openingTime = picked;
              } else {
                closingTime = picked;
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildField({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}