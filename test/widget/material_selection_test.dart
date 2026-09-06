/// test/widget/material_selection_test.dart
/// Проверка поведения при выборе материала

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rsw_svarcos/main.dart';

void main() {
  testWidgets('Выбор материала: при выборе Сталь 20 показывается SnackBar и выбор сбрасывается', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Проверяем, что по умолчанию выбран АМг6 (видим текст на экране)
    expect(find.text('АМг6'), findsOneWidget);

    // Открываем выпадающий список
    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    // Выбираем Сталь 20
    final steelOption = find.text('Сталь 20').last;
    await tester.tap(steelOption);
    await tester.pumpAndSettle();

    // Проверяем, что появился SnackBar
    expect(find.text('В текущей версии доступен только АМг6. Остальные материалы будут добавлены позже.'), findsOneWidget);

    // Проверяем, что выбор сбросился на АМг6 (текст снова виден)
    expect(find.text('АМг6'), findsOneWidget);
  });

  testWidgets('Выбор материала: при выборе 12Х18Н10Т показывается SnackBar и выбор сбрасывается', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('АМг6'), findsOneWidget);

    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    final steelOption = find.text('12Х18Н10Т').last;
    await tester.tap(steelOption);
    await tester.pumpAndSettle();

    expect(find.text('В текущей версии доступен только АМг6. Остальные материалы будут добавлены позже.'), findsOneWidget);
    expect(find.text('АМг6'), findsOneWidget);
  });
}