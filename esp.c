#include <WiFi.h>
#include <PubSubClient.h>
#include <WiFiManager.h>

// ══════════════════════════════════════════
//  MQTT
// ══════════════════════════════════════════
const char* MQTT_BROKER = "18.225.238.184";
const int   MQTT_PORT   = 1883;
const char* CLIENT_ID   = "esp32_dispensador_01";

// ── Topics publicar ────────────────────────
#define TOPIC_DISTANCIA  "mascotas/g4/comida/distancia"
#define TOPIC_PESO       "mascotas/g4/comida/peso"
#define TOPIC_AGUA       "mascotas/g4/agua/nivel"
#define TOPIC_BOMBA      "mascotas/g4/agua/bomba"
#define TOPIC_SERVO      "mascotas/g4/comida/servo"
#define TOPIC_ALERTAS    "mascotas/g4/alertas"
#define TOPIC_BOTONES    "mascotas/g4/botones"

// ── Topics suscribir ───────────────────────
#define TOPIC_CMD_COMIDA "mascotas/g4/cmd/comida"
#define TOPIC_CMD_AGUA   "mascotas/g4/cmd/agua"

// ── Pin para resetear WiFi ─────────────────
#define PIN_RESET_WIFI   0   // GPIO0 = botón BOOT del ESP32

WiFiClient   wifiClient;
PubSubClient mqtt(wifiClient);

// ══════════════════════════════════════════
//  RESET WIFI (mantener botón BOOT 3 seg)
// ══════════════════════════════════════════
void checkResetWiFi() {
  if (digitalRead(PIN_RESET_WIFI) == LOW) {
    unsigned long inicio = millis();
    while (digitalRead(PIN_RESET_WIFI) == LOW) {
      if (millis() - inicio >= 3000) {
        Serial.println("[ESP32] Reseteando WiFi...");
        WiFiManager wm;
        wm.resetSettings();
        ESP.restart();
      }
    }
  }
}

// ══════════════════════════════════════════
//  CONEXIÓN WIFI CON WIFIMANAGER
// ══════════════════════════════════════════
void conectarWiFi() {
  WiFiManager wifiManager;

  // Tiempo máximo para configurar (segundos)
  wifiManager.setConfigPortalTimeout(180);

  // Si no hay credenciales guardadas, crea la red "Dispensador-Setup"
  if (!wifiManager.autoConnect("Dispensador-Setup")) {
    Serial.println("[ESP32] Falló configuración WiFi, reiniciando...");
    ESP.restart();
  }

  Serial.println("[ESP32] WiFi conectado!");
  Serial.print("[ESP32] IP: ");
  Serial.println(WiFi.localIP());
}

// ══════════════════════════════════════════
//  CALLBACK MQTT — COMANDOS DESDE LA APP
// ══════════════════════════════════════════
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String mensaje = "";
  for (int i = 0; i < length; i++) {
    mensaje += (char)payload[i];
  }
  mensaje.trim();

  Serial.print("[ESP32] MQTT recibido → ");
  Serial.print(topic);
  Serial.print(": ");
  Serial.println(mensaje);

  String t = String(topic);

  if (t == TOPIC_CMD_COMIDA && mensaje == "DISPENSAR") {
    Serial2.println("CMD:DISPENSAR");   // → Arduino Mega
  }
  if (t == TOPIC_CMD_AGUA) {
    if      (mensaje == "ON")  Serial2.println("CMD:BOMBA_ON");
    else if (mensaje == "OFF") Serial2.println("CMD:BOMBA_OFF");
  }
}

// ══════════════════════════════════════════
//  CONEXIÓN MQTT
// ══════════════════════════════════════════
void conectarMQTT() {
  while (!mqtt.connected()) {
    Serial.print("[ESP32] Conectando MQTT...");
    if (mqtt.connect(CLIENT_ID)) {
      Serial.println(" OK!");
      mqtt.subscribe(TOPIC_CMD_COMIDA);
      mqtt.subscribe(TOPIC_CMD_AGUA);
    } else {
      Serial.print(" fallo rc=");
      Serial.print(mqtt.state());
      Serial.println(" reintentando en 3s...");
      delay(3000);
    }
  }
}

// ══════════════════════════════════════════
//  PROCESAR MENSAJES DEL ARDUINO MEGA
// ══════════════════════════════════════════
void procesarMensaje(String msg) {
  msg.trim();
  if (msg.length() == 0) return;

  Serial.print("[ESP32] Mega → ");
  Serial.println(msg);

  // DATA:distancia,peso,agua,bomba,servo
  if (msg.startsWith("DATA:")) {
    String datos = msg.substring(5);
    int    idx   = 0;
    String v[5];

    for (int i = 0; i < 5; i++) {
      int coma = datos.indexOf(',', idx);
      if (coma == -1) v[i] = datos.substring(idx);
      else { v[i] = datos.substring(idx, coma); idx = coma + 1; }
    }

    mqtt.publish(TOPIC_DISTANCIA, v[0].c_str());
    mqtt.publish(TOPIC_PESO,      v[1].c_str());
    mqtt.publish(TOPIC_AGUA,      v[2].c_str());
    mqtt.publish(TOPIC_BOMBA,     v[3] == "1" ? "ACTIVA"  : "apagada");
    mqtt.publish(TOPIC_SERVO,     v[4] == "1" ? "ABIERTO" : "cerrado");

    // Publicar señal de WiFi RSSI real
    char rssiStr[10];
    itoa(WiFi.RSSI(), rssiStr, 10);
    mqtt.publish("mascotas/g4/wifi/rssi", rssiStr);

    Serial.println("[ESP32] Datos publicados en MQTT ✓");
  }
  else if (msg.startsWith("ALERTA:")) {
    mqtt.publish(TOPIC_ALERTAS, msg.substring(7).c_str());
    Serial.println("[ESP32] Alerta publicada ✓");
  }
  else if (msg.startsWith("BTN:")) {
    mqtt.publish(TOPIC_BOTONES, msg.substring(4).c_str());
    Serial.println("[ESP32] Botón publicado ✓");
  }
  else if (msg.startsWith("EVT:")) {
    mqtt.publish(TOPIC_ALERTAS, msg.substring(4).c_str());
    Serial.println("[ESP32] Evento publicado ✓");
  }
}

// ══════════════════════════════════════════
//  SETUP
// ══════════════════════════════════════════
void setup() {
  Serial.begin(115200);   // Monitor serie
  Serial2.begin(9600);    // Comunicación con Arduino Mega

  pinMode(PIN_RESET_WIFI, INPUT_PULLUP);

  Serial.println("=== ESP32 DISPENSADOR INICIANDO ===");

  conectarWiFi();

  mqtt.setServer(MQTT_BROKER, MQTT_PORT);
  mqtt.setCallback(mqttCallback);
  conectarMQTT();

  Serial.println("[ESP32] Sistema listo! ✓");
}

// ══════════════════════════════════════════
//  LOOP
// ══════════════════════════════════════════
void loop() {
  // Verificar botón reset WiFi
  checkResetWiFi();

  // Reconectar MQTT si se cae
  if (!mqtt.connected()) conectarMQTT();
  mqtt.loop();

  // Leer mensajes del Arduino Mega
  if (Serial2.available()) {
    String msg = Serial2.readStringUntil('\n');
    procesarMensaje(msg);
  }
}