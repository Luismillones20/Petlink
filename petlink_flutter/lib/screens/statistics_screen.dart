import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).fetchAIRecommendations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final accentColor = const Color(0xFFF39C12);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estadísticas de Salud',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Diario'),
            Tab(text: 'Mensual'),
            Tab(text: 'Análisis de Salud'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildDailyTab(context, state, cardColor, isDark),
          _buildMonthlyTab(context, state, cardColor, isDark),
          _buildHealthTab(context, state, cardColor, isDark),
        ],
      ),
    );
  }

  // --- TAB 1: DIARIO ---
  Widget _buildDailyTab(BuildContext context, AppState state, Color cardColor, bool isDark) {
    final theme = Theme.of(context);
    final foodPercent = (state.todayFoodIntake / state.dailyFoodTarget).clamp(0.0, 1.0);
    final waterPercent = (state.todayWaterIntake / state.dailyWaterTarget).clamp(0.0, 1.0);
    final caloriePercent = (state.todayCalorieIntake / state.dailyCaloricTarget).clamp(0.0, 1.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row for Hydration & Calories Circular Progress Rings
          Row(
            children: [
              Expanded(
                child: Container(
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
                    children: [
                      const Text(
                        'Hidratación de Hoy',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CustomPaint(
                          painter: CircularProgressPainter(
                            percent: waterPercent,
                            color: Colors.blue,
                            trackColor: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${state.todayWaterIntake.round()}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                                const Text(
                                  'mL / 600',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        waterPercent >= 1.0 ? '¡Meta Completada!' : 'Faltan ${(state.dailyWaterTarget - state.todayWaterIntake).clamp(0, 1000).round()} mL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: waterPercent >= 1.0 ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
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
                    children: [
                      const Text(
                        'Calorías Activas',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CustomPaint(
                          painter: CircularProgressPainter(
                            percent: caloriePercent,
                            color: const Color(0xFFF39C12),
                            trackColor: isDark ? Colors.orange.withOpacity(0.1) : Colors.orange.withOpacity(0.05),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${state.todayCalorieIntake.round()}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                                const Text(
                                  'kcal / 900',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Comida: ${state.todayFoodIntake.round()}g servidos',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE67E22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. EXTREMELY UNIQUE METER: Eating Speed Gauge (HX711 dynamic parsing)
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
                    const Text(
                      'Velocidad de Ingesta (HX711)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Saludable',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.activity, color: Colors.teal, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${state.eatingSpeed} g/segundo',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Calculado por los intervalos de caída de peso en el plato',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Visual Gauge Bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (state.eatingSpeed / 4.0).clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.green, Colors.orange, Colors.red],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Lento (< 1.0 g/s)', style: TextStyle(fontSize: 8, color: Colors.grey)),
                    Text('Óptimo (1.5 - 2.5 g/s)', style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold)),
                    Text('Rápido (> 3.0 g/s)', style: TextStyle(fontSize: 8, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.heartPulse, size: 14, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Max tiene un ritmo excelente. Esto previene torsiones gástricas y ahogamiento.',
                          style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Today's Feeding Logs
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
                  'Registro de Ingestas Hoy',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (state.todayFeedingLogs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No hay comidas registradas hoy.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.todayFeedingLogs.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.grey.withOpacity(0.2)),
                    itemBuilder: (context, index) {
                      final log = state.todayFeedingLogs[index];
                      final isManual = log['type'] == 'Manual';
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isManual ? Colors.orange.withOpacity(0.12) : Colors.green.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.bone,
                                  color: isManual ? Colors.orange : Colors.green,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isManual ? 'Dosificación Manual' : 'Horario Programado',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  Text(
                                    log['time'],
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '+${log['amount']}g',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.teal),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: MENSUAL ---
  Widget _buildMonthlyTab(BuildContext context, AppState state, Color cardColor, bool isDark) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month-over-Month Custom Chart Card
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
                          'Comparativa Histórica Mensual',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Últimos 6 meses de consumo',
                          style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                        ),
                      ],
                    ),
                    const Icon(LucideIcons.calendar, size: 16, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 24),
                // Custom Paint Monthly Bar Chart
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: MonthlyBarChartPainter(
                      foodData: state.monthlyFoodHistory,
                      waterData: state.monthlyWaterHistory,
                      labels: state.monthLabels,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: const Color(0xFFF39C12), borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 6),
                    const Text('Comida (kg)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(width: 24),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 6),
                    const Text('Agua (L)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Aggregated Monthly Metrics
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
                  'Resumen de Tendencia Mensual',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildMetricRow(
                  context: context,
                  icon: LucideIcons.trendingUp,
                  iconColor: Colors.green,
                  label: 'Consumo comida promedio',
                  value: '23.8 kg / mes',
                  caption: 'Estable en rango del Golden Retriever',
                ),
                Divider(color: Colors.grey.withOpacity(0.2), height: 24),
                _buildMetricRow(
                  context: context,
                  icon: LucideIcons.droplets,
                  iconColor: Colors.blue,
                  label: 'Consumo agua promedio',
                  value: '8.1 L / mes',
                  caption: 'Perfecta hidratación del 100%',
                ),
                Divider(color: Colors.grey.withOpacity(0.2), height: 24),
                _buildMetricRow(
                  context: context,
                  icon: LucideIcons.badgeAlert,
                  iconColor: Colors.orange,
                  label: 'Alertas omitidas',
                  value: '0 este mes',
                  caption: 'Cero ausencias de alimentación registradas',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: ANÁLISIS DE SALUD ---
  Widget _buildHealthTab(BuildContext context, AppState state, Color cardColor, bool isDark) {
    final theme = Theme.of(context);
    
    // Calculate water intake per kg
    final mlPerKg = state.todayWaterIntake / state.petWeight;
    String hydrationStatus = 'Insuficiente';
    Color hydrationColor = Colors.orange;
    if (mlPerKg >= 45.0) {
      hydrationStatus = 'Excelente';
      hydrationColor = Colors.green;
    } else if (mlPerKg >= 30.0) {
      hydrationStatus = 'Bueno';
      hydrationColor = Colors.blue;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Interactive Health Index Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFFF39C12).withOpacity(0.12), Colors.orange.withOpacity(0.04)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF39C12).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.pawPrint, color: const Color(0xFFF39C12), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Índice de Salud de Max',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const Icon(LucideIcons.heartPulse, color: Colors.red, size: 20),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  '98/100',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.green),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Índice Altamente Favorable',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSubHealthIndex('Nutrición', '100%', Colors.green),
                    _buildSubHealthIndex('Hidratación', '${(state.todayWaterIntake/state.dailyWaterTarget*100).clamp(0, 100).round()}%', Colors.blue),
                    _buildSubHealthIndex('Ingesta', 'Excelente', Colors.teal),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Hydration Index calculation card (Different and Extremely Useful!)
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
                  'Cálculo de Hidratación por Peso',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Los veterinarios recomiendan entre 40-50 mL de agua por kg al día.',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ingesta actual por kg:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          '${mlPerKg.toStringAsFixed(1)} mL/kg',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: hydrationColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        hydrationStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: hydrationColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (mlPerKg / 50.0).clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: hydrationColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0 mL', style: TextStyle(fontSize: 8, color: Colors.grey)),
                    Text('Meta: 45 mL/kg', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text('50 mL+', style: TextStyle(fontSize: 8, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. AI Smart Diagnostic Recommendations
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
                    Row(
                      children: [
                        const Icon(LucideIcons.sparkles, color: Color(0xFFF39C12), size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Recomendaciones IA PetLink',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.rotateCw,
                        size: 16,
                        color: state.loadingAiRecommendations ? Colors.orange : Colors.grey,
                      ),
                      onPressed: state.loadingAiRecommendations
                          ? null
                          : () => state.fetchAIRecommendations(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.loadingAiRecommendations)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF39C12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Generando recomendaciones de salud con IA...',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  for (var rec in state.aiRecommendations) ...[
                    _buildAiRecommendationItem(rec),
                    const SizedBox(height: 12),
                  ]
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets for health diagnostics
  Widget _buildSubHealthIndex(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAiRecommendationItem(String recommendation) {
    String emoji = "✨";
    String content = recommendation;
    if (recommendation.isNotEmpty) {
      final firstWord = recommendation.split(' ').first;
      if (firstWord.length <= 4 && (firstWord.startsWith(RegExp(r'[\u{1F300}-\u{1F9FF}]')) || firstWord.codeUnits.any((u) => u > 255))) {
        emoji = firstWord;
        content = recommendation.substring(firstWord.length).trim();
      }
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF39C12).withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String caption,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(caption, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}

// --- CUSTOM CIRCULAR PROGRESS PAINTER ---
class CircularProgressPainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color trackColor;

  CircularProgressPainter({
    required this.percent,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 6;

    final paintTrack = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0;

    final paintProgress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 9.0;

    canvas.drawCircle(center, radius, paintTrack);
    
    // Draw progress arc starting from top (-90 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * percent,
      false,
      paintProgress,
    );
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter oldDelegate) {
    return oldDelegate.percent != percent || oldDelegate.color != color;
  }
}

// --- CUSTOM MONTHLY BAR CHART PAINTER ---
class MonthlyBarChartPainter extends CustomPainter {
  final List<double> foodData;
  final List<double> waterData;
  final List<String> labels;
  final bool isDark;

  MonthlyBarChartPainter({
    required this.foodData,
    required this.waterData,
    required this.labels,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (foodData.isEmpty || waterData.isEmpty) return;

    final double chartHeight = size.height - 25;
    final double groupWidth = size.width / foodData.length;
    
    final paintGrid = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw horizontal grid lines
    for (int i = 0; i <= 3; i++) {
      double y = chartHeight - (i * chartHeight / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final double maxVal = 30.0; // Max expected Monthly value (30kg or 30L)
    final double minVal = 0.0;

    for (int i = 0; i < foodData.length; i++) {
      // Group center X
      double groupCenterX = (i * groupWidth) + (groupWidth / 2);
      
      // Bar width
      const double barWidth = 12.0;
      
      // Heights
      double foodPct = (foodData[i] - minVal) / (maxVal - minVal);
      double waterPct = (waterData[i] - minVal) / (maxVal - minVal);
      foodPct = foodPct.clamp(0.05, 1.0);
      waterPct = waterPct.clamp(0.05, 1.0);

      double foodBarHeight = foodPct * chartHeight;
      double waterBarHeight = waterPct * chartHeight;

      // Draw Food Bar (Left)
      final foodRect = Rect.fromLTWH(
        groupCenterX - barWidth - 2, 
        chartHeight - foodBarHeight, 
        barWidth, 
        foodBarHeight
      );
      final foodPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(foodRect)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(foodRect, const Radius.circular(3)), foodPaint);

      // Draw Water Bar (Right)
      final waterRect = Rect.fromLTWH(
        groupCenterX + 2, 
        chartHeight - waterBarHeight, 
        barWidth, 
        waterBarHeight
      );
      final waterPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Colors.blue, Color(0xFF3498DB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(waterRect)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(waterRect, const Radius.circular(3)), waterPaint);

      // Draw Month Label
      final textSpan = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontSize: 9.0,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(groupCenterX - (textPainter.width / 2), chartHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant MonthlyBarChartPainter oldDelegate) {
    return oldDelegate.foodData != foodData || oldDelegate.waterData != waterData || oldDelegate.isDark != isDark;
  }
}
