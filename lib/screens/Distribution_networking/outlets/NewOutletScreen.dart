import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';

import '../../../constants/app_colors.dart';
import '../../../services/api_services.dart';
import '../../../services/location_service.dart';
import 'package:provider/provider.dart';
import '../../../permissions/AppStateProvider.dart';
import '../../../permissions/SessionManager.dart';
import 'outlet_provider.dart';
import '../../../utilities/common_widgets.dart';

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
  OutletCategory? selectedCategory;
  String gender = "";
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
    Future.microtask(() {
      if (mounted) {
        context.read<OutletProvider>().fetchCategories();
      }
    });
  }

  bool _isFetchingAddress = false;

  Future<void> _autoFetchAddress(double lat, double lng) async {
    if (_isFetchingAddress) return;
    setState(() => _isFetchingAddress = true);
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      final url = "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng";
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            "User-Agent": "AzistaUltraApp/1.0",
          },
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        final displayName = response.data["display_name"]?.toString();
        if (displayName != null) {
          setState(() {
            addressController.text = displayName;
          });
        }
      }
    } catch (e) {
      debugPrint("Address fetch error: $e");
    } finally {
      setState(() => _isFetchingAddress = false);
    }
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
        _autoFetchAddress(lat, lng);
      }
    } catch (e) {
      print("Location error: $e");
    }
  }
  Future<void> submitOutlet() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Outlet Name is mandatory")),
      );
      return;
    }

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an Outlet Category")),
      );
      return;
    }

    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone Number is mandatory")),
      );
      return;
    }

    if (contactController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact Person Name is mandatory")),
      );
      return;
    }

    if (phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid phone number")),
      );
      return;
    }

    if (whatsappController.text.isNotEmpty && whatsappController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("WhatsApp number must be exactly 10 digits")),
      );
      return;
    }

    if (altMobileController.text.isNotEmpty && altMobileController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alternative mobile number must be exactly 10 digits")),
      );
      return;
    }

    double lat = currentPosition.latitude;
    double lng = currentPosition.longitude;

    if (marker != null) {
      lat = marker!.position.latitude;
      lng = marker!.position.longitude;

      try {
        final coords = await LocationService.getCoordinates();
        final currentLat = double.parse(coords[0]);
        final currentLng = double.parse(coords[1]);

        final distance = Geolocator.distanceBetween(
          currentLat,
          currentLng,
          lat,
          lng,
        );

        if (distance > 50) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Selected location is ${distance.toStringAsFixed(0)}m away. You must be within 50 meters to register an outlet.")),
          );
          return;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to verify location. Please check GPS and try again.")),
        );
        return;
      }
    } else {
      // Default to current GPS coordinates if available, otherwise fallback to currentPosition
      try {
        final coords = await LocationService.getCoordinates();
        lat = double.parse(coords[0]);
        lng = double.parse(coords[1]);
      } catch (_) {
        lat = currentPosition.latitude;
        lng = currentPosition.longitude;
      }
    }

    if (isSubmitting) return;

    setState(() => isSubmitting = true);

    int distId = widget.routeId;
    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      if (appState.selectedDistributorId != null) {
        distId = appState.selectedDistributorId!;
      } else {
        final dists = await SessionManager.getDistributors();
        if (dists.isNotEmpty) {
          distId = int.tryParse(dists.first["distributor_id"]?.toString() ?? '') ?? widget.routeId;
        }
      }
    } catch (_) {}

    final payload = {
      "route_id": widget.routeId,
      "distributor_id": distId,
      "beat_id": widget.routeId,
      "outlet_category": int.tryParse(selectedCategory!.categoryId) ?? 0,
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
      "latitude": lat,
      "longitude": lng,
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
      SuccessDialog.show(context, message: message, onDismiss: () {
        Navigator.pop(context, true);
      });
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
      appBar: AppBar(
        title: const Text(
          "REGISTRATION",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                      Text(widget.routeName.toUpperCase()),
                      const SizedBox.shrink(),
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
                ? const Center(child: LogoProgressIndicator())
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
                _autoFetchAddress(latLng.latitude, latLng.longitude);
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

                  _categorySelectField(context.watch<OutletProvider>()),

                  _textField(nameController, "Outlet Name", Icons.store, isRequired: true),
                  _textField(contactController, "Contact Person", Icons.person, isRequired: true),
                  _textField(phoneController, "Phone", Icons.phone, isRequired: true),

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
                          activeColor: AppColors.button,
                          title: const Text("Male"),
                          onChanged: (v) => setState(() => gender = v!),
                        ),

                        RadioListTile<String>(
                          value: "Female",
                          groupValue: gender,
                          activeColor: AppColors.button,
                          title: const Text("Female"),
                          onChanged: (v) => setState(() => gender = v!),
                        ),

                        RadioListTile<String>(
                          value: "other",
                          groupValue: gender,
                          activeColor: AppColors.button,
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
                color: AppColors.button,
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
  Widget _textField(
      TextEditingController controller,
      String hint,
      IconData icon, {
      bool isRequired = false,
      }) {
    bool isNumberField =
        hint.toLowerCase().contains("phone") ||
            hint.toLowerCase().contains("mobile") ||
            hint.toLowerCase().contains("whatsapp") ;

    return _buildField(
      child: TextField(
        controller: controller,

        keyboardType:
        isNumberField
            ? TextInputType.number
            : TextInputType.text,

        inputFormatters:
        isNumberField
            ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]
            : null,

        decoration: InputDecoration(
          hintText: isRequired ? "$hint *" : hint,
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

  void _showCategoryPicker(BuildContext context, OutletProvider provider) {
    String searchKeyword = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredCategories = provider.categories.where((cat) {
              return cat.categoryName.toLowerCase().contains(searchKeyword.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "SELECT OUTLET CATEGORY",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (value) {
                      setModalState(() {
                        searchKeyword = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "SEARCH CATEGORY...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: provider.isCategoriesLoading
                        ? const Center(child: LogoProgressIndicator())
                        : filteredCategories.isEmpty
                            ? const Center(child: Text("No categories found"))
                            : GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: filteredCategories.length,
                                itemBuilder: (context, index) {
                                  final category = filteredCategories[index];
                                  final isSelected = selectedCategory?.categoryId == category.categoryId;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedCategory = category;
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.button.withValues(alpha:0.1) : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected ? AppColors.button : Colors.grey.shade300,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.03),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Expanded(
                                                  child: Image.network(
                                                    category.categoryImage,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Icon(
                                                        Icons.storefront,
                                                        size: 28,
                                                        color: Colors.grey,
                                                      );
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  category.categoryName,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            const Positioned(
                                              top: 4,
                                              right: 4,
                                              child: CircleAvatar(
                                                radius: 8,
                                                backgroundColor: AppColors.button,
                                                child: Icon(
                                                  Icons.check,
                                                  size: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _categorySelectField(OutletProvider provider) {
    return _buildField(
      child: InkWell(
        onTap: () => _showCategoryPicker(context, provider),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.list, color: Colors.grey),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 15,
                      color: selectedCategory != null ? Colors.black : Colors.grey.shade600,
                    ),
                    children: [
                      TextSpan(
                        text: selectedCategory != null
                            ? selectedCategory!.categoryName
                            : "Select Outlet Category",
                      ),
                      if (selectedCategory == null)
                        const TextSpan(
                          text: " *",
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ),
              if (selectedCategory != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    selectedCategory!.categoryImage,
                    width: 28,
                    height: 28,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}