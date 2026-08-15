// Модель данных для параметров сварочного цикла аппарата Tecna TE550
// Содержит все 19 параметров, которые пользователь может настраивать
// + новые поля для расчёта: материал, толщины, диаметр точки, рабочий ход электродов

class WeldingParameters {
  // ---- ОСНОВНЫЕ ПАРАМЕТРЫ СВАРОЧНОГО ЦИКЛА ----
  
  // Время подхода электродов (первая ступень сжатия)
  // Диапазон: 00.5 – 99.5 циклов
  final double squeeze1;
  
  // Установка усилия сжатия (при наличии датчика)
  // Диапазон: 00.5 – 10.0 bar
  final double pressure;
  
  // Задержка перед приложением усилия проковки
  // Диапазон: 00 – 99 циклов
  final int forgeDelay;
  
  // Установка усилия механической проковки
  // Диапазон: 00.5 – 10.0 bar
  final double forgePressure;
  
  // Длительность импульса предварительного подогрева
  // Диапазон: 00.0 – 99.5 циклов
  final double preWeld;
  
  // Мощность импульса предварительного подогрева
  // Диапазон: 05 – 99 %
  final int prePower;
  
  // Пауза между импульсом подогрева и основным
  // Диапазон: 00 – 50 циклов
  final int cold1;
  
  // Время плавного нарастания тока до заданного значения
  // Диапазон: 00 – 25 циклов
  final int slopeUp;
  
  // Длительность основного сварочного импульса
  // Диапазон: 00.5 – 99.5 циклов
  final double weld;
  
  // Мощность основного сварочного импульса
  // Диапазон: 05 – 99 %
  final int power;
  
  // Количество сварочных импульсов за один цикл
  // Диапазон: 01 – 09 (до 50 в режиме стыковой)
  final int impulseN;
  
  // Пауза между сварочными импульсами (при IMPULSE N. > 1)
  // Диапазон: 00 – 50 циклов
  final int cold2;
  
  // Время плавного спада тока после основного импульса
  // Диапазон: 00 – 25 циклов
  final int slopeDown;
  
  // Пауза между основным импульсом и импульсом подогрева перед проковкой
  // Диапазон: 00 – 50 циклов
  final int cold3;
  
  // Длительность импульса подогрева перед проковкой (электрическая проковка)
  // Диапазон: 00.0 – 99.5 циклов
  final double postWeld;
  
  // Мощность импульса подогрева перед проковкой (электрическая проковка)
  // Диапазон: 05 – 99 %
  final int postPower;
  
  // Время удержания электродов в сжатом состоянии после сварки
  // Диапазон: 00.5 – 99.5 циклов
  final double holdTime;
  
  // Пауза между завершением одного цикла и началом следующего
  // Диапазон: 00.0 – 99.5 циклов
  final double offTime;

  // ---- НОВЫЕ ПОЛЯ ДЛЯ РАСЧЁТА ----
  
  // Материал деталей (АМг6, Сталь 08кп и т.д.)
  final String material;
  
  // Толщина верхней детали (меньшая), мм
  // Диапазон: 0.3 – 3.0
  final double thicknessTop;
  
  // Толщина нижней детали (большая), мм
  // Диапазон: 0.3 – 3.0
  final double thicknessBottom;
  
  // Диаметр литого ядра (точки), мм
  // Расчётное значение, отображается только для информации
  final double nuggetDiameter;

  // Рабочий ход электродов, мм
  // Диапазон: 5 – 50 мм, шаг 5 мм
  final double stroke;

  // ---- КОНСТРУКТОР ----
  const WeldingParameters({
    required this.squeeze1,
    required this.pressure,
    required this.forgeDelay,
    required this.forgePressure,
    required this.preWeld,
    required this.prePower,
    required this.cold1,
    required this.slopeUp,
    required this.weld,
    required this.power,
    required this.impulseN,
    required this.cold2,
    required this.slopeDown,
    required this.cold3,
    required this.postWeld,
    required this.postPower,
    required this.holdTime,
    required this.offTime,
    this.material = 'АМг6',
    this.thicknessTop = 1.5,
    this.thicknessBottom = 1.5,
    this.nuggetDiameter = 3.5,
    this.stroke = 20.0,
  });

  // ---- ФАБРИЧНЫЙ КОНСТРУКТОР (значения по умолчанию) ----
  factory WeldingParameters.defaults() {
    return const WeldingParameters(
      squeeze1: 19.0,
      pressure: 1.5,
      forgeDelay: 1,
      forgePressure: 3.0,
      preWeld: 0.0,
      prePower: 50,
      cold1: 0,
      slopeUp: 0,
      weld: 6.0,
      power: 19,
      impulseN: 1,
      cold2: 0,
      slopeDown: 0,
      cold3: 2,
      postWeld: 4.8,
      postPower: 9,
      holdTime: 5.0,
      offTime: 0.0,
      material: 'АМг6',
      thicknessTop: 1.5,
      thicknessBottom: 1.5,
      nuggetDiameter: 3.5,
      stroke: 20.0,
    );
  }
}

// ---- РАСШИРЕНИЕ ДЛЯ COPYWITH ----
extension WeldingParametersExtension on WeldingParameters {
  WeldingParameters copyWith({
    double? squeeze1,
    double? pressure,
    int? forgeDelay,
    double? forgePressure,
    double? preWeld,
    int? prePower,
    int? cold1,
    int? slopeUp,
    double? weld,
    int? power,
    int? impulseN,
    int? cold2,
    int? slopeDown,
    int? cold3,
    double? postWeld,
    int? postPower,
    double? holdTime,
    double? offTime,
    String? material,
    double? thicknessTop,
    double? thicknessBottom,
    double? nuggetDiameter,
    double? stroke,
  }) {
    return WeldingParameters(
      squeeze1: squeeze1 ?? this.squeeze1,
      pressure: pressure ?? this.pressure,
      forgeDelay: forgeDelay ?? this.forgeDelay,
      forgePressure: forgePressure ?? this.forgePressure,
      preWeld: preWeld ?? this.preWeld,
      prePower: prePower ?? this.prePower,
      cold1: cold1 ?? this.cold1,
      slopeUp: slopeUp ?? this.slopeUp,
      weld: weld ?? this.weld,
      power: power ?? this.power,
      impulseN: impulseN ?? this.impulseN,
      cold2: cold2 ?? this.cold2,
      slopeDown: slopeDown ?? this.slopeDown,
      cold3: cold3 ?? this.cold3,
      postWeld: postWeld ?? this.postWeld,
      postPower: postPower ?? this.postPower,
      holdTime: holdTime ?? this.holdTime,
      offTime: offTime ?? this.offTime,
      material: material ?? this.material,
      thicknessTop: thicknessTop ?? this.thicknessTop,
      thicknessBottom: thicknessBottom ?? this.thicknessBottom,
      nuggetDiameter: nuggetDiameter ?? this.nuggetDiameter,
      stroke: stroke ?? this.stroke,
    );
  }
}