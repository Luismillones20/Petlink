#include <Servo.h>
#include "HX711.h"

// ══════════════════════════════════════════
//  PINES FASE 1
// ══════════════════════════════════════════
#define TRIG_PIN    9
#define ECHO_PIN    10
#define SERVO_PIN   6
#define BTN_COMIDA  2
#define BTN_AGUA    3
#define LED_COMIDA  4
#define LED_AGUA    5
#define LED_ALERTA  7
#define LED_BOMBA   11
#define BUZZER      8
#define HX711_DT    A0
#define HX711_SCK   A1

// ══════════════════════════════════════════
//  PINES FASE 2
// ══════════════════════════════════════════
int pinsSonda[10] = {22,23,24,25,26,27,28,29,30,31};
#define BOMBA_PIN 32

// ══════════════════════════════════════════
//  OBJETOS
// ══════════════════════════════════════════
Servo dispensador;
HX711 balanza;

#define FACTOR_CALIBRACION 420.0

// ══════════════════════════════════════════
//  UMBRALES
// ══════════════════════════════════════════
#define DISTANCIA_ALERTA      15
#define PESO_MINIMO           50.0
#define INTERVALO_COMIDA      10000
#define NIVEL_ENCENDER_BOMBA  30
#define NIVEL_APAGAR_BOMBA    80
#define TIEMPO_MAX_BOMBA      5000
#define INTERVALO_PUBLICAR    3000

// ══════════════════════════════════════════
//  VARIABLES DE ESTADO
// ══════════════════════════════════════════
unsigned long ultimaAlimentacion = 0;
unsigned long ultimaPublicacion  = 0;
bool          servoAbierto       = false;
bool          bombaActiva        = false;
unsigned long tiempoAbrioServo   = 0;
unsigned long tiempoEncioBomba   = 0;

// ══════════════════════════════════════════
//  FUNCIONES AUXILIARES
// ══════════════════════════════════════════
long medirDistancia() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  return pulseIn(ECHO_PIN, HIGH) * 0.034 / 2;
}

float leerPeso() {
  if (balanza.is_ready()) return balanza.get_units(5);
  return -1;
}

int leerNivelAgua() {
  int nivelMaximo = 0;
  for (int i = 0; i < 10; i++) {
    if (digitalRead(pinsSonda[i]) == LOW) {
      nivelMaximo = (i + 1) * 10;
    }
  }
  return nivelMaximo;
}

void alertaBuzzer(int veces) {
  for (int i = 0; i < veces; i++) {
    digitalWrite(BUZZER, HIGH); delay(150);
    digitalWrite(BUZZER, LOW);  delay(150);
  }
}

void abrirDispensador() {
  Serial.println("[MEGA] Abriendo dispensador");
  dispensador.write(90);
  servoAbierto     = true;
  tiempoAbrioServo = millis();
  digitalWrite(LED_COMIDA, HIGH);
  alertaBuzzer(1);
  Serial1.println("EVT:DISPENSANDO");
}

void cerrarDispensador() {
  dispensador.write(0);
  servoAbierto = false;
  digitalWrite(LED_COMIDA, LOW);
  Serial1.println("EVT:DISPENSADOR_CERRADO");
}

void encenderBomba() {
  Serial.println("[MEGA] Bomba ENCENDIDA");
  digitalWrite(BOMBA_PIN, HIGH);
  digitalWrite(LED_BOMBA, HIGH);
  bombaActiva      = true;
  tiempoEncioBomba = millis();
  alertaBuzzer(1);
  Serial1.println("EVT:BOMBA_ON");
}

void apagarBomba() {
  Serial.println("[MEGA] Bomba APAGADA");
  digitalWrite(BOMBA_PIN, LOW);
  digitalWrite(LED_BOMBA, LOW);
  bombaActiva = false;
  Serial1.println("EVT:BOMBA_OFF");
}

// ══════════════════════════════════════════
//  RECIBIR COMANDOS DESDE NODEMCU
// ══════════════════════════════════════════
void leerComandosESP() {
  if (Serial1.available()) {
    String cmd = Serial1.readStringUntil('\n');
    cmd.trim();
    Serial.print("[MEGA] Comando recibido: ");
    Serial.println(cmd);

    if (cmd == "CMD:DISPENSAR") {
      if (!servoAbierto) abrirDispensador();
    }
    else if (cmd == "CMD:BOMBA_ON") {
      if (!bombaActiva) encenderBomba();
    }
    else if (cmd == "CMD:BOMBA_OFF") {
      if (bombaActiva) apagarBomba();
    }
  }
}

// ══════════════════════════════════════════
//  SETUP
// ══════════════════════════════════════════
void setup() {
  Serial.begin(9600);
  Serial1.begin(9600);

  dispensador.attach(SERVO_PIN);
  dispensador.write(0);

  pinMode(TRIG_PIN,  OUTPUT);
  pinMode(ECHO_PIN,  INPUT);
  pinMode(BTN_COMIDA, INPUT);
  pinMode(BTN_AGUA,   INPUT);
  pinMode(LED_COMIDA, OUTPUT);
  pinMode(LED_AGUA,   OUTPUT);
  pinMode(LED_ALERTA, OUTPUT);
  pinMode(LED_BOMBA,  OUTPUT);
  pinMode(BUZZER,     OUTPUT);
  pinMode(BOMBA_PIN,  OUTPUT);

  for (int i = 0; i < 10; i++) {
    pinMode(pinsSonda[i], INPUT);
  }

  balanza.begin(HX711_DT, HX711_SCK);
  balanza.set_scale(FACTOR_CALIBRACION);
  balanza.tare();

  Serial.println("=== FASE 3 MEGA LISTA ===");
}

// ══════════════════════════════════════════
//  LOOP
// ══════════════════════════════════════════
void loop() {
  unsigned long ahora    = millis();
  long          distancia = medirDistancia();
  float         peso      = leerPeso();
  int           nivelAgua = leerNivelAgua();

  leerComandosESP();

  // ── Cerrar servo tras 2 seg ────────────
  if (servoAbierto && (ahora - tiempoAbrioServo >= 2000)) {
    cerrarDispensador();
  }

  // ── Alerta contenedor bajo ─────────────
  if (distancia > DISTANCIA_ALERTA) {
    digitalWrite(LED_ALERTA, HIGH);
    Serial1.println("ALERTA:COMIDA_BAJA");
  } else {
    digitalWrite(LED_ALERTA, LOW);
  }

  // ── Alimentación automática ─────────────
  if (ahora - ultimaAlimentacion >= INTERVALO_COMIDA) {
    ultimaAlimentacion = ahora;
    if (peso < PESO_MINIMO && !servoAbierto) {
      abrirDispensador();
    }
  }

  // ── Lógica bomba ────────────────────────
  if (bombaActiva && (ahora - tiempoEncioBomba >= TIEMPO_MAX_BOMBA)) {
    apagarBomba();
  }
  if (!bombaActiva && nivelAgua <= NIVEL_ENCENDER_BOMBA) {
    encenderBomba();
  }
  if (bombaActiva && nivelAgua >= NIVEL_APAGAR_BOMBA) {
    apagarBomba();
  }

  // ── Botón comida ────────────────────────
  if (digitalRead(BTN_COMIDA) == HIGH) {
    Serial.println("[MEGA] Boton COMIDA");
    Serial1.println("BTN:COMIDA");
    alertaBuzzer(2);
    digitalWrite(LED_COMIDA, HIGH);
    delay(300);
    digitalWrite(LED_COMIDA, LOW);
    delay(200);
  }

  // ── Botón agua ──────────────────────────
  if (digitalRead(BTN_AGUA) == HIGH) {
    Serial.println("[MEGA] Boton AGUA");
    Serial1.println("BTN:AGUA");
    alertaBuzzer(2);
    digitalWrite(LED_AGUA, HIGH);
    delay(300);
    digitalWrite(LED_AGUA, LOW);
    delay(200);
  }

  // ── Publicar datos cada 3 seg ───────────
  if (ahora - ultimaPublicacion >= INTERVALO_PUBLICAR) {
    ultimaPublicacion = ahora;
    String datos = "DATA:";
    datos += distancia; datos += ",";
    datos += (int)peso; datos += ",";
    datos += nivelAgua; datos += ",";
    datos += bombaActiva  ? "1" : "0"; datos += ",";
    datos += servoAbierto ? "1" : "0";
    Serial1.println(datos);
    Serial.println("[MEGA] Enviado → " + datos);
  }

  delay(300);
}