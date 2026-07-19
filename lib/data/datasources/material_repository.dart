/// Справочник материалов для расчёта параметров точечной сварки
/// Данные по ГОСТ 15878-79 и отраслевым нормалям

class MaterialData {
  final String name;
  final String group; // 'steel', 'aluminum', 'copper'
  final double kI; // Коэффициент для тока
  final double kt; // Коэффициент для времени сварки
  final double kF; // Коэффициент для усилия
  final double minThickness; // Минимальная толщина, мм
  final double maxThickness; // Максимальная толщина, мм
  final double resistivity; // Удельное сопротивление, мкОм·м
  final double thermalConductivity; // Теплопроводность, Вт/(м·К)
  final bool requirePreheat; // Требуется ли подогрев
  final bool requirePostHeat; // Требуется ли отпуск
  final double defaultSlopeUp; // Рекомендуемое время нарастания тока, с
  final double defaultSlopeDown; // Рекомендуемое время спада тока, с

  const MaterialData({
    required this.name,
    required this.group,
    required this.kI,
    required this.kt,
    required this.kF,
    required this.minThickness,
    required this.maxThickness,
    required this.resistivity,
    required this.thermalConductivity,
    this.requirePreheat = false,
    this.requirePostHeat = false,
    this.defaultSlopeUp = 0,
    this.defaultSlopeDown = 0,
  });
}

class MaterialRepository {
  static final Map<String, MaterialData> _materials = {
    'АМг6': MaterialData(
      name: 'АМг6',
      group: 'aluminum',
      kI: 12.0,
      kt: 0.8,
      kF: 2.5,
      minThickness: 0.5,
      maxThickness: 4.0,
      resistivity: 0.058,
      thermalConductivity: 120,
      requirePreheat: true,
      requirePostHeat: true,
      defaultSlopeUp: 0.15,
      defaultSlopeDown: 0.08,
    ),
  };

  static MaterialData? getMaterial(String name) {
    return _materials[name];
  }

  static List<String> getMaterialNames() {
    return _materials.keys.toList();
  }
}