import 'package:flutter_test/flutter_test.dart';
import 'package:rsw_svarcos/domain/usecases/calculate_parameters_usecase.dart';
import 'package:rsw_svarcos/data/datasources/material_repository.dart';
import 'package:rsw_svarcos/data/datasources/machine_specs.dart';

void main() {
  group('Расчётный модуль CalculateParametersUseCase', () {
    late CalculateParametersUseCase useCase;

    setUp(() {
      useCase = CalculateParametersUseCase();
    });

    // ============================================================
    // 1. ТЕСТЫ ПОЛИНОМОВ (опорные точки)
    // ============================================================
    group('Проверка табличных значений (опорные точки)', () {
      final testCases = {
        0.5: [6.0, 2.5, 0.0],
        0.8: [9.1, 3.5, 4.0],
        1.0: [14.2, 4.5, 4.5],
        1.5: [19.7, 6.0, 7.0],
        2.0: [27.9, 7.5, 8.0],
        2.5: [37.6, 9.5, 10.0],
        3.0: [43.6, 11.5, 12.0],
      };

      test('Проверка POWER, WELD, tForge в опорных точках', () {
        for (var entry in testCases.entries) {
          final thickness = entry.key;
          final expected = entry.value;
          final result = useCase(
            material: 'АМг6',
            thickness: thickness,
            stroke: 20.0,
          );

          expect(result.power, closeTo(expected[0], 0.01));
          expect(result.weld, closeTo(expected[1], 0.01));
          expect(result.forgeTimeTable, closeTo(expected[2], 0.01));
        }
      });
    });

    // ============================================================
    // 2. ТЕСТЫ ИНТЕРПОЛЯЦИИ (промежуточные точки)
    // ============================================================
    group('Проверка интерполяции', () {
      final interpolationCases = {
        0.6: [6.83, 2.85, 0.0],
        0.9: [11.59, 3.99, 4.39],
        1.1: [16.11, 4.92, 4.81],
        1.3: [17.94, 5.49, 5.97],
        1.7: [22.46, 6.55, 7.52],
        2.2: [31.88, 8.26, 8.68],
        2.7: [40.54, 10.31, 10.83],
      };

      test('Проверка интерполяции для промежуточных толщин', () {
        for (var entry in interpolationCases.entries) {
          final thickness = entry.key;
          final result = useCase(
            material: 'АМг6',
            thickness: thickness,
            stroke: 20.0,
          );

          expect(result.power, greaterThan(0));
          expect(result.weld, greaterThan(0));
          expect(result.forgeTimeTable, greaterThanOrEqualTo(0));

          // Проверка плавности: для 0.6 между 0.5 и 0.8
          if (thickness == 0.6) {
            final result05 = useCase(
              material: 'АМг6',
              thickness: 0.5,
              stroke: 20.0,
            );
            final result08 = useCase(
              material: 'АМг6',
              thickness: 0.8,
              stroke: 20.0,
            );
            expect(result.power, greaterThan(result05.power));
            expect(result.power, lessThan(result08.power));
          }
        }
      });
    });

    // ============================================================
    // 3. ТЕСТЫ ФОРМУЛ
    // ============================================================
    group('Формулы расчёта', () {
      test('PRESSURE = S (наименьшая толщина)', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 1.5,
          stroke: 20.0,
        );
        expect(result.pressure, 1.5);
      });

      test('FORG.PRESS. = 2 × PRESSURE (ограничение 6.0)', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 3.0,
          stroke: 20.0,
        );
        expect(result.forgePressure, 6.0);
      });

      test('tForge = 0 при S < 0.8', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 0.5,
          stroke: 20.0,
        );
        expect(result.forgeTimeTable, 0.0);
      });

      test('POST-WELD и POST-POWER = 0 при S < 0.5', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 0.3,
          stroke: 20.0,
        );
        expect(result.postWeld, 0.0);
        expect(result.postPower, 0.0);
      });

      test('POST-WELD и POST-POWER рассчитываются при S >= 0.5', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 0.5,
          stroke: 20.0,
        );
        expect(result.postWeld, greaterThan(0));
        expect(result.postPower, greaterThan(0));
      });

      test('SQUEEZE 1 по формуле: stroke / 2.5 + PRESSURE / 0.3 + 6', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 1.5,
          stroke: 20.0,
        );
        final expected = 20.0 / 2.5 + 1.5 / 0.3 + 6;
        expect(result.squeeze1, closeTo(expected, 0.01));
      });

      test('FORGE DELAY: SLOPE UP + WELD + SLOPE DOWN − (FORG.PRESS. − PRESSURE) / 0.3', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 1.5,
          stroke: 20.0,
        );
        final expected = 0.0 + result.weld + 0.0 - (result.forgePressure - result.pressure) / 0.3;
        expect(result.forgeDelay, closeTo(expected, 0.01));
      });

      test('FORGE DELAY не может быть отрицательным', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 0.5,
          stroke: 20.0,
        );
        expect(result.forgeDelay, greaterThanOrEqualTo(0));
      });

      test('COLD 3 = 0.25 × tForge', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 1.5,
          stroke: 20.0,
        );
        expect(result.cold3, closeTo(0.25 * result.forgeTimeTable, 0.01));
      });

      test('HOLD TIME = 0.75 × tForge', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 1.5,
          stroke: 20.0,
        );
        expect(result.holdTime, closeTo(0.75 * result.forgeTimeTable, 0.01));
      });
    });

    // ============================================================
    // 4. ГРАНИЧНЫЕ ТЕСТЫ
    // ============================================================
    group('Граничные условия', () {
      test('Минимальная толщина 0.5 мм', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 0.5,
          stroke: 20.0,
        );
        expect(result.power, 6.0);
        expect(result.weld, 2.5);
        expect(result.forgeTimeTable, 0.0);
        expect(result.pressure, 0.5);
      });

      test('Максимальная толщина 3.0 мм', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 3.0,
          stroke: 20.0,
        );
        expect(result.power, 43.6);
        expect(result.weld, 11.5);
        expect(result.forgeTimeTable, 12.0);
        expect(result.forgePressure, 6.0);
      });

      test('Максимальный рабочий ход 50 мм', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 1.5,
          stroke: 50.0,
        );
        final expected = 50.0 / 2.5 + 1.5 / 0.3 + 6;
        expect(result.squeeze1, closeTo(expected, 0.01));
      });
    });

    // ============================================================
    // 5. ОТСУТСТВИЕ ДАННЫХ ДЛЯ ДРУГИХ МАТЕРИАЛОВ
    // ============================================================
    group('Обработка ошибок', () {
      test('Выбор материала с заглушкой (Сталь 20)', () {
        expect(
          () => useCase(
            material: 'Сталь 20',
            thickness: 1.0,
            stroke: 20.0,
          ),
          throwsException,
        );
      });
    });
  });
}