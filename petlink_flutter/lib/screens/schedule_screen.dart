import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    // Get today's food consumption from global state
    double todayFoodConsumed = state.foodConsumptionHistory.isNotEmpty
        ? state.foodConsumptionHistory.last
        : 0.0;
    const double maxFoodPerDay = 300.0;
    double consumptionRatio = (todayFoodConsumed / maxFoodPerDay).clamp(0.0, 1.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header and Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dosificación Horaria',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Sincronizado con EEPROM (Arduino)',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Añadir nuevo horario (Simulado para esta versión)'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                label: const Text('Nuevo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Schedule Cards List
          ...state.schedules.map((schedule) {
            final isFood = schedule.type == 'food';
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                iconColor: theme.primaryColor,
                collapsedIconColor: Colors.grey,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isFood ? Colors.orange.withOpacity(0.12) : Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isFood ? LucideIcons.bone : LucideIcons.droplets,
                        color: isFood ? theme.primaryColor : Colors.blue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                schedule.time,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.black),
                              ),
                              if (isFood && schedule.validateWithAI) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF39C12).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(LucideIcons.shield, color: Color(0xFFE67E22), size: 9),
                                      SizedBox(width: 3),
                                      Text(
                                        'IA',
                                        style: TextStyle(
                                          color: Color(0xFFE67E22),
                                          fontSize: 8,
                                          fontWeight: FontWeight.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isFood ? 'Porción: ${schedule.amount}' : 'Acción: Llenar Bebedero',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: schedule.active,
                      onChanged: (_) => state.toggleSchedule(schedule.id),
                      activeColor: theme.primaryColor,
                    ),
                  ],
                ),
                children: [
                  const Divider(height: 16),
                  
                  // Expandable Options: AI verification toggle (only for food)
                  if (isFood) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(LucideIcons.shield, color: Color(0xFFF39C12), size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Validar con IA (ESP32-CAM)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Switch(
                          value: schedule.validateWithAI,
                          onChanged: schedule.active
                              ? (val) => state.toggleScheduleAI(schedule.id, val)
                              : null,
                          activeColor: theme.primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Portion grams slider adjustment
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isFood ? 'Cantidad a Servir (gramos)' : 'Volumen de Relleno (ml)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            isFood ? '${schedule.portionGrams}g' : '${schedule.portionGrams}ml',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.black,
                              color: isFood ? theme.primaryColor : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Slider(
                        value: schedule.portionGrams.toDouble(),
                        min: isFood ? 20.0 : 50.0,
                        max: isFood ? 150.0 : 300.0,
                        divisions: isFood ? 13 : 5,
                        activeColor: isFood ? theme.primaryColor : Colors.blue,
                        inactiveColor: (isFood ? theme.primaryColor : Colors.blue).withOpacity(0.15),
                        onChanged: schedule.active
                            ? (val) => state.updateSchedulePortion(schedule.id, val.round())
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 8),

          // 2. Límites Diarios y Prevención (Weight Sensor Metrics Card)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Límites Diarios y Prevención',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Real-time weight consumption safety bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Consumo hoy ( HX711 )',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '${todayFoodConsumed.round()}g / ${maxFoodPerDay.round()}g',
                      style: const TextStyle(fontWeight: FontWeight.black, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: consumptionRatio,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange,
                            consumptionRatio > 0.8 ? Colors.red : Colors.green,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Settings details
                _buildSafetyMetricRow(
                  context,
                  label: 'Dispensaciones extra autorizadas',
                  value: '2 al día',
                ),
                const Divider(height: 20),
                _buildSafetyMetricRow(
                  context,
                  label: 'Margen de prevención plato lleno',
                  value: '220g máx',
                ),
                const SizedBox(height: 12),
                
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.activity, color: Colors.blue, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'El sensor de peso del Arduino Mega detendrá las dispensaciones automáticas si el plato tiene más de 220g para evitar derrames.',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.blue[200] : Colors.blue[800],
                            height: 1.4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSafetyMetricRow(BuildContext context, {required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.black, fontSize: 11),
        ),
      ],
    );
  }
}
