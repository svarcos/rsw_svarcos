// lib/data/models/cyclogram_point.dart

/// Точка на графике циклограммы
class CyclogramPoint {
  final double time; // Время в циклах
  final double current; // Ток в процентах (0-100)
  final double force; // Усилие в bar (0-10)
  final String stage; // Название этапа

  const CyclogramPoint({
    required this.time,
    required this.current,
    required this.force,
    required this.stage,
  });
}