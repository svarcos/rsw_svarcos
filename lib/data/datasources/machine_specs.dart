/// Технические характеристики сварочной машины Tecna ING-132
class MachineSpecs {
  /// Скорость перемещения электродов, мм/имп
  /// v = velocity, стандартное значение для пневматических систем
  static const double electrodeVelocity = 2.5;

  /// Скорость изменения давления, бар/имп
  /// Определяет время нарастания/спада давления в пневмосистеме
  static const double pressureRiseRate = 0.3;

  /// Вторичный ток короткого замыкания, кА
  static const double shortCircuitCurrent = 106.0;

  /// Максимальное усилие электродов, бар
  static const double maxPressure = 6.0;

  /// Максимальный рабочий ход электродов, мм
  static const double maxStroke = 150.0;

  /// Минимальный рабочий ход электродов, мм
  static const double minStroke = 5.0;
}