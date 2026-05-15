import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({Key? key}) : super(key: key);

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
          // Profile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    image: const DecorationImage(
                      image: NetworkImage('https://api.dicebear.com/7.x/notionists/png?seed=Max&backgroundColor=F39C12'),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Max', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Golden Retriever • 3 años', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ajustes Generales
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(LucideIcons.settings, size: 18),
                    SizedBox(width: 8),
                    Text('Ajustes Generales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingRow(
                  'Modo Oscuro',
                  Switch(value: state.isDarkMode, onChanged: state.toggleDarkMode, activeColor: theme.primaryColor),
                  true,
                ),
                _buildSettingRow(
                  'Umbral Alerta Comida (%)',
                  Container(
                    width: 60,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('20'),
                  ),
                  true,
                ),
                _buildSettingRow(
                  'Stream aut. por sonido',
                  Switch(value: true, onChanged: (_) {}, activeColor: theme.primaryColor),
                  false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Conexión Sistema
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(LucideIcons.wifi, size: 18),
                    SizedBox(width: 8),
                    Text('Conexión Sistema', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoField('Broker MQTT', 'mqtt://broker.hivemq.com:1883', isDark),
                const SizedBox(height: 12),
                _buildInfoField('Dispositivo ID', 'ESP8266_UTEC_2026', isDark),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          Center(
            child: Text(
              'PetLink v1.0.0 (UTEC 2026)\nConectado vía WebSocket',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, Widget trailing, bool borderBottom) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: borderBottom ? Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          trailing,
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(value, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
