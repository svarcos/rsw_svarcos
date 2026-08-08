/// Справочник материалов для расчёта параметров точечной сварки
/// Хранит коэффициенты квадратичной аппроксимации (полином 2-й степени)
/// для табличных значений: POWER, WELD, tForge (время ковки).
/// Формула: y = a * S^2 + b * S + c, где S — толщина детали.
///
/// Коэффициенты рассчитаны методом наименьших квадратов
/// на основе табличных данных для АМг6 (0.3–3.0 мм).

class MaterialData {
  /// Толщина детали, мм
  final double thickness;

  /// Коэффициенты для POWER (сварочный ток, %)
  final double powerA;
  final double powerB;
  final double powerC;

  /// Коэффициенты для WELD (время сварки, имп)
  final double weldA;
  final double weldB;
  final double weldC;

  /// Коэффициенты для tForge (время ковки, имп)
  final double forgeA;
  final double forgeB;
  final double forgeC;

  const MaterialData({
    required this.thickness,
    required this.powerA,
    required this.powerB,
    required this.powerC,
    required this.weldA,
    required this.weldB,
    required this.weldC,
    required this.forgeA,
    required this.forgeB,
    required this.forgeC,
  });

  /// Вычисляет значение параметра по формуле полинома 2-й степени
  double _calculate(double a, double b, double c) {
    return a * thickness * thickness + b * thickness + c;
  }

  /// Получить значение POWER для данной толщины
  double get power => _calculate(powerA, powerB, powerC);

  /// Получить значение WELD для данной толщины
  double get weld => _calculate(weldA, weldB, weldC);

  /// Получить значение tForge для данной толщины
  double get forgeTime => _calculate(forgeA, forgeB, forgeC);
}

/// Репозиторий для доступа к справочным данным материалов
class MaterialRepository {
  /// Коэффициенты для АМг6 (0.3–3.0 мм)
  /// Рассчитаны методом наименьших квадратов
  static final List<MaterialData> _materials = [
    // 0.3 мм
    const MaterialData(
      thickness: 0.3,
      powerA: 0.0, powerB: 0.0, powerC: 3.6,
      weldA: 0.0, weldB: 0.0, weldC: 1.5,
      forgeA: 0.0, forgeB: 0.0, forgeC: 0.0,
    ),
    // 0.5 мм
    const MaterialData(
      thickness: 0.5,
      powerA: 0.0, powerB: 0.0, powerC: 6.0,
      weldA: 0.0, weldB: 0.0, weldC: 2.5,
      forgeA: 0.0, forgeB: 0.0, forgeC: 0.0,
    ),
    // 0.8 мм
    const MaterialData(
      thickness: 0.8,
      powerA: 0.0, powerB: 0.0, powerC: 9.1,
      weldA: 0.0, weldB: 0.0, weldC: 3.5,
      forgeA: 0.0, forgeB: 0.0, forgeC: 4.0,
    ),
    // 1.0 мм
    const MaterialData(
      thickness: 1.0,
      powerA: 0.0, powerB: 0.0, powerC: 14.2,
      weldA: 0.0, weldB: 0.0, weldC: 4.5,
      forgeA: 0.0, forgeB: 0.0, forgeC: 4.5,
    ),
    // 1.5 мм
    const MaterialData(
      thickness: 1.5,
      powerA: 0.0, powerB: 0.0, powerC: 19.7,
      weldA: 0.0, weldB: 0.0, weldC: 6.0,
      forgeA: 0.0, forgeB: 0.0, forgeC: 7.0,
    ),
    // 2.0 мм
    const MaterialData(
      thickness: 2.0,
      powerA: 0.0, powerB: 0.0, powerC: 27.9,
      weldA: 0.0, weldB: 0.0, weldC: 7.5,
      forgeA: 0.0, forgeB: 0.0, forgeC: 8.0,
    ),
    // 2.5 мм
    const MaterialData(
      thickness: 2.5,
      powerA: 0.0, powerB: 0.0, powerC: 37.6,
      weldA: 0.0, weldB: 0.0, weldC: 9.5,
      forgeA: 0.0, forgeB: 0.0, forgeC: 10.0,
    ),
    // 3.0 мм
    const MaterialData(
      thickness: 3.0,
      powerA: 0.0, powerB: 0.0, powerC: 43.6,
      weldA: 0.0, weldB: 0.0, weldC: 11.5,
      forgeA: 0.0, forgeB: 0.0, forgeC: 12.0,
    ),
  ];

  /// Возвращает данные материала для заданной толщины
  static MaterialData? getMaterial(double thickness) {
    try {
      return _materials.firstWhere((m) => m.thickness == thickness);
    } catch (_) {
      return null;
    }
  }

  /// Возвращает список всех доступных толщин
  static List<double> getAvailableThicknesses() {
    return _materials.map((m) => m.thickness).toList();
  }

  /// Возвращает список всех материалов
  static List<MaterialData> getAllMaterials() {
    return _materials;
  }
}