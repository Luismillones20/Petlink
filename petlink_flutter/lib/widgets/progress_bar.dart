import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double value;
  final IconData icon;
  final Color? color;
  final Color iconColor;

  const ProgressBar({
    Key? key,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasError = value < 0;
    final barColor = hasError 
        ? Colors.red 
        : (color ?? (value > 50 ? Colors.green : value > 20 ? Colors.orange : Colors.red));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: hasError ? Colors.red : iconColor, size: 18),
                const SizedBox(width: 6),
                const Text('Nivel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            Text(
              hasError ? 'ERROR SENSOR' : '${value.round()}%', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: barColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: hasError ? 1.0 : (value / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
