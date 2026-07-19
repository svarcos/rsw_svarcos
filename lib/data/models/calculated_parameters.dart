/// Модель рассчитанных параметров сварочного цикла
class CalculatedParameters {
  final String material;
  final double thickness;
  final double nuggetDiameter;
  final double weldingForce;
  final double weldingCurrent;
  final double weldingTime;
  final double squeezeTime;
  final double forgeTime;

  final double? preheatCurrent;
  final double? preheatTime;
  final double? pause1;
  final int? impulseCount;
  final double? pause2;
  final double? slopeUp;
  final double? slopeDown;
  final double? postHeatCurrent;
  final double? postHeatTime;
  final double? pause3;
  final double cyclePause;

  const CalculatedParameters({
    required this.material,
    required this.thickness,
    required this.nuggetDiameter,
    required this.weldingForce,
    required this.weldingCurrent,
    required this.weldingTime,
    required this.squeezeTime,
    required this.forgeTime,
    this.preheatCurrent,
    this.preheatTime,
    this.pause1,
    this.impulseCount,
    this.pause2,
    this.slopeUp,
    this.slopeDown,
    this.postHeatCurrent,
    this.postHeatTime,
    this.pause3,
    this.cyclePause = 0.5,
  });
}