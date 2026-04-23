import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../Distribution_networking/outlets/PosBaseScreen.dart';
import '../Distribution_networking/outlets/outlet_provider.dart';

class NearMeScreen extends StatelessWidget {
  const NearMeScreen({super.key});

  Widget outletCard(Outlet outlet, BuildContext context) {
    return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PosBaseScreen(outlet: outlet),
            ),
          );
        },
    child :Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4)
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(outlet.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              
              const SizedBox(height: 4),
              Text("OUTLET ID: ${outlet.id}", style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),

              const Divider(height: 24),

              Row(
                children: [
                  Icon(Icons.person, size: 18, color: Colors.grey.shade500),
                  const SizedBox(width: 12),
                  Text(outlet.owner, style: TextStyle(color: Colors.grey.shade800)),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.grey.shade500),
                  const SizedBox(width: 12),
                  Text(outlet.phone, style: TextStyle(color: Colors.grey.shade800)), // Image shows phone number next to location pin
                ],
              ),
              
              const SizedBox(height: 10),
              
              Row(
                children: [
                  const Icon(Icons.storefront, size: 18, color: Colors.teal),
                  const SizedBox(width: 12),
                  const Text("OUTLET IMAGE", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w500)),
                ],
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      outlet.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 5),

                    Icon(
                      Icons.domain,
                      size: 18,
                      color: Colors.blueGrey.shade700,
                    ),
                  ],
                ),
              ),

              const Divider(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.teal),
                        borderRadius: BorderRadius.circular(20), // rounded borders like in image
                        color: Colors.white,
                      ),
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          "CALL",
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(20), // rounded borders like in image
                        color: Colors.white,
                      ),
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          "DIRECTIONS",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (outlet.name.toUpperCase() == "TESTING") // Add Unfreeze button overlay for testing
            Positioned(
              top: 50,
              left: 40,
              right: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFFC62828), // Dark red
                alignment: Alignment.center,
                child: const Text(
                  "UNFREEZE OUTLET",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    )
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OutletProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // light background
      appBar: AppBar(
        title: const Text(
          "Near Me",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFFC62828),
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) {
                context.read<OutletProvider>().updateSearch(value);
              },
              decoration: const InputDecoration(
                hintText: "Search by Outlet,Owner or Phone",
                hintStyle: TextStyle(color: Colors.black54),
                suffixIcon: Icon(Icons.search, color: Color(0xFFC62828)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Container(height: 1, color: Colors.grey.shade300),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "Outlets of 100 mts around current location",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: provider.outlets.length,
              itemBuilder: (context, index) {
                return outletCard(provider.outlets[index], context);
              },
            ),
          )
        ],
      ),
    );
  }
}
