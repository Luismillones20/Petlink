import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Notificaciones Recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          if (state.alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(LucideIcons.bell, size: 48, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No hay alertas recientes', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
                ],
              ),
            )
          else
            ...state.alerts.map((alert) {
              final isPending = alert.status == 'pending';
              final borderColor = isPending ? theme.primaryColor : (isDark ? Colors.grey[800]! : Colors.grey[300]!);
              
              IconData iconData;
              Color iconColor;
              if (alert.type.contains('food')) {
                iconData = LucideIcons.bone;
                iconColor = theme.primaryColor;
              } else if (alert.type.contains('water')) {
                iconData = LucideIcons.droplets;
                iconColor = Colors.blue;
              } else {
                iconData = LucideIcons.activity;
                iconColor = Colors.orange;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border(left: BorderSide(color: borderColor, width: 4)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
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
                              Icon(iconData, size: 16, color: iconColor),
                              const SizedBox(width: 8),
                              Text(alert.msg, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text(alert.time, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
                        ],
                      ),
                      
                      if (isPending)
                        Padding(
                          padding: const EdgeInsets.top(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => state.resolveAlert(alert.id, 'resolved'),
                                  icon: const Icon(LucideIcons.check, size: 16),
                                  label: const Text('Autorizar'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => state.resolveAlert(alert.id, 'denied'),
                                  icon: const Icon(LucideIcons.x, size: 16),
                                  label: const Text('Denegar'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      if (alert.status == 'resolved')
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text('✓ Solicitud autorizada', style: TextStyle(fontSize: 12, color: Colors.green)),
                        ),
                      if (alert.status == 'denied')
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text('✗ Solicitud denegada', style: TextStyle(fontSize: 12, color: Colors.red)),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
