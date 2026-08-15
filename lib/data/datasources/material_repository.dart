/// Справочник материалов для расчёта параметров точечной сварки
/// Данные по ГОСТ 15878-79 и отраслевым нормалям
///
/// Хранит коэффициенты квадратичной аппроксимации (полином 2-й степени)
/// для табличных значений: POWER, WELD, tForge (время ковки).
/// Формула: y = a * S^2 + b * S + c, где S — толщина детали.
///
/// Коэффициенты рассчитаны методом наименьших квадратов
/// на основе табличных данных для АМг6 (0.3–3.0 мм).

class MaterialRepository {
  /// Коэффициенты для АМг6 (0.3–3.0 мм)
  /// Рассчитаны методом наименьших квадратов
  static final Map<String, Map<String, List<double>>> _coefficients = {
    'АМг6': {
      'power': [1.2814, 10.9110, 2.4220],
      'weld': [0.7967, 1.8631, 1.1280],
      'forge': [
        // tForge = 0 при S < 0.8, иначе -7.2813*S^2 + 37.4375*S - 41.2813
        -7.2813, 37.4375, -41.2813
      ],
    },
  };

  /// Рассчитать параметры для заданного материала и толщины
  static (double power, double weld, double forgeTime) calculateForThickness({
    required String material,
    required double thickness,
  }) {
    final materialCoeffs = _coefficients[material];
    if (materialCoeffs == null) {
      throw Exception('Материал "$material" не найден в справочнике');
    }

    final powerCoeffs = materialCoeffs['power']!;
    final weldCoeffs = materialCoeffs['weld']!;
    final forgeCoeffs = materialCoeffs['forge']!;

    final power = powerCoeffs[0] * thickness * thickness + powerCoeffs[1] * thickness + powerCoeffs[2];
    final weld = weldCoeffs[0] * thickness * thickness + weldCoeffs[1] * thickness + weldCoeffs[2];

    // tForge: если толщина < 0.8, то 0, иначе по формуле
    double forgeTime;
    if (thickness < 0.8) {
      forgeTime = 0.0;
    } else {
      forgeTime = forgeCoeffs[0] * thickness * thickness + forgeCoeffs[1] * thickness + forgeCoeffs[2];
    }

    return (power, weld, forgeTime);
  }

  /// Возвращает список всех доступных материалов
  static List<String> getAvailableMaterials() {
    return _coefficients.keys.toList();
  }
}