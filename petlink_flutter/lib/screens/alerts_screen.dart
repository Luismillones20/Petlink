import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String selectedFilter = 'all'; // 'all', 'pending', 'sound', 'ai'

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    // Filter alerts list based on selection
    final filteredAlerts = state.alerts.where((alert) {
      if (selectedFilter == 'pending') {
        return alert.status == 'pending';
      } else if (selectedFilter == 'sound') {
        return alert.type == 'bark';
      } else if (selectedFilter == 'ai') {
        return alert.type == 'ai_alert';
      }
      return true; // 'all'
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Title and count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Centro de Notificaciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (state.pendingAlertsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.pendingAlertsCount} Pendientes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 2. Interactive Filter Chips Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('all', 'Todas', LucideIcons.bell, theme),
              const SizedBox(width: 8),
              _buildFilterChip('pending', 'Pendientes', LucideIcons.check, theme),
              const SizedBox(width: 8),
              _buildFilterChip('sound', 'Audio (MAX9814)', LucideIcons.volume2, theme),
              const SizedBox(width: 8),
              _buildFilterChip('ai', 'Detección IA', LucideIcons.shield, theme),
            ],
          ),
        ),

        // 3. Alerts Feed List
        Expanded(
          child: filteredAlerts.isEmpty
              ? _buildEmptyState(context, theme)
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = filteredAlerts[index];
                    final isPending = alert.status == 'pending';
                    
                    // Determine colors and icons based on type and severity
                    IconData iconData = LucideIcons.bell;
                    Color iconColor = theme.primaryColor;
                    Color cardBorderColor = isPending ? theme.primaryColor : Colors.transparent;
                    
                    if (alert.type == 'food_req') {
                      iconData = LucideIcons.bone;
                      iconColor = theme.primaryColor;
                    } else if (alert.type == 'bark') {
                      iconData = LucideIcons.volume2;
                      iconColor = Colors.orange;
                    } else if (alert.type == 'ai_alert') {
                      iconData = LucideIcons.shield;
                      iconColor = Colors.red;
                    } else if (alert.type == 'water_req') {
                      iconData = LucideIcons.droplets;
                      iconColor = Colors.blue;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cardBorderColor.withOpacity(0.4),
                          width: isPending ? 1.5 : 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: isPending ? theme.primaryColor : iconColor,
                                width: 4.5,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: iconColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(iconData, size: 14, color: iconColor),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          alert.type == 'food_req'
                                              ? 'Petición de Alimento'
                                              : alert.type == 'bark'
                                                  ? 'Alerta de Audio'
                                                  : alert.type == 'ai_alert'
                                                      ? 'Seguridad IA'
                                                      : 'Notificación',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      alert.time,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  alert.msg,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.3),
                                ),
                                
                                // Interactive actions if pending
                                if (isPending) ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => state.resolveAlert(alert.id, 'resolved'),
                                          icon: const Icon(LucideIcons.check, size: 15, color: Colors.white),
                                          label: const Text('Autorizar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => state.resolveAlert(alert.id, 'denied'),
                                          icon: const Icon(LucideIcons.x, size: 15, color: Colors.red),
                                          label: const Text('Denegar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.red),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                
                                // Status resolution labels
                                if (alert.status == 'resolved') ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: const [
                                      Icon(LucideIcons.check, color: Colors.green, size: 14),
                                      SizedBox(width: 6),
                                      Text(
                                        '✓ Solicitud autorizada • Plato Servido',
                                        style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                                if (alert.status == 'denied') ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: const [
                                      Icon(LucideIcons.x, color: Colors.red, size: 14),
                                      SizedBox(width: 6),
                                      Text(
                                        '✗ Solicitud denegada • Dispensador bloqueado',
                                        style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filterKey, String label, IconData icon, ThemeData theme) {
    final isSelected = selectedFilter == filterKey;
    final isDark = theme.brightness == Brightness.dark;
    
    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.black : FontWeight.bold,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white54 : Colors.black54),
      ),
      selectedColor: theme.primaryColor,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (bool selected) {
        setState(() {
          selectedFilter = filterKey;
        });
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.bell,
                size: 48,
                color: theme.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Historial Limpio',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'No hay notificaciones que coincidan con el filtro seleccionado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
