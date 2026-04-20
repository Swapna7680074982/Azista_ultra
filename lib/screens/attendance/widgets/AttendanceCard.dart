import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/Attendance model.dart';

class AttendanceCard extends StatelessWidget {
  final Attendance data;

  const AttendanceCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          _row("Started At", _format(data.start)),
          const SizedBox(height: 6),
          _row("Ended At", _format(data.end)),
          const SizedBox(height: 4),

          if (data.hasRequest)
            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onTap: () => showRequestPopup(context, data),
                child: ClipPath(
                  clipper: _RequestClipper(),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 5, 16, 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "REQUEST",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        Text(value),
      ],
    );
  }

  String _format(DateTime dt) {
    return "${dt.day}-${_monthName(dt.month)}-${dt.year} "
        "${_formatTime(dt)}";
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final period = dt.hour >= 12 ? "pm" : "am";
    return "$hour:${dt.minute.toString().padLeft(2, '0')} $period";
  }

  String _monthName(int m) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[m - 1];
  }
}

String _formatDate(DateTime dt) {
  const months = [
    "Jan","Feb","Mar","Apr","May","Jun",
    "Jul","Aug","Sep","Oct","Nov","Dec"
  ];

  return "${dt.day}-${months[dt.month - 1]}-${dt.year}";
}

class _RequestClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.moveTo(12, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(12, size.height);
    path.lineTo(0, size.height / 2);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

void showRequestPopup(BuildContext context, Attendance data) {
  final dateController =
  TextEditingController(text: _formatDate(data.start));
  final messageController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 10,
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  const Center(
                    child: Text(
                      "Send Request",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text("Request Date",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),

                  Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration:
                      const InputDecoration(border: InputBorder.none),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text("Request Message",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Request Message",
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.bottomRight,
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("SEND REQUEST",style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),

              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 28,
                    width: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}