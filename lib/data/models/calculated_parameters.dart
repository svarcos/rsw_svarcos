/// Модель рассчитанных параметров сварочного цикла
/// Содержит все параметры, необходимые для построения циклограммы
/// и передачи данных из расчётного модуля в UI

class CalculatedParameters {
  // ---- ИСХОДНЫЕ ДАННЫЕ ----
  
  /// Толщина детали, мм
  final double thickness;
  
  /// Рабочий ход электродов, мм (вводится пользователем)
  final double stroke;
  
  // ---- ТАБЛИЧНЫЕ ПАРАМЕТРЫ (из справочника) ----
  
  /// POWER, % — сварочный ток в процентах
  final double power;
  
  /// WELD, имп — время сварки в импульсах
  final double weld;
  
  /// tков, имп — время ковки в импульсах
  final double forgeTimeTable;
  
  // ---- РАССЧИТАННЫЕ ПАРАМЕТРЫ ----
  
  /// Диаметр литого ядра, мм
  final double nuggetDiameter;
  
  /// PRESSURE, бар — давление/усилие сжатия электродов
  final double pressure;
  
  /// SQUEEZE 1, имп — время сжатия электродов
  final double squeeze1;
  
  /// FORG.PRESS., бар — давление/усилие ковки
  final double forgePressure;
  
  /// FORGE DELAY, имп — задержка включения давления/усилия ковки
  final double forgeDelay;
  
  /// COLD 3, имп — пауза между сваркой и дополнительной операцией
  final double cold3;
  
  /// POST-WELD, имп — время дополнительной операции после сварки
  final double postWeld;
  
  /// POST-POWER, % — мощность/ток дополнительной операции после сварки
  final double postPower;
  
  /// HOLD TIME, имп — время удержания усилия/давления ковки
  final double holdTime;

  // ---- КОНСТРУКТОР ----
  
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
  });

  // ---- ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ----
  
  /// Возвращает карту параметров для удобного отображения в UI
  Map<String, dynamic> toMap() {
    return {
      'thickness': thickness,
      'stroke': stroke,
      'power': power,
      'weld': weld,
      'forgeTimeTable': forgeTimeTable,
      'nuggetDiameter': nuggetDiameter,
      'pressure': pressure,
      'squeeze1': squeeze1,
      'forgePressure': forgePressure,
      'forgeDelay': forgeDelay,
      'cold3': cold3,
      'postWeld': postWeld,
      'postPower': postPower,
      'holdTime': holdTime,
    };
  }

  @override
  String toString() {
    return 'CalculatedParameters(\n'
        '  thickness: $thickness,\n'
        '  stroke: $stroke,\n'
        '  power: $power,\n'
        '  weld: $weld,\n'
        '  forgeTimeTable: $forgeTimeTable,\n'
        '  nuggetDiameter: $nuggetDiameter,\n'
        '  pressure: $pressure,\n'
        '  squeeze1: $squeeze1,\n'
        '  forgePressure: $forgePressure,\n'
        '  forgeDelay: $forgeDelay,\n'
        '  cold3: $cold3,\n'
        '  postWeld: $postWeld,\n'
        '  postPower: $postPower,\n'
        '  holdTime: $holdTime,\n'
        ')';
  }
}