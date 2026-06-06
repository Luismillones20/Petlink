import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';

class AIChatbotSheet extends StatefulWidget {
  const AIChatbotSheet({Key? key}) : super(key: key);

  @override
  State<AIChatbotSheet> createState() => _AIChatbotSheetState();
}

class _AIChatbotSheetState extends State<AIChatbotSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'model',
      'text': '¡Hola! Soy PetLink AI, tu asistente inteligente de salud y cuidado de mascotas. ¿Cómo te puedo ayudar hoy con Max? 🐾'
    }
  ];
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }



  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final state = Provider.of<AppState>(context, listen: false);
      
      // Inject context-aware instructions
      final systemContext = 'Eres PetLink AI, un asistente de veterinaria y cuidado de mascotas amigable, experto y profesional. '
          'La mascota de este usuario es Max, un perro Golden Retriever de 25 kg. '
          'Su telemetría de hoy del comedero inteligente PetLink es:\n'
          '- Comida consumida hoy: ${state.todayFoodIntake.round()}g (meta diaria de 240g)\n'
          '- Agua consumida hoy: ${state.todayWaterIntake.round()}ml (meta diaria de 600ml)\n'
          '- Velocidad de alimentación: ${state.eatingSpeed} g/s (HX711)\n\n'
          'Responde de forma natural, empática, concisa (máximo 2-3 oraciones por respuesta) y habla en español. '
          'Si te preguntan sobre su alimentación, salud o estadísticas, usa estos datos reales.';

      // Format conversation history for Gemini API
      final contents = <Map<String, dynamic>>[];
      
      // Append historical messages
      // We prepend the system instructions as system instruction in the API or inside the prompt.
      // Gemini 1.5 Flash supports systemInstruction or simple prepending. Prepending is highly robust.
      contents.add({
        'role': 'user',
        'parts': [
          {'text': '$systemContext\n\nAquí inicia la conversación con el usuario.'}
        ]
      });
      contents.add({
        'role': 'model',
        'parts': [
          {'text': 'Entendido. Estoy listo para asistir al dueño de Max con toda su telemetría e información de salud.'}
        ]
      });

      for (var msg in _messages) {
        contents.add({
          'role': msg['role'] == 'user' ? 'user' : 'model',
          'parts': [
            {'text': msg['text']!}
          ]
        });
      }

      final apiKey = state.activeApiKey;
      if (apiKey.isEmpty) {
        setState(() {
          _messages.add({
            'role': 'model',
            'text': 'Configuración de API Key no encontrada. Por favor revisa la pantalla de configuración en la app o tu archivo .env.'
          });
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }

      final client = HttpClient();
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');
      final request = await client.postUrl(uri);
      request.headers.set('content-type', 'application/json');

      final body = {'contents': contents};
      request.add(utf8.encode(json.encode(body)));

      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = json.decode(responseBody);
        final String replyText = data['candidates'][0]['content']['parts'][0]['text'];
        
        setState(() {
          _messages.add({'role': 'model', 'text': replyText.trim()});
        });
      } else {
        final responseBody = await response.transform(utf8.decoder).join();
        String errorMsg = '';
        try {
          final data = json.decode(responseBody);
          errorMsg = data['error']['message'] ?? '';
        } catch (_) {}

        String replyText = 'Error en el servidor de Gemini (${response.statusCode}). ';
        if (errorMsg.contains('API key') || errorMsg.contains('restricted') || errorMsg.contains('invalid') || errorMsg.contains('not found')) {
          replyText += 'Asegúrate de que tu API Key sea correcta y de que no tenga restricciones activas (Key Restrictions) bloqueando la Generative Language API en Google Cloud Console.';
        } else {
          replyText += 'Verifica tu configuración o intenta de nuevo.';
        }

        setState(() {
          _messages.add({
            'role': 'model',
            'text': replyText
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'model',
          'text': 'Hubo un error de red al intentar comunicarme con la IA. Asegúrate de estar conectado a internet. Detalles: $e'
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final chatBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final headerBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    double sheetHeight = MediaQuery.of(context).size.height * 0.75 - keyboardHeight;
    if (sheetHeight < 250.0) sheetHeight = 250.0;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: chatBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.sparkles, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PetLink IA Chatbot',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Asistente Inteligente Activo',
                              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Rendering loading indicator bubble
                  return _buildLoadingBubble(isDark);
                }

                final msg = _messages[index];
                final isModel = msg['role'] == 'model';

                return _buildMessageBubble(
                  text: msg['text']!,
                  isModel: isModel,
                  isDark: isDark,
                  primaryColor: primaryColor,
                );
              },
            ),
          ),

          // Input field row
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: headerBg,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(isDark ? 0.1 : 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Pregúntale a la IA sobre Max...',
                          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildMessageBubble({
    required String text,
    required bool isModel,
    required bool isDark,
    required Color primaryColor,
  }) {
    final bubbleColor = isModel
        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
        : primaryColor;
    
    final textColor = isModel
        ? (isDark ? Colors.white : Colors.black87)
        : Colors.white;

    final align = isModel ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final radius = isModel
        ? const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
            topLeft: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
            topRight: Radius.circular(16),
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: isModel ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isModel) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, top: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(LucideIcons.sparkles, color: primaryColor, size: 14),
                  ),
                ),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (!isModel) ...[
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
                    image: const DecorationImage(
                      image: NetworkImage('https://api.dicebear.com/7.x/notionists/png?seed=Max&backgroundColor=00D4AA'),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble(bool isDark) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(LucideIcons.sparkles, color: theme.primaryColor, size: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
                topLeft: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'PetLink IA está escribiendo...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
