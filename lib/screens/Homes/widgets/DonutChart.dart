import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import 'dart:math';

class DonutChart extends StatefulWidget {
  final double value;
  final String label;
  final Color color;

  const DonutChart({
    super.key,
    required this.value,
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
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 170),
                    painter: DonutPainter(
                      progress: _controller.value,
                      color: widget.color,
                    ),
                  ),
                  Container(
                    width: 95,
                    height: 95,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    child: Column(
                      children: [
                        Text(
                          widget.value.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 10, height: 10, color: widget.color),
            const SizedBox(width: 6),
            Text(widget.label),
          ],
        ),
      ],
    );
  }
}



class DonutPainter extends CustomPainter {
  final double progress;
  final Color color;

  DonutPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outerStroke = 40.0;

    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerStroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect.deflate(outerStroke / 2),
      -pi / 2,
      2 * pi * progress,
      false,
      outerPaint,
    );

    final middleStroke = 30.0;

    final middlePaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = middleStroke;

    canvas.drawArc(
      rect.deflate(outerStroke + 8),
      -pi / 2,
      2 * pi,
      false,
      middlePaint,
    );

    final innerStroke = 22.0;

    final innerPaint = Paint()
      ..color = Colors.red.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerStroke;

    canvas.drawArc(
      rect.deflate(outerStroke + middleStroke + 16),
      -pi / 2,
      2 * pi,
      false,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) {
    return oldDelegate.progress != progress;
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