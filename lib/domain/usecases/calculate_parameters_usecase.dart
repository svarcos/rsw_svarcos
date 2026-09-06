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

    // Диаметр литого ядра (информационный параметр)
    final nuggetDiameter = ((3 * thickness + 2) * 0.9).ceilToDouble();

    // PRESSURE = S (наименьшая толщина)
    final pressure = thickness;

    // SQUEEZE 1 = d / electrodeVelocity + PRESSURE / pressureRiseRate + 6
    final squeeze1 = stroke / MachineSpecs.electrodeVelocity +
        pressure / MachineSpecs.pressureRiseRate + 6;

    // FORG.PRESS. = 2 × PRESSURE (ограничение 6.0 бар)
    final forgePressure = thickness < 0.8
        ? pressure
        : (2 * pressure).clamp(0.0, MachineSpecs.maxPressure);

    // FORGE DELAY = SLOPE UP + WELD + SLOPE DOWN − (FORG.PRESS. − PRESSURE) / pressureRiseRate
    // Если значение < 0 — FORGE DELAY = 0
    // Округляем до ближайшего целого (циклы)
    final slopeUp = 0.0;
    final slopeDown = 0.0;
    final forgeDelay = (slopeUp + weld + slopeDown - (forgePressure - pressure) / MachineSpecs.pressureRiseRate)
        .clamp(0.0, double.infinity)
        .round();

    // COLD 3 = 0.25 × tков (округляем до ближайшего целого)
    final cold3 = (0.25 * forgeTime).roundToDouble();

    // POST-WELD = 0.8 × WELD (только если толщина >= 0.5, что всегда верно)
    final postWeld = 0.8 * weld;

    // POST-POWER = 0.45 × POWER (округление до целого, диапазон 5–99)
    final postPower = (0.45 * power).round().clamp(5, 99);

    // HOLD TIME = 0.75 × tков (округляем до ближайшего целого)
    final holdTime = (0.75 * forgeTime).roundToDouble();

    // ---- 3. OFF TIME (минимальное допустимое значение) ----
    // OFF TIME — это пауза между циклами, устанавливается оператором вручную.
    // Но она не может быть меньше времени спада давления.
    // Время спада давления:
    // - если есть FORG.PRESS. → FORG.PRESS. / 0.3
    // - если нет FORG.PRESS. → PRESSURE / 0.3
    // Округляем до целого числа (ceil), чтобы гарантировать, что offTime >= времени спада.
    final decayPressure = thickness >= 0.8 ? forgePressure : pressure;
    final offTime = (decayPressure / MachineSpecs.pressureRiseRate).ceilToDouble();

    // ---- 4. ВАЛИДАЦИЯ РАССЧИТАННЫХ ПАРАМЕТРОВ ----
    // Проверка: FORG.PRESS. не должен быть меньше PRESSURE
    if (forgePressure < pressure) {
      throw Exception('FORG.PRESS. не может быть меньше PRESSURE');
    }

    // ---- 5. ПРИВЕДЕНИЕ К ТИПАМ И ОГРАНИЧЕНИЕ ДИАПАЗОНОВ ----
    // Все параметры приводятся к нужному типу и ограничиваются допустимыми диапазонами
    final clampedPower = power.round().clamp(5, 99);
    final clampedWeld = weld.clamp(0.5, 99.5);
    final clampedPressure = pressure.clamp(0.5, 10.0);
    final clampedSqueeze1 = squeeze1.clamp(0.5, 99.5);
    final clampedForgePressure = forgePressure.clamp(0.0, 10.0);
    final clampedCold3 = cold3.clamp(0.0, 50.0);
    final clampedPostWeld = postWeld.clamp(0.0, 99.5);
    final clampedHoldTime = holdTime.clamp(0.5, 99.5);
    final clampedOffTime = offTime.clamp(0.0, 99.5);
    final clampedForgeDelay = forgeDelay.clamp(0, 99);
    final clampedPostPower = postPower.clamp(5, 99);

    // ---- 6. Возвращаем результат ----
    return CalculatedParameters(
      thickness: thickness,
      stroke: stroke,
      power: clampedPower,
      weld: clampedWeld,
      forgeTimeTable: forgeTime,
      nuggetDiameter: nuggetDiameter,
      pressure: clampedPressure,
      squeeze1: clampedSqueeze1,
      forgePressure: clampedForgePressure,
      forgeDelay: clampedForgeDelay,
      cold3: clampedCold3,
      postWeld: clampedPostWeld,
      postPower: clampedPostPower,
      holdTime: clampedHoldTime,
      offTime: clampedOffTime,
    );
  }
}