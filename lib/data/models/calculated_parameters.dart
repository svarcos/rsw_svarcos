/// Модель рассчитанных параметров сварочного цикла
/// Используется для передачи данных из расчётного модуля в UI
class CalculatedParameters {
  // ---- ИСХОДНЫЕ ДАННЫЕ ----
  final double thickness;          // Толщина детали, мм
  final double stroke;             // Рабочий ход электродов, мм

  // ---- ТАБЛИЧНЫЕ ПАРАМЕТРЫ (АМг6) ----
  final double power;              // POWER, %
  final double weld;               // WELD, имп
  final double forgeTimeTable;     // tForge, имп

  // ---- РАССЧИТАННЫЕ ПАРАМЕТРЫ ----
  final double nuggetDiameter;     // Диаметр литого ядра, мм
  final double pressure;           // PRESSURE, бар
  final double squeeze1;           // SQUEEZE 1, имп
  final double forgePressure;      // FORG.PRESS., бар
  final double forgeDelay;         // FORGE DELAY, имп
  final double cold3;              // COLD 3, имп
  final double postWeld;           // POST-WELD, имп
  final double postPower;          // POST-POWER, %
  final double holdTime;           // HOLD TIME, имп
  final double offTime;            // OFF TIME, имп

  // ---- ПАРАМЕТРЫ МНОГОИМПУЛЬСНОГО ЦИКЛА (пока не используются) ----
  final double? preheatCurrent;    // PRE-POWER, %
  final double? preheatTime;       // PRE-WELD, имп
  final double? pause1;            // COLD 1, имп
  final int? impulseCount;         // IMPULSE N.
  final double? pause2;            // COLD 2, имп
  final double? slopeUp;           // SLOPE UP, имп
  final double? slopeDown;         // SLOPE DOWN, имп
  final double cyclePause;         // OFF TIME, имп (дублируется)

  const CalculatedParameters({
    required this.thickness,
    required this.stroke,
    required this.power,
    required this.weld,
    required this.forgeTimeTable,
    required this.nuggetDiameter,
    required this.pressure,
    required this.squeeze1,
    required this.forgePressure,
    required this.forgeDelay,
    required this.cold3,
    required this.postWeld,
    required this.postPower,
    required this.holdTime,
    required this.offTime,
    this.preheatCurrent,
    this.preheatTime,
    this.pause1,
    this.impulseCount,
    this.pause2,
    this.slopeUp,
    this.slopeDown,
    this.cyclePause = 0.5,
  });
}