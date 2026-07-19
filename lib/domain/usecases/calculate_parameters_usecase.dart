/// Модуль расчёта параметров точечной сварки

import 'dart:math';

import '../../data/datasources/material_repository.dart';
import '../../data/models/calculated_parameters.dart';

class CalculateParametersUseCase {
  CalculatedParameters call({
    required String materialName,
    required double thickness,
  }) {
    final material = MaterialRepository.getMaterial(materialName);
    if (material == null) {
      throw Exception('Материал "$materialName" не найден в справочнике');
    }

    if (thickness < material.minThickness || thickness > material.maxThickness) {
      throw Exception(
        'Толщина ${thickness} мм выходит за допустимый диапазон '
        'для материала ${materialName} (${material.minThickness}–${material.maxThickness} мм)',
      );
    }

    final nuggetDiameter = _calculateNuggetDiameter(thickness, material);

    final pressure = calculatePressure(nuggetDiameter);
    final forgePressure = calculateForgePressure(nuggetDiameter);
    final weldingCurrent = calculateWeldingCurrent(nuggetDiameter);
    final weldTime = calculateWeldTime(nuggetDiameter);
    final forgeDelay = calculateForgeDelay(nuggetDiameter);

    // Заглушки
    const squeezeTime = 0.5;
    const impulseCount = 1;
    const cyclePause = 0.5;

    return CalculatedParameters(
      material: materialName,
      thickness: thickness,
      nuggetDiameter: nuggetDiameter,
      weldingForce: pressure,
      weldingCurrent: weldingCurrent,
      weldingTime: weldTime.toDouble(),
      squeezeTime: squeezeTime,
      forgeTime: forgeDelay.toDouble(),
      preheatCurrent: null,
      preheatTime: null,
      pause1: null,
      impulseCount: impulseCount,
      pause2: null,
      slopeUp: null,
      slopeDown: null,
      postHeatCurrent: null,
      postHeatTime: null,
      pause3: null,
      cyclePause: cyclePause,
    );
  }

  double calculatePressure(double nuggetDiameter) {
    return 0.025 * nuggetDiameter * nuggetDiameter;
  }

  double calculateForgePressure(double nuggetDiameter) {
    return 0.043 * nuggetDiameter * nuggetDiameter;
  }

  double calculateWeldingCurrent(double nuggetDiameter) {
    return 0.6 * nuggetDiameter * nuggetDiameter;
  }

  int calculateWeldTime(double nuggetDiameter) {
    final value = 0.2 * pow(nuggetDiameter, 1.5);
    return value.ceil();
  }

  int calculateForgeDelay(double nuggetDiameter) {
    final value = 0.55 * nuggetDiameter;
    return value.ceil();
  }

  double _calculateNuggetDiameter(double thickness, MaterialData material) {
    if (material.group == 'aluminum') {
      return 2.0 + 3.0 * thickness;
    }
    return 1.75 + 2.5 * thickness;
  }
}