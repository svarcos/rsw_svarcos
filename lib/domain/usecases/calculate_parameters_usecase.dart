/// Модуль расчёта параметров точечной сварки для алюминиево-магниевых сплавов
///
/// Выполняет расчёт всех параметров сварочного цикла на основе:
/// - данных из MaterialRepository
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
    // ---- 1. Получаем данные из репозитория ----
    final (power, weld, forgeTime) = MaterialRepository.calculateForThickness(
      material: material,
      thickness: thickness,
    );

    // ---- 2. Расчёт производных параметров по формулам ----

    // Диаметр литого ядра
    final nuggetDiameter = (3 * thickness + 2) * 0.9;

    // PRESSURE = S (наименьшая толщина)
    final pressure = thickness;

    // SQUEEZE 1 = d / electrodeVelocity + PRESSURE / pressureRiseRate + 6
    final squeeze1 = stroke / MachineSpecs.electrodeVelocity +
        pressure / MachineSpecs.pressureRiseRate + 6;

    // ---- РАСЧЁТ FORG.PRESS. И FORGE DELAY ----
    // FORG.PRESS. = 2 × PRESSURE (ограничение 6.0 бар)
    // Если S < 0.8, то FORG.PRESS. = PRESSURE (ковка отключена, но давление сохраняется)
    double forgePressure;
    if (thickness < 0.8) {
      forgePressure = pressure; // вместо 0.0
    } else {
      forgePressure = (2 * pressure).clamp(0.0, MachineSpecs.maxPressure);
    }

    // FORGE DELAY = SLOPE UP + WELD + SLOPE DOWN − (FORG.PRESS. − PRESSURE) / pressureRiseRate
    // Если S < 0.8, то FORGE DELAY = 0
    // Иначе если значение < 1, то FORGE DELAY = 1
    final slopeUp = 0.0;
    final slopeDown = 0.0;
    double forgeDelay;
    if (thickness < 0.8) {
      forgeDelay = 0.0;
    } else {
      forgeDelay = (slopeUp + weld + slopeDown - (forgePressure - pressure) / MachineSpecs.pressureRiseRate);
      if (forgeDelay < 1) {
        forgeDelay = 1;
      }
    }

    // ---- ЛОГИКА: ЕСЛИ FORGE DELAY = 0, ТО FORG.PRESS. = PRESSURE ----
    // Это соответствует поведению блока управления:
    // если задержка равна 0, то проковка отключена, но давление остаётся PRESSURE
    if (forgeDelay == 0) {
      forgePressure = pressure;
    }

    // ---- ОСТАЛЬНЫЕ ПАРАМЕТРЫ ----
    // COLD 3 = 0,25 × tков
    final cold3 = 0.25 * forgeTime;

    // POST-WELD = 0.8 × WELD (только если толщина >= 0.5)
    final postWeld = thickness >= 0.5 ? 0.8 * weld : 0.0;

    // POST-POWER = 0.45 × POWER (только если толщина >= 0.5)
    final postPower = thickness >= 0.5 ? 0.45 * power : 0.0;

    // HOLD TIME = 0,75 × tков
    final holdTime = 0.75 * forgeTime;

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