/// Модуль расчёта параметров точечной сварки для алюминиево-магниевых сплавов
///
/// Выполняет расчёт всех параметров сварочного цикла на основе:
/// - интерполяции табличных данных из MaterialRepository
/// - пользовательского ввода (материал, толщина, рабочий ход электродов)
/// - формул пересчёта из таблицы 4
///
/// Возвращает готовый объект CalculatedParameters.

import 'dart:math';

import '../../data/datasources/material_repository.dart';
import '../../data/datasources/machine_specs.dart';
import '../../data/models/calculated_parameters.dart';

class CalculateParametersUseCase {
  /// Рассчитать параметры сварочного цикла для заданного материала, толщины и хода электродов
  CalculatedParameters call({
    required String material,
    required double thickness,
    required double stroke,
  }) {
    // ---- 0. Проверка, что материал существует ----
    if (!MaterialRepository.getAvailableMaterials().contains(material)) {
      throw Exception('Материал "$material" не найден в справочнике');
    }

    // ---- 1. Получаем данные из репозитория (интерполяция) ----
    final (power, weld, forgeTime) = MaterialRepository.interpolate(thickness);

    // ---- 2. Расчёт производных параметров по формулам ----

    // Диаметр литого ядра
    final nuggetDiameter = (3 * thickness + 2) * 0.9;

    // PRESSURE = S (наименьшая толщина)
    final pressure = thickness;

    // SQUEEZE 1 = d / electrodeVelocity + PRESSURE / pressureRiseRate + 6
    final squeeze1 = stroke / MachineSpecs.electrodeVelocity +
        pressure / MachineSpecs.pressureRiseRate + 6;

    // FORG.PRESS. = 2 × PRESSURE (ограничение 6.0 бар)
    final forgePressure = (2 * pressure).clamp(0.0, MachineSpecs.maxPressure);

    // FORGE DELAY = SLOPE UP + WELD + SLOPE DOWN − (FORG.PRESS. − PRESSURE) / pressureRiseRate
    // Если значение < 0 — FORGE DELAY = 0
    // SLOPE UP и SLOPE DOWN пока равны 0 (заглушка)
    final slopeUp = 0.0;
    final slopeDown = 0.0;
    final forgeDelay = (slopeUp + weld + slopeDown - (forgePressure - pressure) / MachineSpecs.pressureRiseRate)
        .clamp(0.0, double.infinity);

    // COLD 3 = 0,25 × tков
    final cold3 = 0.25 * forgeTime;

    // POST-WELD = 0.8 × WELD (только если толщина >= 0.5)
    final postWeld = thickness >= 0.5 ? 0.8 * weld : 0.0;

    // POST-POWER = 0.45 × POWER (только если толщина >= 0.5)
    final postPower = thickness >= 0.5 ? 0.45 * power : 0.0;

    // HOLD TIME = 0,75 × tков
    final holdTime = 0.75 * forgeTime;

    // ---- 3. Округление до нужной точности ----
    // Все временные параметры (импульсы) → математическое округление до целого
    // Ток, давление, толщина → математическое округление до 1 знака после запятой
    
    // Округление до 1 знака (для power, pressure, forgePressure, postPower)
    final powerRounded = (power * 10).roundToDouble() / 10;
    final pressureRounded = (pressure * 10).roundToDouble() / 10;
    final forgePressureRounded = (forgePressure * 10).roundToDouble() / 10;
    final postPowerRounded = (postPower * 10).roundToDouble() / 10;

    // Математическое округление до целых (для временных параметров)
    final weldRounded = weld.roundToDouble();
    final squeeze1Rounded = squeeze1.roundToDouble();
    final forgeDelayRounded = forgeDelay.roundToDouble();
    final cold3Rounded = cold3.roundToDouble();
    final postWeldRounded = postWeld.roundToDouble();
    final holdTimeRounded = holdTime.roundToDouble();

    // ---- 4. Возвращаем результат ----
    return CalculatedParameters(
      thickness: thickness,
      stroke: stroke,
      power: powerRounded,
      weld: weldRounded,
      forgeTimeTable: forgeTime,
      nuggetDiameter: nuggetDiameter,
      pressure: pressureRounded,
      squeeze1: squeeze1Rounded,
      forgePressure: forgePressureRounded,
      forgeDelay: forgeDelayRounded,
      cold3: cold3Rounded,
      postWeld: postWeldRounded,
      postPower: postPowerRounded,
      holdTime: holdTimeRounded,
    );
  }
}