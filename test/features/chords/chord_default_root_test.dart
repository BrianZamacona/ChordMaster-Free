import 'package:chordmaster_free/features/chords/chord_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('abre en C; buscar quita la raíz por defecto; Limpiar vuelve a C', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final vm = container.read(chordViewModelProvider.notifier);
    while (container.read(chordViewModelProvider).isLoading) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    var s = container.read(chordViewModelProvider);
    expect(s.selectedRoot, 'C');
    expect(s.filteredChords, hasLength(24));
    expect(s.filteredChords.every((c) => c.root == 'C'), isTrue);

    vm.search('Bm7');
    s = container.read(chordViewModelProvider);
    expect(s.selectedRoot, isNull);
    expect(s.filteredChords.map((c) => c.root), contains('B'));

    vm.clearFilters();
    s = container.read(chordViewModelProvider);
    expect(s.selectedRoot, 'C');
    expect(s.searchQuery, isEmpty);

    // Una raíz elegida por el usuario se respeta al buscar.
    vm
      ..filterByRoot('E')
      ..search('m7');
    expect(container.read(chordViewModelProvider).selectedRoot, 'E');
  });
}
