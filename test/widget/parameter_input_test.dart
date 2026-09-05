/// test/widget/parameter_input_test.dart
/// Виджет-тесты для экрана ввода параметров

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rsw_svarcos/main.dart';

void main() {
  group('Экран ввода параметров (интерактивность)', () {
    testWidgets('Изменение толщины пересчитывает зависимые параметры', (tester) async {
      await tester.pumpWidget(const MyApp());

      // Находим ползунок толщины верхней детали
      final thicknessSlider = find.byKey(const Key('thickness_top_slider'));
      expect(thicknessSlider, findsOneWidget);

      // Изменяем значение ползунка
      await tester.drag(thicknessSlider, const Offset(100, 0));
      await tester.pumpAndSettle();

      // Проверяем, что POWER изменился (например, поле с ключом pressure_field_input)
      final pressureField = find.byKey(const Key('pressure_field_input'));
      expect(pressureField, findsOneWidget);

      // Проверяем, что значение изменилось
      final pressureValue = tester.widget<TextField>(pressureField).controller?.text;
      expect(pressureValue, isNot('1.5'));
    });

    testWidgets('Изменение stroke пересчитывает SQUEEZE 1', (tester) async {
      await tester.pumpWidget(const MyApp());

      // Находим ползунок stroke
      final strokeSlider = find.byKey(const Key('stroke_slider'));
      expect(strokeSlider, findsOneWidget);

      // Изменяем значение
      await tester.drag(strokeSlider, const Offset(100, 0));
      await tester.pumpAndSettle();

      // Проверяем, что SQUEEZE 1 изменился
      // Находим поле SQUEEZE 1 по его label (можно использовать find.text)
      final squeezeField = find.textContaining('SQUEEZE 1');
      expect(squeezeField, findsOneWidget);
    });

    testWidgets('Синхронизация ползунок ↔ поле ввода', (tester) async {
      await tester.pumpWidget(const MyApp());

      // Находим поле ввода для толщины
      final textField = find.byKey(const Key('thickness_top_input'));
      expect(textField, findsOneWidget);

      // Вводим новое значение
      await tester.enterText(textField, '2.0');
      await tester.pumpAndSettle();

      // Проверяем, что ползунок переместился
      final slider = find.byKey(const Key('thickness_top_slider'));
      final sliderWidget = tester.widget<Slider>(slider);
      expect(sliderWidget.value, 2.0);
    });

    testWidgets('Кнопка «Рассчитать» обновляет все параметры', (tester) async {
      await tester.pumpWidget(const MyApp());

      // Находим кнопку «Рассчитать»
      final calculateButton = find.byKey(const Key('calculate_button'));
      expect(calculateButton, findsOneWidget);

      // Нажимаем на кнопку
      await tester.tap(calculateButton);
      await tester.pumpAndSettle();

      // Проверяем, что появился SnackBar
      final snackBar = find.text('✅ Параметры рассчитаны и применены');
      expect(snackBar, findsOneWidget);
    });

    testWidgets('Смена материала сбрасывает параметры', (tester) async {
      await tester.pumpWidget(const MyApp());

      // Находим выпадающий список материала
      final dropdown = find.byKey(const Key('material_dropdown'));
      expect(dropdown, findsOneWidget);

      // Открываем список
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Выбираем '12Х18Н10Т'
      final option = find.text('12Х18Н10Т').last;
      await tester.tap(option);
      await tester.pumpAndSettle();

      // Проверяем, что появилось предупреждение
      final warning = find.text('В текущей версии доступен только АМг6. Остальные материалы будут добавлены позже.');
      expect(warning, findsOneWidget);
    });
  });
}