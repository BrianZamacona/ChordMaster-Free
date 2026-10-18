import 'package:chordmaster_free/services/achievement_service.dart';
import 'package:chordmaster_free/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage implements StorageService {
  final data = <String, dynamic>{};

  @override
  Future<void> openBoxes() async {}

  @override
  Future<void> save(String box, String key, dynamic value) async => data[key] = value;

  @override
  Future<T?> get<T>(String box, String key) async {
    final value = data[key];
    return value is T ? value : null;
  }

  @override
  Future<List<dynamic>> getAll(String box) async => data.values.toList();

  @override
  Future<void> delete(String box, String key) async => data.remove(key);

  @override
  Future<void> clear(String box) async => data.clear();
}

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
      ]),
    );
  });

  test('recordDistinct cuenta valores distintos y persiste la lista', () async {
    final storage = _MemoryStorage();
    Future<int> view(String id) => AchievementService.instance.recordDistinct(
          storage: storage,
          key: 'viewed_scale_ids',
          value: id,
          goal: 10,
          achievementId: 'scale_explorer',
        );
    expect(await view('major'), 1);
    expect(await view('major'), 1); // repetida no cuenta
    expect(await view('dorian'), 2);
    expect(storage.data['viewed_scale_ids'], unorderedEquals(['major', 'dorian']));
  });
}
