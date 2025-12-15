import 'package:flutter/material.dart';
import 'dart:math';
// no direct model dependency required

class CategoryBarChart extends StatelessWidget {
  final Map<String, double> data; // category -> value
  const CategoryBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final maxVal = entries.isEmpty
        ? 1.0
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: entries.length * 56.0 + 16,
      child: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final e = entries[index];
          final ratio = maxVal == 0 ? 0.0 : (e.value / maxVal);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(width: 80, child: Text(e.key)),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                          height: 28,
                          decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(6))),
                      FractionallySizedBox(
                        widthFactor: ratio,
                        child: Container(
                            height: 28,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                    width: 80, child: Text('${e.value.toStringAsFixed(0)} 大卡')),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SimpleLineChart extends StatelessWidget {
  final List<double> values; // ordered by time (oldest -> newest)
  final List<String>? labels;

  const SimpleLineChart({super.key, required this.values, this.labels});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 160),
      painter: _LineChartPainter(values, labels),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String>? labels;
  _LineChartPainter(this.values, this.labels);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final maxVal =
        values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final minVal =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final gap = values.isEmpty
        ? 0.0
        : size.width / (values.length - 1 == 0 ? 1 : (values.length - 1));

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * gap;
      final y = size.height - ((values[i] - minVal) / range) * size.height;
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    // draw points
    final pointPaint = Paint()..color = Colors.white;
    for (var i = 0; i < values.length; i++) {
      final x = i * gap;
      final y = size.height - ((values[i] - minVal) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
      if (labels != null && i < labels!.length) {
        textPainter.text = TextSpan(
            text: labels![i],
            style: const TextStyle(color: Colors.white70, fontSize: 10));
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(x - textPainter.width / 2, size.height + 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DonutChart extends StatelessWidget {
  final double proteinCalories;
  final double fatCalories;
  final double carbsCalories;
  final double totalCalories;
  final double proteinGrams;
  final double fatGrams;
  final double carbsGrams;

  const DonutChart({
    super.key,
    required this.proteinCalories,
    required this.fatCalories,
    required this.carbsCalories,
    required this.totalCalories,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbsGrams,
  });

  @override
  Widget build(BuildContext context) {
    final segments = [proteinCalories, fatCalories, carbsCalories];
    final colors = [
      const Color(0xFF6FB3E0), // protein - blue
      const Color(0xFFF5C76A), // fat - yellow
      const Color(0xFF8ED9A8), // carbs - green
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final maxSide =
          constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
      final size = maxSide.clamp(120.0, 320.0);
      final legendSpacing = 12.0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: size,
            width: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(size, size),
                  painter: _DonutPainter(segments: segments, colors: colors),
                ),
                // center labels
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('熱量',
                        style: TextStyle(
                            color: Colors.white70, fontSize: size * 0.06)),
                    Text(totalCalories.toStringAsFixed(0),
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: size * 0.18,
                            fontWeight: FontWeight.bold)),
                    Text('kcal',
                        style: TextStyle(
                            color: Colors.white70, fontSize: size * 0.055)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: legendSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _macroLegend(colors[0], '蛋白質', proteinGrams),
              _macroLegend(colors[1], '脂肪', fatGrams),
              _macroLegend(colors[2], '碳水', carbsGrams),
            ],
          )
        ],
      );
    });
  }

  Widget _macroLegend(Color color, String label, double grams) {
    return Column(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text('${grams.toStringAsFixed(1)} g',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> segments;
  final List<Color> colors;
  _DonutPainter({required this.segments, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold(0.0, (a, b) => a + b);
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;
    final thickness = radius * 0.25;

    double startAngle = -pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt;

    for (var i = 0; i < segments.length; i++) {
      final sweep = total == 0
          ? (2 * pi / segments.length)
          : (segments[i] / total) * 2 * pi;
      paint.color = colors[i % colors.length];
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - thickness / 2),
          startAngle,
          sweep,
          false,
          paint);
      startAngle += sweep;
    }

    // gap effect: draw background arc thin to create separation (optional)
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = Colors.white.withOpacity(0.06);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - thickness / 2),
        0,
        2 * pi,
        false,
        bg);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
