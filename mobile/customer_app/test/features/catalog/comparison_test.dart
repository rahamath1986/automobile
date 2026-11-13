import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motosaas_customer/features/catalog/application/catalog_controllers.dart';

import 'fixtures.dart';

void main() {
  group('ComparisonController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('starts empty and adds up to three variants', () {
      final controller = container.read(comparisonControllerProvider.notifier);
      controller.toggle(modelFixture('a'), variantFixture('v1'));
      controller.toggle(modelFixture('b'), variantFixture('v2'));
      controller.toggle(modelFixture('c'), variantFixture('v3'));

      expect(container.read(comparisonControllerProvider), hasLength(3));
    });

    test('rejects a fourth variant', () {
      final controller = container.read(comparisonControllerProvider.notifier);
      controller.toggle(modelFixture('a'), variantFixture('v1'));
      controller.toggle(modelFixture('b'), variantFixture('v2'));
      controller.toggle(modelFixture('c'), variantFixture('v3'));

      final added = controller.toggle(modelFixture('d'), variantFixture('v4'));

      expect(added, isFalse);
      expect(container.read(comparisonControllerProvider), hasLength(3));
    });

    test('toggling an existing variant removes it', () {
      final controller = container.read(comparisonControllerProvider.notifier);
      controller.toggle(modelFixture('a'), variantFixture('v1'));

      final result = controller.toggle(modelFixture('a'), variantFixture('v1'));

      expect(result, isTrue);
      expect(container.read(comparisonControllerProvider), isEmpty);
    });

    test('remove and clear update the comparison tray', () {
      final controller = container.read(comparisonControllerProvider.notifier);
      controller.toggle(modelFixture('a'), variantFixture('v1'));
      controller.toggle(modelFixture('b'), variantFixture('v2'));

      controller.remove('v1');
      expect(container.read(comparisonControllerProvider).map((item) => item.key), ['v2']);

      controller.clear();
      expect(container.read(comparisonControllerProvider), isEmpty);
    });
  });

  group('CatalogFilter', () {
    test('filters by category and search query', () {
      const filter = CatalogFilter(category: CatalogCategory.electric, query: 'iqube');
      final results = filter.apply([
        modelFixture('a', name: 'R15 V4', category: 'MOTORCYCLE', fuelType: 'PETROL'),
        modelFixture('b', name: 'iQube', category: 'ELECTRICVEHICLE', fuelType: 'ELECTRIC'),
      ]);

      expect(results, hasLength(1));
      expect(results.first.name, 'iQube');
    });
  });
}
