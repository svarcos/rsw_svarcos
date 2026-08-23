/// Модуль расчёта параметров точечной сварки для алюминиево-магниевых сплавов
///
/// Выполняет расчёт всех параметров сварочного цикла на основе:
/// - данных из MaterialRepository
/// - пользовательского ввода (толщина, рабочий ход электродов)
/// - формул пересчёта из таблицы 4
///
/// Возвращает готовый объект CalculatedParameters.

import 'dart:math';

import '../../data/datasources/material_repository.dart';
import '../../data/datasources/machine_specs.dart';
import '../../data/models/calculated_parameters.dart';

class CalculateParametersUseCase {
  /// Рассчитать параметры сварочного цикла для заданной толщины и хода электродов
  CalculatedParameters call({
    required double thickness,
    required double stroke,
  }) {
    // ---- 0. ВАЛИДАЦИЯ ВХОДНЫХ ДАННЫХ ----
    // Диапазон толщин: 0.5 – 3.0 мм
    if (thickness < 0.5 || thickness > 3.0) {
      throw Exception('Толщина должна быть в диапазоне 0.5–3.0 мм');
    }

    // Диапазон рабочего хода: 5 – 150 мм
    if (stroke < 5.0 || stroke > 150.0) {
      throw Exception('Рабочий ход должен быть в диапазоне 5–150 мм');
    }

    // ---- 1. Получаем данные из репозитория ----
    final (power, weld, forgeTime) = MaterialRepository.interpolate(thickness);

    // ---- 2. Расчёт производных параметров по формулам ----

    // Диаметр литого ядра (с округлением вверх до целого)
    final nuggetDiameter = ((3 * thickness + 2) * 0.9).ceilToDouble();

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

    // COLD 3 = 0,25 × tков (математическое округление)
    final cold3 = (0.25 * forgeTime).roundToDouble();

    // POST-WELD = 0.8 × WELD (только если толщина >= 0.5)
    final postWeld = thickness >= 0.5 ? 0.8 * weld : 0.0;

    // POST-POWER = 0.45 × POWER (только если толщина >= 0.5)
    final postPower = thickness >= 0.5 ? 0.45 * power : 0.0;

    // HOLD TIME = 0,75 × tков (математическое округление)
    final holdTime = (0.75 * forgeTime).roundToDouble();

    // ---- 3. Возвращаем результат ----
    return CalculatedParameters(
      thickness: thickness,
      stroke: stroke,
      power: power,
      weld: weld,
      forgeTimeTable: forgeTime,
      nuggetDiameter: nuggetDiameter,
      pressure: pressure,
      squeeze1: squeeze1,
      forgePressure: forgePressure,
      forgeDelay: forgeDelay,
      cold3: cold3,
      postWeld: postWeld,
      postPower: postPower,
      holdTime: holdTime,
    );
  }
}