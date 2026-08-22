/// Справочник материалов для расчёта параметров точечной сварки
/// Данные по ГОСТ 15878-79 и отраслевым нормалям
///
/// Хранит табличные значения для POWER, WELD, tForge (время ковки).
/// Для промежуточных толщин используется линейная интерполяция.
/// Диапазон толщин: 0.5 – 3.0 мм (шаг 0.1 мм)

class MaterialRepository {
  static final List<Map<String, double>> _table = [
    {'thickness': 0.5, 'power': 6.0, 'weld': 2.5, 'forge': 0.0},
    {'thickness': 0.8, 'power': 9.1, 'weld': 3.5, 'forge': 4.0},
    {'thickness': 1.0, 'power': 14.2, 'weld': 4.5, 'forge': 4.5},
    {'thickness': 1.5, 'power': 19.7, 'weld': 6.0, 'forge': 7.0},
    {'thickness': 2.0, 'power': 27.9, 'weld': 7.5, 'forge': 8.0},
    {'thickness': 2.5, 'power': 37.6, 'weld': 9.5, 'forge': 10.0},
    {'thickness': 3.0, 'power': 43.6, 'weld': 11.5, 'forge': 12.0},
  ];

  static (double power, double weld, double forge) interpolate(double thickness) {
    // Если толщина меньше минимальной — берём первую точку
    if (thickness <= _table.first['thickness']!) {
      final first = _table.first;
      return (first['power']!, first['weld']!, first['forge']!);
    }

    // Если толщина больше максимальной — берём последнюю точку
    if (thickness >= _table.last['thickness']!) {
      final last = _table.last;
      return (last['power']!, last['weld']!, last['forge']!);
    }

    // Находим соседние точки
    for (int i = 0; i < _table.length - 1; i++) {
      final x0 = _table[i]['thickness']!;
      final x1 = _table[i + 1]['thickness']!;

      if (thickness >= x0 && thickness <= x1) {
        final y0power = _table[i]['power']!;
        final y1power = _table[i + 1]['power']!;
        final y0weld = _table[i]['weld']!;
        final y1weld = _table[i + 1]['weld']!;
        final y0forge = _table[i]['forge']!;
        final y1forge = _table[i + 1]['forge']!;

        final power = y0power + (y1power - y0power) * (thickness - x0) / (x1 - x0);
        final weld = y0weld + (y1weld - y0weld) * (thickness - x0) / (x1 - x0);
        double forge = y0forge + (y1forge - y0forge) * (thickness - x0) / (x1 - x0);

        // Если толщина < 0.8, ковка отсутствует
        if (thickness < 0.8) {
          forge = 0.0;
        }

        return (power, weld, forge);
      }
    }

    // Защита от ошибок
    final last = _table.last;
    return (last['power']!, last['weld']!, last['forge']!);
  }

  static List<String> getAvailableMaterials() {
    return ['АМг6'];
  }
}