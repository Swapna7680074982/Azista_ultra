import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class FocusedBrandItem {
  final String name;
  final String category;
  final String description;
  final String target;
  final String scheme;
  final String margin;
  final String badge;
  final IconData icon;

  const FocusedBrandItem({
    required this.name,
    required this.category,
    required this.description,
    required this.target,
    required this.scheme,
    required this.margin,
    required this.badge,
    this.icon = Icons.stars,
  });

  factory FocusedBrandItem.fromJson(Map<String, dynamic> json) {
    return FocusedBrandItem(
      name: json['name'] ?? json['product_name'] ?? json['brand_name'] ?? '',
      category: json['category'] ?? json['division'] ?? 'Pharma',
      description: json['description'] ?? json['composition'] ?? '',
      target: json['target'] ?? json['focus_target'] ?? 'Focus Brand',
      scheme: json['scheme'] ?? json['offer'] ?? 'Active Scheme',
      margin: json['margin'] ?? '15% Margin',
      badge: json['badge'] ?? 'TOP PRIORITY',
    );
  }
}

class FocusedBrandsData {
  static const List<FocusedBrandItem> defaultBrands = [
    FocusedBrandItem(
      name: "DASUTRA TABLETS",
      category: "Men's Health / Ultra",
      description: "Fast-acting Sildenafil 100mg / 50mg Tablets",
      target: "Minimum 5+ boxes per outlet visit",
      scheme: "Buy 10 boxes, Get 2 Free (Active)",
      margin: "18% Retailer Margin",
      badge: "⭐ TOP PRIORITY",
      icon: Icons.local_fire_department,
    ),
    FocusedBrandItem(
      name: "AZIFINE 500",
      category: "Anti-Infective / Antibiotic",
      description: "Azithromycin 500mg Tablets (3s / 5s pack)",
      target: "Target 3+ boxes per outlet",
      scheme: "Special Scheme: Buy 20 Get 3 Free",
      margin: "15% Retailer Margin",
      badge: "🎯 HIGH FOCUS",
      icon: Icons.medical_services,
    ),
    FocusedBrandItem(
      name: "PANTOVISTA DSR",
      category: "Gastroenterology",
      description: "Pantoprazole & Domperidone Sustained Release",
      target: "Target 5+ strips per booking",
      scheme: "Seasonal Discount: 10% Extra Off",
      margin: "16% Retailer Margin",
      badge: "🔥 SEASONAL FOCUS",
      icon: Icons.medication_liquid,
    ),
    FocusedBrandItem(
      name: "CALCIVISTA XT",
      category: "Nutritional / Supplements",
      description: "Calcium Citrate, Vitamin D3 & Zinc Tablets",
      target: "Target 4+ bottles/boxes",
      scheme: "Introductory Offer: Buy 5 Get 1 Free",
      margin: "20% Retailer Margin",
      badge: "✨ NEW FOCUS",
      icon: Icons.health_and_safety,
    ),
  ];
}

class FocusedBrandsDialog extends StatelessWidget {
  final VoidCallback? onProceed;
  final String outletName;
  final bool isAlreadyCheckedIn;

  const FocusedBrandsDialog({
    super.key,
    this.onProceed,
    this.outletName = "",
    this.isAlreadyCheckedIn = false,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onProceed,
    String outletName = "",
    bool isAlreadyCheckedIn = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => FocusedBrandsDialog(
        onProceed: onProceed,
        outletName: outletName,
        isAlreadyCheckedIn: isAlreadyCheckedIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brands = FocusedBrandsData.defaultBrands;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
          maxWidth: 480,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Green Banner Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1B5E20), // Dark Green
                    Color(0xFF2E7D32), // Green
                    Color(0xFF388E3C), // Medium Green
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars, color: Colors.amber, size: 16),
                            SizedBox(width: 6),
                            Text(
                              "PRIORITY FOCUS",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "FOCUSED BRANDS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    outletName.isNotEmpty
                        ? "Pitch & book these priority products for $outletName today!"
                        : "Focus products to pitch and maximize order booking today!",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Tip Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFE8F5E9),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Earn extra incentive & fulfill target by booking focus brands.",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable List of Focused Brands
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(14),
                itemCount: brands.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final brand = brands[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(brand.icon, color: const Color(0xFF2E7D32), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          brand.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1B5E20),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.green.shade300),
                                        ),
                                        child: Text(
                                          brand.badge,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    brand.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(height: 1, thickness: 0.6, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      brand.scheme,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Text(
                                brand.margin,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.track_changes, size: 13, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(
                              brand.target,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.blueGrey.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "DISMISS",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        if (onProceed != null) {
                          onProceed!();
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isAlreadyCheckedIn ? Icons.shopping_bag : Icons.login,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAlreadyCheckedIn ? "PROCEED TO POB" : "PROCEED TO CHECK-IN",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standalone full-width banner widget for PosBaseScreen and PobScreen
class FocusedBrandsBannerWidget extends StatelessWidget {
  final VoidCallback onTap;
  final int count;

  const FocusedBrandsBannerWidget({
    super.key,
    required this.onTap,
    this.count = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE8F5E9),
            Color(0xFFC8E6C9),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF81C784), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stars, color: Colors.amber, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "FOCUSED BRANDS ACTIVE",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "$count BRANDS",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Dasutra Tablets & other priority items • Tap to view schemes",
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.green.shade900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios, size: 13, color: Color(0xFF2E7D32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
