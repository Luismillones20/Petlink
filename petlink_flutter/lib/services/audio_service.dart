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
    try {
      _channel = WebSocketChannel.connect(Uri.parse(WS_URL));
      _conectado = true;
      print('[Flutter] WebSocket audio conectado');

      // Escuchar audio que llega del ESP32
      _channel!.stream.listen(
        (data) {
          if (data is Uint8List) {
            _reproducirAudio(data);
          } else if (data is List<int>) {
            _reproducirAudio(Uint8List.fromList(data));
          }
        },
        onError: (error) {
          _conectado = false;
          print('[Flutter] WebSocket audio error: $error');
        },
        onDone: () {
          _conectado = false;
          print('[Flutter] WebSocket audio desconectado');
        },
      );
    } catch (e) {
      _conectado = false;
      print('[Flutter] Error al conectar WebSocket de audio: $e');
    }
  }

  // ── Empezar a hablar ──────────────────────
  Future<void> iniciarMicrofono() async {
    if (!_conectado) {
      print('[Flutter] No se puede iniciar micrófono: WebSocket no conectado');
      return;
    }

    try {
      final tienePermiso = await _recorder.hasPermission();
      if (!tienePermiso) {
        print('[Flutter] Permiso de micrófono denegado');
        return;
      }

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
      }, onError: (err) {
        print('[Flutter] Error en stream de grabación: $err');
      });

      print('[Flutter] Micrófono activado');
    } catch (e) {
      print('[Flutter] Error al iniciar micrófono: $e');
    }
  }

  // ── Dejar de hablar ───────────────────────
  Future<void> detenerMicrofono() async {
    _escuchando = false;
    try {
      await _recorder.stop();
      print('[Flutter] Micrófono detenido');
    } catch (e) {
      print('[Flutter] Error al detener micrófono: $e');
    }
  }

  // ── Reproducir audio del ESP32 ────────────
  void _reproducirAudio(Uint8List audioData) {
    try {
      _player.play(BytesSource(audioData));
    } catch (e) {
      print('[Flutter] Error al reproducir audio: $e');
    }
  }

  // ── Desconectar ───────────────────────────
  void desconectar() {
    try {
      _channel?.sink.close();
      _recorder.stop();
      _player.dispose();
    } catch (e) {
      print('[Flutter] Error al desconectar AudioService: $e');
    } finally {
      _conectado = false;
    }
  }

  bool get conectado => _conectado;
}
