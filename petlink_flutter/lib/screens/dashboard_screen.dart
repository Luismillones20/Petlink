import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';
import '../widgets/progress_bar.dart';
import 'statistics_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryGradient = const LinearGradient(
      colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Find any pending food requests to display interactive approval banner
    final pendingFoodRequest = state.alerts.firstWhere(
      (a) => a.type == 'food_req' && a.status == 'pending',
      orElse: () => null as dynamic,
    );

    // Determine weight status text and color
    String weightStatus = 'Estable';
    Color weightStatusColor = Colors.green;
    if (state.foodWeight <= 20) {
      weightStatus = 'Vacío';
      weightStatusColor = Colors.red;
    } else if (state.foodWeight <= 80) {
      weightStatus = 'Bajo';
      weightStatusColor = Colors.orange;
    } else if (state.foodWeight > 180) {
      weightStatus = 'Ración Servida';
      weightStatusColor = Colors.teal;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Dynamic Notification Approval Banner (Top Level)
          if (pendingFoodRequest != null) ...[
            _buildInteractiveApprovalBanner(context, pendingFoodRequest, state),
            const SizedBox(height: 16),
          ],

          // 2. Active Dispenser Solenoid Indicator (Flashing IoT Activity)
          if (state.activeSolenoids > 0) ...[
            _buildActiveHardwareIndicator(context, state.activeSolenoids),
            const SizedBox(height: 16),
          ],

          // 3. Sensor Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSensorWeightCard(
                  context: context,
                  title: 'Plato (Sensor HX711)',
                  weight: state.foodWeight,
                  statusText: weightStatus,
                  statusColor: weightStatusColor,
                  cardColor: cardColor,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context: context,
                  icon: LucideIcons.check,
                  iconColor: Colors.green,
                  title: 'Último Alimento',
                  value: state.lastFed,
                  cardColor: cardColor,
                  footer: 'Dosificador Arduino',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3.5 Premium Health Analytics Banner
          _buildHealthStatsBanner(context, cardColor, isDark),
          const SizedBox(height: 16),

          // 4. Load Cell Real-time Weight Chart Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Histórico de Peso (g)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Monitoreo continuo de balanza',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'En Línea',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: WeightChartPainter(
                      data: state.weightHistory,
                      lineColor: theme.primaryColor,
                      areaColor: theme.primaryColor,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Lecturas anteriores', style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4))),
                    Text('Tiempo real (3s)', style: TextStyle(fontSize: 10, color: theme.primaryColor.withOpacity(0.7), fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Contenedores (Food and Water Levels)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Volumen de Contenedores',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ProgressBar(
                  value: state.foodLevel,
                  icon: LucideIcons.bone,
                  iconColor: theme.primaryColor,
                ),
                const SizedBox(height: 20),
                ProgressBar(
                  value: state.waterLevel,
                  icon: LucideIcons.droplets,
                  iconColor: Colors.blue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. Acciones Rápidas (Alimentar / Servir Agua)
          const Text(
            'Comandos Rápidos IoT',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: state.activeSolenoids > 0 ? null : state.manualFeed,
                    icon: const Icon(LucideIcons.bone, size: 20, color: Colors.white),
                    label: const Text(
                      'Alimentar',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: state.activeSolenoids > 0 ? null : state.manualWater,
                    icon: const Icon(LucideIcons.droplets, size: 20, color: Colors.white),
                    label: const Text(
                      'Agua (150ml)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 7. Expandable Hardware Simulator (For Testing Pet Button)
          _buildHardwareSimulatorPanel(context, theme, state, cardColor, isDark),
        ],
      ),
    );
  }

  // Header Banner for real-time pet action approvals
  Widget _buildInteractiveApprovalBanner(
    BuildContext context,
    dynamic requestAlert,
    AppState state,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C1E12) : const Color(0xFFFDF6EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF39C12).withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF39C12).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF39C12).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.bell, color: Color(0xFFE67E22), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡SOLICITUD EN CURSO!',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Color(0xFFE67E22),
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Max presionó el botón en el dispensador',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'El sistema espera confirmación. La cámara ESP32-CAM se activará para verificar la identidad.',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => state.resolveAlert(requestAlert.id, 'resolved'),
                  icon: const Icon(LucideIcons.check, size: 16, color: Colors.white),
                  label: const Text('Autorizar (80g)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => state.resolveAlert(requestAlert.id, 'denied'),
                  icon: const Icon(LucideIcons.x, size: 16, color: Colors.red),
                  label: const Text('Denegar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // active hardware movement indicator
  Widget _buildActiveHardwareIndicator(BuildContext context, int state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            state == 1
                ? 'Arduino Mega: Dispensando comida...'
                : 'Arduino Mega: Bombeando agua...',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  // Load Cell weight card
  Widget _buildSensorWeightCard({
    required BuildContext context,
    required String title,
    required double weight,
    required String statusText,
    required Color statusColor,
    required Color cardColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
              ),
              const Icon(LucideIcons.activity, size: 14, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${weight.round()}g',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // last food card
  Widget _buildSummaryCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color cardColor,
    required String footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
              ),
              Icon(icon, color: iconColor, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Text(
            footer,
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Expandable panel to mock physical hardware buttons
  Widget _buildHardwareSimulatorPanel(
    BuildContext context,
    ThemeData theme,
    AppState state,
    Color cardColor,
    bool isDark,
  ) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        title: const Text(
          'Simulador de Dispositivo (Hardware)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
        ),
        leading: const Icon(LucideIcons.cpu, color: Colors.blueGrey),
        childrenPadding: const EdgeInsets.all(16),
        expandedAlignment: Alignment.topLeft,
        children: [
          const Text(
            'Simula interacciones físicas que ocurrirían en el circuito Arduino Mega o ESP32-CAM:',
            style: TextStyle(fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              state.triggerPetButtonRequest();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulación: ¡Mascota presionó el botón físico!'),
                  backgroundColor: Color(0xFFF39C12),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(LucideIcons.bell, size: 18, color: Colors.white),
            label: const Text('Simular Botón Físico de Mascota', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          // Network logs mock
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Consola de Depuración IoT:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                const SizedBox(height: 6),
                Text('[Arduino Mega] Sensor HX711 calibrado. Peso inicial: ${state.foodWeight.round()}g', style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.green)),
                const SizedBox(height: 2),
                Text('[ESP32-CAM] Video stream listo en http://${state.esp32CamIP}/stream', style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.blue)),
                const SizedBox(height: 2),
                Text('[MQTT] Publicando en tema: petlink/dispenser/status', style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.purple)),
                const SizedBox(height: 2),
                Text('[Red] RSSI: ${state.wifiSignal} dBm (Señal Fuerte)', style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Premium Health Analytics Banner
  Widget _buildHealthStatsBanner(BuildContext context, Color cardColor, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StatisticsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.sparkles, color: Color(0xFFF39C12), size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Análisis de Salud de Max',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Hidratación: Excelente • Ingesta: Saludable\nVer estadísticas detalladas diarias y mensuales',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}

// --- BEZIER SMOOTH AREA CHART ---
class WeightChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color areaColor;
  final bool isDark;

  WeightChartPainter({
    required this.data,
    required this.lineColor,
    required this.areaColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paintLine = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final paintArea = Paint()..style = PaintingStyle.fill;

    final paintGrid = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double widthBetweenPoints = size.width / (data.length - 1);
    const double maxVal = 200.0; // Max expected scale
    const double minVal = 0.0;

    // Draw horizontal grid lines and labels
    for (int i = 0; i <= 3; i++) {
      double y = size.height - (i * size.height / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
      
      final textSpan = TextSpan(
        text: '${(minVal + (maxVal - minVal) * i / 3).round()}g',
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 9.0,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, y - 12));
    }

    final path = Path();
    final areaPath = Path();

    double getX(int index) => index * widthBetweenPoints;
    double getY(double val) {
      double pct = (val - minVal) / (maxVal - minVal);
      pct = pct.clamp(0.0, 1.0);
      // Give padding to top/bottom
      return size.height - (pct * size.height * 0.8) - (size.height * 0.1);
    }

    path.moveTo(getX(0), getY(data[0]));
    areaPath.moveTo(getX(0), size.height);
    areaPath.lineTo(getX(0), getY(data[0]));

    for (int i = 0; i < data.length - 1; i++) {
      final p0 = Offset(getX(i), getY(data[i]));
      final p1 = Offset(getX(i + 1), getY(data[i + 1]));
      
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p1.dx, p1.dy,
      );

      areaPath.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p1.dx, p1.dy,
      );
    }

    areaPath.lineTo(getX(data.length - 1), size.height);
    areaPath.close();

    // Fill area with linear gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        areaColor.withOpacity(0.35),
        areaColor.withOpacity(0.0),
      ],
    );
    paintArea.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(areaPath, paintArea);
    canvas.drawPath(path, paintLine);

    // Draw circular dots on points
    final paintPoint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final paintPointBorder = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white;

    for (int i = 0; i < data.length; i++) {
      final center = Offset(getX(i), getY(data[i]));
      // draw white border circle first
      canvas.drawCircle(center, 5.0, paintPointBorder);
      // draw colored dot
      canvas.drawCircle(center, 3.5, paintPoint);
    }
  }

  @override
  bool shouldRepaint(covariant WeightChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.isDark != isDark;
  }
}
