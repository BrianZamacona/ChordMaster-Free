import 'package:chordmaster_free/services/achievement_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

void main() {
  test('cada logro se puede conseguir: ninguno de un módulo que ya no existe', () {
    expect(
      AchievementService.allAchievements.map((a) => a.id),
      unorderedEquals([
        'first_chord',
        'tuned_up',
        'seven_day_streak',
        'scale_explorer',
        'rhythm_master',
        'ear_wizard',
        'composer',
        'health_conscious',
        'song_learner',
        'foundations_done',
      ]),
    );
  });

  test('recordDistinct cuenta valores distintos y persiste la lista', () async {
    final storage = InMemoryStore();
    Future<int> view(String id) => AchievementService(storage).recordDistinct(
          key: 'viewed_scale_ids',
          value: id,
          goal: 10,
          achievementId: 'scale_explorer',
        );
    expect(await view('major'), 1);
    expect(await view('major'), 1); // repetida no cuenta
    expect(await view('dorian'), 2);
    expect(storage.progress['viewed_scale_ids'], unorderedEquals(['major', 'dorian']));
  });

  test('unlock guarda la fecha en la caja de logros, una sola vez', () async {
    final storage = InMemoryStore();
    final service = AchievementService(storage);

    await service.unlock('tuned_up');
    final first = storage.achievements['tuned_up'];
    await service.unlock('tuned_up');
    await service.unlock('no_existe');

    expect(first, isA<String>());
    expect(storage.achievements['tuned_up'], first);
    expect(await service.unlockedTimestamps(), {'tuned_up': first});
    expect(await service.getUnlocked(), ['tuned_up']);
  });
}
