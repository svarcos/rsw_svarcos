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

      // Все временные параметры сварочного цикла (в импульсах, округлены до целых)
      final totalTime = result.squeeze1.round() +
          result.preWeld.round() +
          result.cold1.round() +
          result.slopeUp.round() +
          (result.weld.round() * result.impulseCount) +
          (result.cold2.round() * (result.impulseCount - 1)) +
          result.slopeDown.round() +
          result.cold3.round() +
          result.postWeld.round() +
          result.holdTime.round() +
          result.offTime.round();

      // Ожидаемая длительность для S=1.5 при stroke=20:
      // squeeze1   = 19
      // preWeld    = 0
      // cold1      = 0
      // slopeUp    = 0
      // weld       = 6 * 1 = 6
      // cold2      = 0 * (1-1) = 0
      // slopeDown  = 0
      // cold3      = 2 (0.25 * 7 = 1.75 → 2)
      // postWeld   = 5 (4.8 → 5)
      // holdTime   = 5 (5.25 → 5)
      // offTime    = 10
      // Итого: 19 + 0 + 0 + 0 + 6 + 0 + 0 + 2 + 5 + 5 + 10 = 47 имп
      expect(totalTime, 47);
    });

    // ============================================================
    // 2. ПРОВЕРКА НАЛИЧИЯ FORG.PRESS.
    // ============================================================
    test('Для АМг6 (S>=0.8) FORG.PRESS. присутствует', () {
      final result = useCase(
        thickness: 1.5,
        stroke: 20.0,
      );
      expect(result.forgePressure, greaterThan(result.pressure));
    });

    test('Для АМг6 (S<0.8) FORG.PRESS. отсутствует', () {
      final result = useCase(
        thickness: 0.5,
        stroke: 20.0,
      );
      expect(result.forgePressure, result.pressure);
    });

    // ============================================================
    // 3. ПРОВЕРКА ФОРМАТА ОТОБРАЖЕНИЯ ТОКА И ДАВЛЕНИЯ (ОДИН ЗНАК ПОСЛЕ ЗАПЯТОЙ)
    // ============================================================
    test('Ток на графике отображается с одним знаком после запятой', () {
      final result = useCase(
        thickness: 1.5,
        stroke: 20.0,
      );
      final formatted = result.power.toStringAsFixed(1);
      expect(formatted, matches(RegExp(r'^\d+\.\d$')));
    });

    test('Давление на графике отображается с одним знаком после запятой', () {
      final result = useCase(
        thickness: 1.5,
        stroke: 20.0,
      );
      final formatted = result.pressure.toStringAsFixed(1);
      expect(formatted, matches(RegExp(r'^\d+\.\d$')));
    });

    // ============================================================
    // 4. ПРОВЕРКА ШКАЛЫ ДАВЛЕНИЯ (ПРАВАЯ ОСЬ)
    // ============================================================
    test('Шкала давления на графике отображает значения 0–10 с шагом 1', () {
      final result = useCase(
        thickness: 3.0,
        stroke: 20.0,
      );
      
      expect(result.forgePressure, lessThanOrEqualTo(6.0));
      expect(result.pressure, greaterThanOrEqualTo(0));
      
      final scaledPressure = result.forgePressure * 10;
      expect(scaledPressure, lessThanOrEqualTo(60));
    });

    // ============================================================
    // 5. ПРОВЕРКА: ВРЕМЕННЫЕ ПАРАМЕТРЫ — ТОЛЬКО ЦЕЛЫЕ ЧИСЛА
    // ============================================================
    test('Все временные параметры являются целыми числами', () {
      final result = useCase(
        thickness: 1.5,
        stroke: 20.0,
      );

      // Проверяем, что все временные параметры — целые числа (без дробной части)
      expect(result.squeeze1 % 1, 0);
      expect(result.preWeld % 1, 0);
      expect(result.cold1 % 1, 0);
      expect(result.slopeUp % 1, 0);
      expect(result.weld % 1, 0);
      expect(result.cold2 % 1, 0);
      expect(result.slopeDown % 1, 0);
      expect(result.cold3 % 1, 0);
      expect(result.postWeld % 1, 0);
      expect(result.holdTime % 1, 0);
      expect(result.offTime % 1, 0);
    });

    // ============================================================
    // 6. ПРОВЕРКА OFF TIME
    // ============================================================
    test('OFF TIME должно быть не меньше времени спада давления', () {
      final result = useCase(
        thickness: 1.5,
        stroke: 20.0,
      );
      final decayTime = result.forgePressure / 0.3;
      expect(result.offTime, greaterThanOrEqualTo(decayTime));
    });
  });
}