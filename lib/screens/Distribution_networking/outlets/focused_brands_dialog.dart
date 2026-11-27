import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import 'outlet_activity_provider.dart';

class FocusedBrandsDialog extends StatefulWidget {
  final VoidCallback? onProceed;
  final String outletName;
  final int? outletId;
  final bool isAlreadyCheckedIn;

  const FocusedBrandsDialog({
    super.key,
    this.onProceed,
    this.outletName = "",
    this.outletId,
    this.isAlreadyCheckedIn = false,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onProceed,
    String outletName = "",
    int? outletId,
    bool isAlreadyCheckedIn = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => FocusedBrandsDialog(
        onProceed: onProceed,
        outletName: outletName,
        outletId: outletId,
        isAlreadyCheckedIn: isAlreadyCheckedIn,
      ),
    );
  }

  @override
  State<FocusedBrandsDialog> createState() => _FocusedBrandsDialogState();
}

class _FocusedBrandsDialogState extends State<FocusedBrandsDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.outletId != null && mounted) {
        final prov = Provider.of<OutletActivityProvider>(context, listen: false);
        final currentOutletData = prov.outletFocusedData;
        final currentOutletId = currentOutletData?['outlet']?['outlet_id'];
        if (currentOutletData == null || currentOutletId?.toString() != widget.outletId.toString()) {
          prov.fetchOutletFocusedProducts(widget.outletId!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
          maxWidth: 440,
        ),
        child: Consumer<OutletActivityProvider>(
          builder: (context, provider, _) {
            final focusedData = provider.outletFocusedData;
            final products = provider.focusedProducts;
            final summary = focusedData?['summary'] as Map<String, dynamic>?;
            final apiOutlet = focusedData?['outlet'] as Map<String, dynamic>?;
            final dateStr = focusedData?['date']?.toString() ?? '';

            final effectiveOutletName = (apiOutlet?['outlet_name']?.toString().isNotEmpty ?? false)
                ? apiOutlet!['outlet_name'].toString()
                : widget.outletName;

            final num percentNum = (summary != null && summary['percent'] != null)
                ? (num.tryParse(summary['percent'].toString()) ?? 0)
                : 0;
            final double progressFraction = (percentNum / 100.0).clamp(0.0, 1.0);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Emerald Header
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0F5132),
                        Color(0xFF198754),
                        Color(0xFF20C997),
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
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.stars_rounded, color: Colors.amber, size: 15),
                                SizedBox(width: 5),
                                Text(
                                  "PRIORITY TARGETS",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.5,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "FOCUSED BRANDS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        effectiveOutletName.isNotEmpty
                            ? effectiveOutletName
                            : "Priority products for order booking",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 11, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                "Date: $dateStr",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Target Summary Box (if summary available)
                if (summary != null)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FCF9),
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryMetric("TARGET", summary['target']?.toString() ?? "0", const Color(0xFF1E293B)),
                            Container(width: 1, height: 26, color: Colors.grey.shade300),
                            _buildSummaryMetric("ACHIEVED", summary['achieved']?.toString() ?? "0", const Color(0xFF15803D)),
                            Container(width: 1, height: 26, color: Colors.grey.shade300),
                            _buildSummaryMetric("COMPLETION", "${summary['percent'] ?? 0}%", const Color(0xFFD97706)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressFraction,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF15803D)),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Content Area
                Flexible(
                  child: provider.isLoadingFocusedProducts
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(36),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Color(0xFF15803D)),
                                SizedBox(height: 14),
                                Text(
                                  "Fetching focused products...",
                                  style: TextStyle(fontSize: 12.5, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : products.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 44, color: Colors.grey.shade400),
                                    const SizedBox(height: 10),
                                    const Text(
                                      "No Focused Products",
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "No priority product targets are assigned for this outlet.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              itemCount: products.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final product = products[index] as Map<String, dynamic>;
                                return _buildProductCard(product);
                              },
                            ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final productName = product['product_name']?.toString() ?? 'Product';
    final target = product['target']?.toString() ?? '0';
    final achieved = product['achieved']?.toString() ?? '0';
    final percent = product['percent']?.toString() ?? '0';
    final skus = product['skus'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Title Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(bottom: BorderSide(color: Colors.green.shade100, width: 0.8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF15803D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14532D),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15803D),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Target: $target",
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Achieved & Percentage Summary
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF15803D)),
                    const SizedBox(width: 4),
                    Text(
                      "Achieved: $achieved",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    "$percent% Complete",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // SKUs List
          if (skus.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SKUs & Validity:",
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 3),
                  ...skus.map((skuItem) {
                    final sku = skuItem as Map<String, dynamic>;
                    final skuName = sku['sku_name']?.toString() ?? 'SKU';
                    final fromDate = sku['from_date']?.toString() ?? '';
                    final toDate = sku['to_date']?.toString() ?? '';
                    final skuTarget = sku['target']?.toString() ?? '0';
                    final skuAchieved = sku['achieved']?.toString() ?? '0';

                    return Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  skuName,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                "Target: $skuTarget | Ach: $skuAchieved",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                          if (fromDate.isNotEmpty && toDate.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              "Period: $fromDate to $toDate",
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Standalone full-width banner widget for PosBaseScreen and PobScreen
class FocusedBrandsBannerWidget extends StatelessWidget {
  final VoidCallback onTap;
  final int? count;
  final String? subtitle;

  const FocusedBrandsBannerWidget({
    super.key,
    required this.onTap,
    this.count,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OutletActivityProvider>(
      builder: (context, provider, _) {
        final effectiveCount = count ?? provider.focusedProducts.length;

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
                      child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
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
                                  effectiveCount > 0 ? "$effectiveCount PRODUCTS" : "PRIORITY",
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
                            subtitle ??
                                (effectiveCount > 0
                                    ? "$effectiveCount target products assigned • Tap to view schemes & targets"
                                    : "Focus products to pitch and maximize targets • Tap to view"),
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
      },
    );
  }
}
