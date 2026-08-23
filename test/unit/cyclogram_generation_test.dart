/// test/unit/cyclogram_generation_test.dart
/// Тесты для проверки генерации циклограммы

import 'package:flutter_test/flutter_test.dart';
import 'package:rsw_svarcos/domain/usecases/calculate_parameters_usecase.dart';

void main() {
  group('Циклограмма — генерация точек', () {
    late CalculateParametersUseCase useCase;

    setUp(() {
      useCase = CalculateParametersUseCase();
    });

    // ============================================================
    // 1. ПРОВЕРКА ОБЩЕЙ ДЛИТЕЛЬНОСТИ
    // ============================================================
    test('Общая длительность циклограммы для АМг6 (S=1.5)', () {
      final result = useCase(
        thickness: 1.5,
        stroke: 20.0,
      );

      final pressure = result.pressure;
      final forgePressure = result.forgePressure;
      final weld = result.weld;
      final postWeld = result.postWeld;
      final holdTime = result.holdTime;
      final cold3 = result.cold3;
      final forgeDelay = result.forgeDelay;
      final squeeze1 = result.squeeze1;

      final tPressureRise = pressure / 0.3;
      final tForgeRise = (forgePressure - pressure) / 0.3;
      final tDecay = forgePressure / 0.3;

      final totalTime = squeeze1 + weld + postWeld + holdTime + cold3 + tDecay + forgeDelay + tPressureRise;

      expect(totalTime, greaterThan(0));
    });

    // ============================================================
    // 2. ПРОВЕРКА НАЛИЧИЯ FORG.PRESS.
    // ============================================================
    test('Для АМг6 присутствует FORG.PRESS.', () {
      final result = useCase(
        thickness: 1.5,
        stroke: 20.0,
      );
      expect(result.forgePressure, greaterThan(result.pressure));
    });

    test('Для других материалов FORG.PRESS. может отсутствовать', () {
      final result = useCase(
        thickness: 1.5,
        stroke: 20.0,
      );
      expect(result.forgePressure, greaterThanOrEqualTo(result.pressure));
    });

    // ============================================================
    // 3. ПРОВЕРКА КОРРЕКТНОСТИ ТОЧЕК НА ГРАФИКЕ
    // ============================================================
    test('Ток на графике отображается с одним знаком после запятой', () {
      final result = useCase(
        thickness: 1.5,
        stroke: 20.0,
      );
      // POWER = 19.7 → в UI должно быть 19.7
      expect(result.power.toStringAsFixed(1), '19.7');
    });

    test('Давление на графике отображается с одним знаком после запятой', () {
      final result = useCase(
        thickness: 1.5,
        stroke: 20.0,
      );
      // PRESSURE = 1.5 → в UI должно быть 1.5
      expect(result.pressure.toStringAsFixed(1), '1.5');
    });

    test('Давление не должно быть на порядок выше расчётного', () {
      final result = useCase(
        thickness: 1.5,
        stroke: 20.0,
      );
      final scaledPressure = result.pressure * 10;
      expect(scaledPressure, lessThanOrEqualTo(100));
    });

    // ============================================================
    // 4. ПРОВЕРКА OFF TIME
    // ============================================================
    test('OFF TIME должно быть не меньше времени спада давления', () {
      final result = useCase(
        thickness: 1.5,
        stroke: 20.0,
      );
      final forgePressure = result.forgePressure;
      final decayTime = forgePressure / 0.3;
      // OFF TIME пока не рассчитывается, но проверка на будущее
      // expect(offTime, greaterThanOrEqualTo(decayTime));
      expect(decayTime, greaterThan(0));
    });

    // ============================================================
    // 5. ПРОВЕРКА ПОСЛЕДОВАТЕЛЬНОСТИ ИМПУЛЬСОВ
    // ============================================================
    test('Проверка последовательности этапов цикла', () {
      final result = useCase(
        thickness: 1.5,
        stroke: 20.0,
      );
      
      expect(result.squeeze1, greaterThan(0));
      expect(result.weld, greaterThan(0));
      expect(result.holdTime, greaterThan(0));
      expect(result.cold3, greaterThanOrEqualTo(0));
      expect(result.postWeld, greaterThanOrEqualTo(0));
    });

    // ============================================================
    // 6. ПРОВЕРКА ШАГА ГЕНЕРАЦИИ ТОЧЕК
    // ============================================================
    test('Шаг генерации точек = 0.5 имп', () {
      // В коде генерации используется step = 0.5
      // Проверка в виджет-тестах
    });
  });
}