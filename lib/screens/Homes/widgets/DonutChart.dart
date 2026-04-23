import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import 'dart:math';

import 'dart:math';
import 'package:flutter/material.dart';

class DonutChart extends StatefulWidget {
  final double value;
  final double total;
  final String label;
  final Color color;

  const DonutChart({
    super.key,
    required this.value,
    required this.total,
    required this.label,
    required this.color,
  });

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 190,
          height: 190,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final sweepLength = widget.total == 0 
                  ? 0.0 
                  : (widget.value / widget.total) * 2 * pi * _controller.value;

              final greenMidAngle = -pi / 2 + sweepLength / 2;
              final gDx = 65 * cos(greenMidAngle);
              final gDy = 65 * sin(greenMidAngle);
              final redMidAngle = pi / 2 + sweepLength / 2;
              final rDx = 65 * cos(redMidAngle);
              final rDy = 65 * sin(redMidAngle);

              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 170),
                    painter: DonutPainter(
                      progress: _controller.value,
                      value: widget.value,
                      total: widget.total,
                      color: widget.color,
                    ),
                  ),

                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),

                  Positioned.fromRect(
                    rect: Rect.fromCenter(
                      center: Offset(95 + gDx, 95 + gDy), 
                      width: 100, 
                      height: 50
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                         children: [
                          Text(
                            widget.value.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            "Achieved",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned.fromRect(
                    rect: Rect.fromCenter(
                      center: Offset(95 + rDx, 95 + rDy), 
                      width: 100, 
                      height: 50
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.total.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Target ${widget.label.split(" ").last}",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 10),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 10, height: 10, color: Colors.green),
                const SizedBox(width: 6),
                Text("Total ${widget.label.split(" ").last}"),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 10, height: 10, color: Colors.red),
                const SizedBox(width: 6),
                Text("Target ${widget.label.split(" ").last}"),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class DonutPainter extends CustomPainter {
  final double progress;
  final double value;
  final double total;
  final Color color;

  DonutPainter({
    required this.progress,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const stroke = 40.0;
    final redPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      rect.deflate(stroke / 2),
      -pi / 2,
      2 * pi,
      false,
      redPaint,
    );
    final greenPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    final sweepAngle =
    total == 0 ? 0.0 : (value / total) * 2 * pi * progress;

    canvas.drawArc(
      rect.deflate(stroke / 2),
      -pi / 2,
      sweepAngle,
      false,
      greenPaint,
    );
    final lightOverlayPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      rect.deflate(35), 
      0, 
      2 * pi, 
      false, 
      lightOverlayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.value != value ||
        oldDelegate.total != total;
  }
}
class CustomToggle extends StatelessWidget {
  final bool value;
  final Function(bool) onChanged;

  const CustomToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.green.withOpacity(0.4),
        ),
        child: Align(
          alignment:
          value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class ActionBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final bool enabled;

  const ActionBox(
      this.icon,
      this.text, {
        this.onTap,
        this.enabled = true,
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,

          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withAlpha(5),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: enabled
                        ? AppColors.primary
                        : Colors.grey,
                    size: 34,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: enabled ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}