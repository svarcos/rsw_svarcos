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
    if (thickness < 0.5 || thickness > 3.0) {
      throw Exception('Толщина должна быть в диапазоне 0.5–3.0 мм');
    }

    if (stroke < 5.0 || stroke > 150.0) {
      throw Exception('Рабочий ход должен быть в диапазоне 5–150 мм');
    }

    // ---- 1. Получаем данные из репозитория ----
    final (power, weld, forgeTime) = MaterialRepository.interpolate(thickness);

    // ---- 2. Расчёт производных параметров по формулам ----

    final nuggetDiameter = ((3 * thickness + 2) * 0.9).ceilToDouble();

    final pressure = thickness;

    final squeeze1 = stroke / MachineSpecs.electrodeVelocity +
        pressure / MachineSpecs.pressureRiseRate + 6;

    final forgePressure = (2 * pressure).clamp(0.0, MachineSpecs.maxPressure);

    final slopeUp = 0.0;
    final slopeDown = 0.0;
    final forgeDelay = (slopeUp + weld + slopeDown - (forgePressure - pressure) / MachineSpecs.pressureRiseRate)
        .clamp(0.0, double.infinity);

    final cold3 = (0.25 * forgeTime).roundToDouble();

    final postWeld = thickness >= 0.5 ? 0.8 * weld : 0.0;

    final postPower = thickness >= 0.5 ? 0.45 * power : 0.0;

    final holdTime = (0.75 * forgeTime).roundToDouble();

    // ---- 3. РАСЧЁТ OFF TIME ----
    // OFF TIME = время спада давления (FORG.PRESS. / 0.3), но не менее 0.5 имп
    // Если ковка отсутствует (FORG.PRESS. == PRESSURE), используем PRESSURE / 0.3
    final decayTime = forgePressure / MachineSpecs.pressureRiseRate;
    final offTime = decayTime.clamp(0.5, double.infinity);

    // ---- 4. ВАЛИДАЦИЯ РАССЧИТАННЫХ ПАРАМЕТРОВ ----
    // Проверка: FORG.PRESS. не должен быть меньше PRESSURE
    if (forgePressure < pressure) {
      throw Exception('FORG.PRESS. не может быть меньше PRESSURE');
    }

    // Проверка: OFF TIME не должен быть меньше времени спада давления
    if (offTime < decayTime) {
      throw Exception('OFF TIME не может быть меньше времени спада давления');
    }

    // ---- 5. Возвращаем результат ----
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
      offTime: offTime,
    );
  }
}