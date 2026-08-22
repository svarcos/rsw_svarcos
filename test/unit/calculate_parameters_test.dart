import 'package:flutter_test/flutter_test.dart';
import 'package:rsw_svarcos/domain/usecases/calculate_parameters_usecase.dart';

void main() {
  group('Расчётный модуль CalculateParametersUseCase', () {
    late CalculateParametersUseCase useCase;

    setUp(() {
      useCase = CalculateParametersUseCase();
    });

    // ============================================================
    // 1. ТЕСТЫ ТАБЛИЧНЫХ ЗНАЧЕНИЙ (опорные точки)
    // ============================================================
    group('Проверка табличных значений (опорные точки)', () {
      final testCases = {
        0.5: [6.0, 3.0, 0.0],    // WELD: 2.5 → 3 (мат. округление)
        0.8: [9.1, 4.0, 4.0],    // WELD: 3.5 → 4
        1.0: [14.2, 5.0, 4.5],   // WELD: 4.5 → 5
        1.5: [19.7, 6.0, 7.0],   // WELD: 6.0 → 6
        2.0: [27.9, 8.0, 8.0],   // WELD: 7.5 → 8
        2.5: [37.6, 10.0, 10.0], // WELD: 9.5 → 10
        3.0: [43.6, 12.0, 12.0], // WELD: 11.5 → 12
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

          expect(result.power, closeTo(expected[0], 0.1));
          expect(result.weld, expected[1]);
          expect(result.forgeTimeTable, closeTo(expected[2], 0.1));
        }
      });
    });

    // ============================================================
    // 2. ТЕСТЫ ИНТЕРПОЛЯЦИИ
    // ============================================================
    group('Проверка интерполяции', () {
      test('Интерполяция для промежуточных толщин', () {
        final result06 = useCase(
          material: 'АМг6',
          thickness: 0.6,
          stroke: 20.0,
        );
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

        // POWER: 0.6 должно быть между 0.5 и 0.8
        expect(result06.power, greaterThan(result05.power));
        expect(result06.power, lessThan(result08.power));

        // WELD: 0.6 должно быть между 0.5 и 0.8
        // Но из-за округления может быть равно 3.0 (как и в 0.5)
        // Поэтому проверяем, что оно не меньше и не больше
        expect(result06.weld, greaterThanOrEqualTo(result05.weld));
        expect(result06.weld, lessThanOrEqualTo(result08.weld));

        // tForge: 0.6 должно быть 0 (так как < 0.8)
        expect(result06.forgeTimeTable, 0.0);
      });

      test('Интерполяция для толщины 1.2', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 1.2,
          stroke: 20.0,
        );
        // Проверяем, что значения не выходят за пределы таблицы
        expect(result.power, greaterThan(14.0));
        expect(result.power, lessThan(20.0));
        // WELD: интерполяция между 4.5 и 6.0 → ~5.4 → мат. округление → 5
        expect(result.weld, greaterThanOrEqualTo(5.0));
        expect(result.weld, lessThanOrEqualTo(6.0));
        expect(result.forgeTimeTable, greaterThan(4.5));
        expect(result.forgeTimeTable, lessThan(7.0));
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

      test('FORG.PRESS. не превышает 6.0', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 3.0,
          stroke: 20.0,
        );
        expect(result.forgePressure, lessThanOrEqualTo(6.0));
      });

      test('tForge = 0 при S < 0.8', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 0.5,
          stroke: 20.0,
        );
        expect(result.forgeTimeTable, 0.0);
      });

      test('tForge > 0 при S >= 0.8', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 0.8,
          stroke: 20.0,
        );
        expect(result.forgeTimeTable, greaterThan(0));
      });

      test('POST-WELD и POST-POWER рассчитываются при S >= 0.5', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 0.5,
          stroke: 20.0,
        );
        // 0.8 * 2.5 = 2.0 → мат. округление → 2.0
        expect(result.postWeld, 2.0);
        // 0.45 * 6.0 = 2.7 → мат. округление до 1 знака → 2.7
        expect(result.postPower, closeTo(2.7, 0.1));
      });

      test('SQUEEZE 1 по формуле: stroke / 2.5 + PRESSURE / 0.3 + 6', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 1.5,
          stroke: 20.0,
        );
        final expected = (20.0 / 2.5 + 1.5 / 0.3 + 6).roundToDouble();
        expect(result.squeeze1, expected);
      });

      test('FORGE DELAY не может быть отрицательным', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 0.5,
          stroke: 20.0,
        );
        expect(result.forgeDelay, greaterThanOrEqualTo(0));
      });

      test('COLD 3 = 0.25 × tForge (мат. округление)', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 1.5,
          stroke: 20.0,
        );
        // 0.25 * 7.0 = 1.75 → мат. округление → 2.0
        expect(result.cold3, 2.0);
      });

      test('HOLD TIME = 0.75 × tForge (мат. округление)', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 1.5,
          stroke: 20.0,
        );
        // 0.75 * 7.0 = 5.25 → мат. округление → 5.0
        expect(result.holdTime, 5.0);
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
        expect(result.weld, 3.0);
        expect(result.forgeTimeTable, 0.0);
        expect(result.pressure, 0.5);
        expect(result.forgePressure, 1.0);
      });

      test('Максимальная толщина 3.0 мм', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 3.0,
          stroke: 20.0,
        );
        expect(result.power, 43.6);
        expect(result.weld, 12.0);
        expect(result.forgeTimeTable, 12.0);
        expect(result.pressure, 3.0);
        expect(result.forgePressure, 6.0);
      });

      test('Максимальный рабочий ход 50 мм', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 1.5,
          stroke: 50.0,
        );
        final expected = (50.0 / 2.5 + 1.5 / 0.3 + 6).roundToDouble();
        expect(result.squeeze1, expected);
      });

      test('Минимальный рабочий ход 5 мм', () {
        final result = useCase(
          material: 'АМг6',
          thickness: 1.5,
          stroke: 5.0,
        );
        final expected = (5.0 / 2.5 + 1.5 / 0.3 + 6).roundToDouble();
        expect(result.squeeze1, expected);
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

      test('Выбор материала с заглушкой (12Х18Н10Т)', () {
        expect(
          () => useCase(
            material: '12Х18Н10Т',
            thickness: 1.0,
            stroke: 20.0,
          ),
          throwsException,
        );
      });
    });

    // ============================================================
    // 6. РЕГРЕССИЯ: ПРОВЕРКА ВСЕХ ОПОРНЫХ ТОЧЕК
    // ============================================================
    group('Регрессионные тесты (все опорные точки)', () {
      final testCases = {
        0.5: [6.0, 3.0, 0.0],
        0.8: [9.1, 4.0, 4.0],
        1.0: [14.2, 5.0, 4.5],
        1.5: [19.7, 6.0, 7.0],
        2.0: [27.9, 8.0, 8.0],
        2.5: [37.6, 10.0, 10.0],
        3.0: [43.6, 12.0, 12.0],
      };

      test('Прогон всех опорных точек', () {
        for (var entry in testCases.entries) {
          final thickness = entry.key;
          final expected = entry.value;
          final result = useCase(
            material: 'АМг6',
            thickness: thickness,
            stroke: 20.0,
          );

          expect(result.power, closeTo(expected[0], 0.1),
              reason: 'POWER для толщины $thickness');
          expect(result.weld, expected[1],
              reason: 'WELD для толщины $thickness');
          expect(result.forgeTimeTable, closeTo(expected[2], 0.1),
              reason: 'tForge для толщины $thickness');
        }
      });
    });
  });
}