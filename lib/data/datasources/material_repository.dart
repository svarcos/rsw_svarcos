/// Справочник материалов для расчёта параметров точечной сварки
/// Данные по ОСТ 92-1115-79

class MaterialData {
  /// Толщина детали, мм
  final double thickness;

  /// POWER, % — сварочный ток в процентах (табличное значение)
  final double power;

  /// WELD, имп — время сварки в импульсах (табличное значение)
  final double weld;

  /// tков, имп — время ковки в импульсах (табличное значение)
  final double forgeTime;

  const MaterialData({
    required this.thickness,
    required this.power,
    required this.weld,
    required this.forgeTime,
  });
}

/// Репозиторий для доступа к справочным данным материалов
class MaterialRepository {
  static final List<MaterialData> _materials = [
    const MaterialData(
      thickness: 0.3,
      power: 3.6,
      weld: 1.5,
      forgeTime: 0,
    ),
    const MaterialData(
      thickness: 0.5,
      power: 6.0,
      weld: 2.5,
      forgeTime: 0,
    ),
    const MaterialData(
      thickness: 0.8,
      power: 9.1,
      weld: 3.5,
      forgeTime: 4.0,
    ),
    const MaterialData(
      thickness: 1.0,
      power: 14.2,
      weld: 4.5,
      forgeTime: 4.5,
    ),
    const MaterialData(
      thickness: 1.5,
      power: 19.7,
      weld: 6.0,
      forgeTime: 7.0,
    ),
    const MaterialData(
      thickness: 2.0,
      power: 27.9,
      weld: 7.5,
      forgeTime: 8.0,
    ),
    const MaterialData(
      thickness: 2.5,
      power: 37.6,
      weld: 9.5,
      forgeTime: 10.0,
    ),
    const MaterialData(
      thickness: 3.0,
      power: 43.6,
      weld: 11.5,
      forgeTime: 12.0,
    ),
  ];

  /// Возвращает данные материала по толщине
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