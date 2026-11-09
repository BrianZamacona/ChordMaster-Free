import 'package:go_router/go_router.dart';

import '../core/widgets/app_scaffold.dart';
import '../data/models/scale_definition.dart';
import '../domain/lessons/curriculum.dart';
import '../features/achievements/achievements_screen.dart';
import '../features/capo/capo_screen.dart';
import '../features/challenges/multi_day_screen.dart';
import '../features/chords/chord_compare_screen.dart';
import '../features/chords/chord_detail_screen.dart';
import '../features/chords/chord_explorer_screen.dart';
import '../features/chords/chord_library_screen.dart';
import '../features/circle/circle_build_screen.dart';
import '../features/circle/circle_screen.dart';
import '../features/courses/course_registry.dart';
import '../features/courses/course_step_route.dart';
import '../features/ear_training/ear_training_screen.dart';
import '../features/finder/note_finder_screen.dart';
import '../features/guides/guide_detail_screen.dart';
import '../features/guides/guides_screen.dart';
import '../features/health/health_screen.dart';
import '../features/home/home_screen.dart';
import '../features/hubs/hubs.dart';
import '../features/lessons/lesson_detail_screen.dart';
import '../features/lessons/lesson_unit_screen.dart';
import '../features/lessons/lessons_screen.dart';
import '../features/licks/lick_detail_screen.dart';
import '../features/licks/licks_screen.dart';
import '../features/metronome/metronome_screen.dart';
import '../features/progressions/progressions_screen.dart';
import '../features/rhythm_games/rhythm_game_screen.dart';
import '../features/session/session_screen.dart';
import '../features/songs/song_detail_screen.dart';
import '../features/songs/songs_screen.dart';
import '../features/technique/technique_screen.dart';
import '../features/tuner/tuner_screen.dart';
import '../features/workouts/workouts_screen.dart';
import 'scales/detail/scale_detail_screen.dart';
import 'scales/double_stops/double_stops_screen.dart';
import 'scales/scales_screen.dart';

/// Rutas anteriores al rediseño de navegación → rutas actuales.
///
/// Se conservan porque Inicio guarda el último módulo visitado con la ruta
/// vieja y puede haber enlaces o notificaciones que la usen.
const legacyRoutePrefixes = {
  // Componer se fusionó con Progresiones ("Mi progresión").
  '/composition': '/learn/progressions',
  '/learn/composition': '/learn/progressions',
  '/ear-training': '/practice/ear-training',
  '/rhythm-game': '/practice/rhythm',
  '/songs': '/practice/songs',
  // Improvisación se fusionó con el detalle de cada escala.
  '/improvisation': '/learn/scales',
  '/practice/improvisation': '/learn/scales',
  '/achievements': '/progress/achievements',
  '/health': '/progress/health',
  '/community': '/progress',
  // Los cursos pasaron al mapa de Lecciones.
  '/learn/melodies': '/learn/lessons/course/melodies',
  '/learn/open-chords': '/learn/lessons/course/open-chords',
  '/learn/strumming': '/learn/lessons/course/strumming',
};

/// Ruta actual para [location], o `null` si no es una ruta vieja.
String? redirectLegacyRoute(String location) {
  for (final MapEntry(key: old, value: current) in legacyRoutePrefixes.entries) {
    if (location == old || location.startsWith('$old/') || location.startsWith('$old?')) {
      return current + location.substring(old.length);
    }
  }
  return null;
}

/// Afinador y metrónomo apilados sobre la pantalla que los abre (Inicio, una
/// lección o una guía): la flecha de atrás vuelve ahí. En la pestaña Afinar
/// son la raíz y no la tienen.
List<RouteBase> _toolRoutes() => [
      GoRoute(path: 'tuner', builder: (_, _) => const TunerScreen()),
      GoRoute(path: 'metronome', builder: (_, _) => const MetronomeScreen()),
    ];

/// Acordes, Escalas, Progresiones, Círculo de quintas y Licks: cuelgan de Aprender
/// (lecciones y guías los abren ahí) y de Inicio (sus accesos), con las
/// mismas pantallas. Su navegación interna usa `context.sectionPath`
/// para quedarse en la pestaña donde se abrió.
List<RouteBase> _moduleRoutes() => [
    GoRoute(
      path: 'licks',
      builder: (_, _) => const LicksScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, state) => LickDetailScreen(lickId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: 'circle',
      builder: (_, _) => const CircleScreen(),
      routes: [
        GoRoute(
          path: 'build',
          builder: (_, _) => const CircleBuildScreen(),
        ),
      ],
    ),
    GoRoute(
      path: 'chords',
      builder: (_, _) => const ChordLibraryScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, state) => ChordDetailScreen(
            chordId: state.pathParameters['id']!,
          ),
          routes: [
            GoRoute(
              path: 'explorer',
              builder: (_, state) => ChordExplorerScreen(
                chordId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: 'compare',
              builder: (_, state) => ChordCompareScreen(
                chordId: state.pathParameters['id']!,
                selection: state.uri.queryParameters['sel'],
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: 'scales',
      builder: (_, _) => const ScalesScreen(),
      routes: [
        GoRoute(
          path: 'double-stops',
          builder: (_, _) => const DoubleStopsScreen(),
        ),
        GoRoute(
          path: ':scaleId',
          builder: (_, state) => ScaleDetailScreen(
            scale: state.extra! as ScaleDefinition,
            initialRoot: int.tryParse(
                  state.uri.queryParameters['root'] ?? '',
                ) ??
                0,
            initialPosition: state.uri.queryParameters['position'],
          ),
        ),
      ],
    ),
    GoRoute(
      path: 'progressions',
      builder: (_, _) => const ProgressionsScreen(),
    ),
    ];

/// Router de ChordMaster Free.
///
/// Todas las pantallas viven dentro de un único [StatefulShellRoute] con cinco
/// pestañas (Inicio, Aprender, Practicar, Herramientas, Progreso), así la
/// barra inferior está siempre visible. Tocar una pestaña abre su pantalla
/// de inicio (no la última que se vio dentro de ella). Las
/// pantallas de una sección cuelgan de su hub, por eso el botón de atrás
/// automático vuelve a la pantalla anterior real.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) => redirectLegacyRoute(state.uri.toString()),
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppScaffold(
        body: shell,
        currentIndex: shell.currentIndex,
        onIndexChange: (index) => shell.goBranch(index, initialLocation: true),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const HomeScreen(),
              routes: [
                // Buscador por notas.
                GoRoute(
                  path: 'finder',
                  builder: (_, _) => const NoteFinderScreen(),
                ),
                // Resumen de la sesión de hoy (desde Práctica de hoy).
                GoRoute(
                  path: 'session',
                  builder: (_, _) => const SessionScreen(),
                ),
                // Los módulos que se abren desde Inicio viven también aquí, para
                // que atrás vuelva a Inicio sin cambiar de pestaña.
                ..._moduleRoutes(),
                ..._toolRoutes(),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/learn',
              builder: (_, _) => const LearnHubScreen(),
              routes: [
                GoRoute(
                  path: 'lessons',
                  builder: (_, _) => const LessonsScreen(),
                  routes: [
                    // Los cursos del mapa: su página es la de su unidad.
                    GoRoute(
                      path: 'course/:slug',
                      builder: (_, state) {
                        final course =
                            LessonCourseInfo.fromSlug(state.pathParameters['slug']!);
                        return LessonUnitScreen(
                          unitId: course == null ? '' : unitOfCourse(course).id,
                        );
                      },
                      routes: [
                        GoRoute(
                          path: ':stepId',
                          builder: (_, state) => CourseStepRouteScreen(
                            slug: state.pathParameters['slug']!,
                            stepId: state.pathParameters['stepId']!,
                          ),
                        ),
                      ],
                    ),
                    // Antes que ':id' para que "unit" no se lea como lección.
                    GoRoute(
                      path: 'unit/:unitId',
                      builder: (_, state) => LessonUnitScreen(
                        unitId: state.pathParameters['unitId']!,
                      ),
                    ),
                    GoRoute(
                      path: ':id',
                      builder: (_, state) => LessonDetailScreen(
                        lessonId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'guides',
                  builder: (_, _) => const GuidesScreen(),
                  routes: [
                    GoRoute(
                      path: ':guideId',
                      builder: (_, state) => GuideDetailScreen(
                        guideId: state.pathParameters['guideId']!,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'capo',
                  builder: (_, _) => const CapoScreen(),
                ),
                ..._moduleRoutes(),
                ..._toolRoutes(),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/practice',
              builder: (_, _) => const PracticeHubScreen(),
              routes: [
                GoRoute(
                  path: 'ear-training',
                  builder: (_, _) => const EarTrainingScreen(),
                ),
                GoRoute(
                  path: 'workouts',
                  builder: (_, state) => WorkoutsScreen(
                    scaleId: state.uri.queryParameters['scale'] ?? 'major',
                    root: int.tryParse(state.uri.queryParameters['root'] ?? '') ?? 0,
                  ),
                ),
                GoRoute(
                  path: 'challenges',
                  builder: (_, _) => const MultiDayChallengesScreen(),
                ),
                GoRoute(
                  path: 'technique',
                  builder: (_, _) => const TechniqueScreen(),
                ),
                GoRoute(
                  path: 'rhythm',
                  builder: (_, _) => const RhythmGameScreen(),
                ),
                GoRoute(
                  path: 'songs',
                  builder: (_, _) => const SongsScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (_, state) => SongDetailScreen(
                        songId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          initialLocation: '/tools/tuner',
          routes: [
            GoRoute(path: '/tools', redirect: (_, _) => '/tools/tuner'),
            GoRoute(
              path: '/tools/tuner',
              pageBuilder: (_, state) => NoTransitionPage(
                key: state.pageKey,
                child: const TunerScreen(),
              ),
            ),
            GoRoute(
              path: '/tools/metronome',
              pageBuilder: (_, state) => NoTransitionPage(
                key: state.pageKey,
                child: const MetronomeScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/progress',
              builder: (_, _) => const ProgressHubScreen(),
              routes: [
                GoRoute(
                  path: 'achievements',
                  builder: (_, _) => const AchievementsScreen(),
                ),
                GoRoute(
                  path: 'health',
                  builder: (_, _) => const HealthScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
