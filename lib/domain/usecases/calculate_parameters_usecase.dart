/// Модуль расчёта параметров точечной сварки для алюминиево-магниевых сплавов
///
/// Выполняет расчёт всех параметров сварочного цикла на основе:
/// - табличных данных из MaterialRepository
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
    // ---- 1. Получаем табличные данные ----
    final material = MaterialRepository.getMaterial(thickness);
    if (material == null) {
      throw Exception('Нет данных для толщины $thickness мм');
    }

    final power = material.power;           // POWER, %
    final weld = material.weld;             // WELD, имп
    final forgeTimeTable = material.forgeTime; // tков, имп

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
    final cold3 = 0.25 * forgeTimeTable;

    // POST-WELD = 0.8 × WELD
    final postWeld = 0.8 * weld;

    // POST-POWER = 0.45 × POWER
    final postPower = 0.45 * power;

    // HOLD TIME = 0,75 × tков
    final holdTime = 0.75 * forgeTimeTable;

    // ---- 3. Возвращаем результат ----
    return CalculatedParameters(
      thickness: thickness,
      stroke: stroke,
      power: power,
      weld: weld,
      forgeTimeTable: forgeTimeTable,
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