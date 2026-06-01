import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with TickerProviderStateMixin {
  bool isTalking = false;
  late AnimationController _scanController;
  late AnimationController _audioController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _audioController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _audioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Visor de ESP32-CAM con Filtros Holográficos e IA
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Mock camera capture representation (visual simulation)
                  _buildCameraMockupFeed(state),

                  // IR Filter Overlay (Visión nocturna)
                  if (state.infraredLight)
                    Container(
                      color: Colors.greenAccent.withOpacity(0.15),
                    ),

                  // Bounding Box Overlay
                  if (state.isAIEnabled && state.boundingBoxOverlay)
                    _buildAIBoundingBox(context, state),

                  // Scanline Holographic Animation
                  if (state.isAIEnabled)
                    AnimatedBuilder(
                      animation: _scanController,
                      builder: (context, child) {
                        return Positioned(
                          top: _scanController.value * 250,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: state.infraredLight
                                      ? Colors.greenAccent
                                      : theme.primaryColor,
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // Corner Surveillance Brackets (Surveillance style)
                  _buildCameraBrackets(state),

                  // Live & Resolution Badges
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            state.infraredLight ? 'MODO: INFRARROJO' : '720p • ESP32-CAM',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Audio Node Status (MAX9814)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.volume2, color: Colors.green, size: 12),
                          SizedBox(width: 6),
                          Text(
                            'MAX9814: Activo',
                            style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Panel de Control de Inteligencia Artificial (IA)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
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
                  children: const [
                    Icon(LucideIcons.shield, color: Color(0xFFF39C12), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Filtros IA y Seguridad',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Toggle IA
                _buildControlRow(
                  title: 'Verificación Facial con IA',
                  subtitle: 'Reconocimiento de rasgos ESP32-CAM',
                  value: state.isAIEnabled,
                  onChanged: state.toggleAIEnabled,
                  activeColor: theme.primaryColor,
                ),
                const Divider(height: 24),

                // Confidence Slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Umbral de Confianza IA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          '${state.aiConfidenceThreshold.round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Slider(
                      value: state.aiConfidenceThreshold,
                      min: 50.0,
                      max: 100.0,
                      divisions: 10,
                      activeColor: theme.primaryColor,
                      inactiveColor: theme.primaryColor.withOpacity(0.15),
                      onChanged: state.isAIEnabled ? state.setConfidenceThreshold : null,
                    ),
                  ],
                ),
                const Divider(height: 24),

                // AI Only feeding toggle
                _buildControlRow(
                  title: 'Alimentación Segura',
                  subtitle: 'Dispensar solo si IA reconoce a Max',
                  value: state.aiOnlyFeeding,
                  onChanged: state.isAIEnabled ? state.toggleAIOnlyFeeding : null,
                  activeColor: theme.primaryColor,
                ),
                const Divider(height: 24),

                // Bounding boxes toggle
                _buildControlRow(
                  title: 'Marcos de Detección',
                  subtitle: 'Mostrar caja verde sobre mascota',
                  value: state.boundingBoxOverlay,
                  onChanged: state.isAIEnabled ? state.toggleBoundingBoxOverlay : null,
                  activeColor: theme.primaryColor,
                ),
                const Divider(height: 24),

                // Infrared Mode Toggle
                _buildControlRow(
                  title: 'Visión Nocturna Infrarroja',
                  subtitle: 'Filtro de luz tenue para la noche',
                  value: state.infraredLight,
                  onChanged: state.toggleInfraredLight,
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Historial de Instantáneas de la ESP32-CAM
          const Text(
            'Instantáneas de Detección (Cámara)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: state.aiSnapshots.length,
              itemBuilder: (context, index) {
                final snap = state.aiSnapshots[index];
                final isMax = snap['label']!.contains('Max');
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMax ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            snap['time']!,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isMax ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              snap['confidence']!,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: isMax ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        snap['label']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        snap['status']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: snap['status']!.contains('Aprobado')
                              ? Colors.green
                              : snap['status']!.contains('Alerta')
                                  ? Colors.orange
                                  : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 4. Audio PTT e Indicador MAX9814
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
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
                // Real-time audio waves when user is speaking
                SizedBox(
                  height: 35,
                  child: isTalking
                      ? AnimatedBuilder(
                          animation: _audioController,
                          builder: (context, child) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(15, (index) {
                                final randomFactor = Random(index).nextDouble();
                                final height = 5.0 + (30.0 * _audioController.value * randomFactor);
                                return Container(
                                  width: 3.5,
                                  height: height,
                                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                );
                              }),
                            );
                          },
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Canal de audio bidireccional listo',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                              ),
                            )
                          ],
                        ),
                ),
                const SizedBox(height: 12),

                // PTT Speak Button
                GestureDetector(
                  onTapDown: (_) => setState(() => isTalking = true),
                  onTapUp: (_) => setState(() => isTalking = false),
                  onTapCancel: () => setState(() => isTalking = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isTalking ? Colors.red : theme.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: isTalking
                              ? Colors.red.withOpacity(0.5)
                              : theme.primaryColor.withOpacity(0.25),
                          blurRadius: isTalking ? 24 : 10,
                          spreadRadius: isTalking ? 6 : 0,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.mic, size: 40, color: Colors.white),
                        const SizedBox(height: 6),
                        Text(
                          isTalking ? 'Hablando...' : 'Presionar\npara hablar',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Row builder for options
  Widget _buildControlRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required Color activeColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.withOpacity(0.9)),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
        ),
      ],
    );
  }

  // Vector / Stylized mock feed rendering for surveillance feel
  Widget _buildCameraMockupFeed(AppState state) {
    final hasIntruder = state.aiStatus.contains('Intruso');
    final isMax = state.aiStatus.contains('Max');
    
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: state.infraredLight ? const Color(0xFF071F0F) : const Color(0xFF1E2429),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cyber style scanning grids
          Opacity(
            opacity: 0.15,
            child: GridPaper(
              color: state.infraredLight ? Colors.green : Colors.blueGrey,
              interval: 40.0,
              subdivisions: 1,
            ),
          ),

          // Central target crosshair
          Opacity(
            opacity: 0.25,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: state.infraredLight ? Colors.green : Colors.white,
                  width: 1,
                ),
              ),
            ),
          ),

          // Stylized Vector Shape representing pet zone
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.pawPrint,
                size: 72,
                color: state.infraredLight
                    ? Colors.green.withOpacity(0.4)
                    : Colors.white24,
              ),
              const SizedBox(height: 12),
              Text(
                'ZONA DE ALIMENTO ACTIVA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: state.infraredLight
                      ? Colors.green.withOpacity(0.5)
                      : Colors.white24,
                ),
              ),
            ],
          ),

          // Real-time camera metadata footer
          Positioned(
            bottom: 12,
            right: 12,
            child: Text(
              'SIGNAL: ${state.wifiSignal}dBm   FPS: 15.0fps',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                color: state.infraredLight ? Colors.green : Colors.white38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Draw simulated AI bounding boxes over target
  Widget _buildAIBoundingBox(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    final hasIntruder = state.aiStatus.contains('Intruso');
    final isMax = state.aiStatus.contains('Max');
    
    final Color color = hasIntruder ? Colors.red : (isMax ? Colors.green : theme.primaryColor);

    return Positioned(
      left: 60,
      top: 50,
      width: 160,
      height: 130,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2.0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -24,
              left: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
                child: Text(
                  '${state.aiStatus} (${state.currentConfidence.round()}%)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Corner overlay surveillance frame
  Widget _buildCameraBrackets(AppState state) {
    final color = state.infraredLight ? Colors.greenAccent : Colors.white24;
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: CustomPaint(
          painter: SurveillanceBracketsPainter(color: color),
        ),
      ),
    );
  }
}

// Painter for cyber style surveillance brackets
class SurveillanceBracketsPainter extends CustomPainter {
  final Color color;

  SurveillanceBracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const double len = 15.0;

    // Top Left
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, len), paint);

    // Top Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);

    // Bottom Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
