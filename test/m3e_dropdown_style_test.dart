import 'package:material_ui/material_ui.dart' as mui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3e_dropdown_menu/m3e_dropdown_menu.dart';

void main() {
  testWidgets('M3EDropdownMenu renders and selects item', (tester) async {
    final fruitItems = [
      const M3EDropdownItem<String>(
        value: 'apple',
        label: 'Apple',
        selected: true,
      ),
      const M3EDropdownItem<String>(value: 'banana', label: 'Banana'),
      const M3EDropdownItem<String>(value: 'orange', label: 'Orange'),
    ];

    String? selectedVal = 'apple';

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
          mui.DefaultMaterialLocalizations.delegate,
        ],
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 250,
              child: M3EDropdownMenu<String>(
                items: fruitItems,
                singleSelect: true,
                searchEnabled: false,
                showChipAnimation: false,
                maxSelections: 3,
                enabled: true,
                containerRadius: 10.0,
                haptic: M3EHapticFeedback.light,
                openMotion: M3EMotion.custom(stiffness: 500.0, damping: 0.8),
                closeMotion: M3EMotion.custom(stiffness: 500.0, damping: 0.8),
                fieldStyle: const M3EDropdownFieldStyle(
                  hintText: '',
                  showClearIcon: false,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 7.0,
                  ),
                  margin: EdgeInsets.zero,
                  selectedTextStyle: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                  hintStyle: TextStyle(fontSize: 12.0),
                  pressedScale: 0.98,
                ),
                dropdownStyle: const M3EDropdownStyle(
                  elevation: 3.0,
                  maxHeight: 280.0,
                  marginTop: 4.0,
                  expandDirection: ExpandDirection.auto,
                  contentPadding: EdgeInsets.all(4.0),
                  containerRadius: 10.0,
                ),
                searchStyle: const M3ESearchStyle(
                  hintText: '',
                  filled: false,
                  autofocus: false,
                  showClearIcon: true,
                  searchDebounceMs: 0,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 6.0,
                  ),
                ),
                chipStyle: M3EChipStyle(
                  borderRadius: BorderRadius.circular(8.0),
                  spacing: 4.0,
                  runSpacing: 4.0,
                  wrap: true,
                  maxDisplayCount: 3,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 2.0,
                  ),
                  openMotion: M3EMotion.custom(stiffness: 500.0, damping: 0.8),
                  closeMotion: M3EMotion.custom(stiffness: 500.0, damping: 0.8),
                  pressedScale: 0.98,
                ),
                itemStyle: const M3EDropdownItemStyle(
                  outerRadius: 8.0,
                  innerRadius: 4.0,
                  itemGap: 2.0,
                  itemPadding: EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 7.0,
                  ),
                  textStyle: TextStyle(fontSize: 12.0),
                  selectedTextStyle: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                  ),
                  pressedScale: 0.98,
                  selectedIcon: Icon(Icons.check_rounded, size: 16.0),
                ),
                closeOnBackButton: false,
                onSelectionChanged: (items) {
                  if (items.isNotEmpty) {
                    selectedVal = items.first.value;
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Apple'), findsWidgets);

    // Tap to open dropdown
    await tester.tap(find.text('Apple').first);
    await tester.pumpAndSettle();

    // Tap banana
    expect(find.text('Banana'), findsOneWidget);
    await tester.tap(find.text('Banana'));
    await tester.pumpAndSettle();

    expect(selectedVal, 'banana');
  });

    testWidgets('M3EDropdownMenu renders search bar when searchEnabled is true', (tester) async {
    final fontItems = [
      const M3EDropdownItem<String>(value: 'Inter', label: 'Inter', selected: true),
      const M3EDropdownItem<String>(value: 'Roboto', label: 'Roboto'),
      const M3EDropdownItem<String>(value: 'Outfit', label: 'Outfit'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
          mui.DefaultMaterialLocalizations.delegate,
        ],
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 250,
              child: M3EDropdownMenu<String>(
                items: fontItems,
                singleSelect: true,
                searchEnabled: true,
                showChipAnimation: false,
                containerRadius: 100.0,
                haptic: M3EHapticFeedback.light,
                openMotion: M3EMotion.custom(stiffness: 500.0, damping: 0.8),
                closeMotion: M3EMotion.custom(stiffness: 500.0, damping: 0.8),
                fieldStyle: const M3EDropdownFieldStyle(
                  hintText: 'Select font',
                  showClearIcon: false,
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
                ),
                dropdownStyle: const M3EDropdownStyle(
                  elevation: 3.0,
                  maxHeight: 280.0,
                  marginTop: 4.0,
                  expandDirection: ExpandDirection.auto,
                  contentPadding: EdgeInsets.all(6.0),
                  containerRadius: 18.0,
                ),
                searchStyle: const M3ESearchStyle(
                  hintText: 'Search fonts…',
                  borderRadius: BorderRadius.all(Radius.circular(100.0)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
                ),
                itemStyle: const M3EDropdownItemStyle(
                  outerRadius: 12.0,
                  innerRadius: 6.0,
                  itemGap: 2.0,
                  itemPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
                closeOnBackButton: false,
                onSelectionChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Inter').first);
    await tester.pumpAndSettle();

    expect(find.text('Search fonts…'), findsOneWidget);
    expect(find.text('Roboto'), findsOneWidget);
  });
}