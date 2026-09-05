/// Модель рассчитанных параметров сварочного цикла
class CalculatedParameters {
  final double thickness;
  final double stroke;
  final int power;
  final double weld;
  final double forgeTimeTable;
  final double nuggetDiameter;
  final double pressure;
  final double squeeze1;
  final double forgePressure;
  final int forgeDelay;
  final double cold3;
  final double postWeld;
  final int postPower;
  final double holdTime;
  final double offTime;

  // Дополнительные поля для циклограммы
  final double preWeld;
  final double cold1;
  final double slopeUp;
  final double slopeDown;
  final double cold2;
  final int impulseCount;

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
    this.preWeld = 0.0,
    this.cold1 = 0.0,
    this.slopeUp = 0.0,
    this.slopeDown = 0.0,
    this.cold2 = 0.0,
    this.impulseCount = 1,
  });
}