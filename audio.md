Primero agrega las dependencias en pubspec.yaml:
dependencies:
  web_socket_channel: ^2.4.0
  record: ^5.0.4          # micrófono
  audioplayers: ^5.2.1    # parlante
  permission_handler: ^11.0.0

  // audio_service.dart
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static const String WS_URL = 'ws://18.225.238.184:8765/app';

  WebSocketChannel? _channel;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer   _player   = AudioPlayer();
  bool _conectado = false;
  bool _escuchando = false;

  // ── Conectar al servidor ──────────────────
  Future<void> conectar() async {
    _channel = WebSocketChannel.connect(Uri.parse(WS_URL));
    _conectado = true;
    print('[Flutter] WebSocket audio conectado');

    // Escuchar audio que llega del ESP32
    _channel!.stream.listen(
      (data) {
        if (data is Uint8List) {
          _reproducirAudio(data);
        }
      },
      onDone: () {
        _conectado = false;
        print('[Flutter] WebSocket desconectado');
      },
    );
  }

  // ── Empezar a hablar ──────────────────────
  Future<void> iniciarMicrofono() async {
    if (!_conectado) return;

    final tienePermiso = await _recorder.hasPermission();
    if (!tienePermiso) return;

    _escuchando = true;

    // Grabar en stream y enviar por WebSocket
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 8000,
        numChannels: 1,
      ),
    );

    stream.listen((audioChunk) {
      if (_conectado && _escuchando) {
        _channel!.sink.add(audioChunk);
      }
    });

    print('[Flutter] Micrófono activado');
  }

  // ── Dejar de hablar ───────────────────────
  Future<void> detenerMicrofono() async {
    _escuchando = false;
    await _recorder.stop();
    print('[Flutter] Micrófono detenido');
  }

  // ── Reproducir audio del ESP32 ────────────
  void _reproducirAudio(Uint8List audioData) {
    _player.play(BytesSource(audioData));
  }

  // ── Desconectar ───────────────────────────
  void desconectar() {
    _channel?.sink.close();
    _recorder.stop();
    _player.dispose();
    _conectado = false;
  }

  bool get conectado => _conectado;
}

