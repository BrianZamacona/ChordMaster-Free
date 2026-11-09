/// Una guía por estilo de Licks y riffs (fila "Estilos"). Se arman desde la
/// biblioteca, que es la fuente única: la guía no trae trastes, enlaza el
/// riff, el lick y la escala del estilo, y sus textos son los de cada frase.
library;

import '../../core/i18n/tr.dart';
import '../lessons/lesson.dart';
import '../licks/lick.dart';
import '../licks/licks.dart';
import 'guides.dart';

/// Id de la guía de [style] (permanente: guarda el avance).
String styleGuideId(LickStyle style) => 'style_${style.name}';

/// Las guías de estilo, en el orden de [LickStyle].
final List<Guide> styleGuides = [for (final style in LickStyle.values) _guideFor(style)];

Guide _guideFor(LickStyle style) {
  final info = lickStyleInfo(style);
  final mine = [for (final l in licks) if (l.style == style) l];
  final riff = mine.firstWhere((l) => l.kind == LickKind.riff);
  final lick = mine.firstWhere((l) => l.kind == LickKind.lick);
  return Guide(
    id: styleGuideId(style),
    category: GuideCategory.styles,
    // Para quien ya toca la frase más difícil del estilo.
    level: mine.map((l) => l.level).reduce((a, b) => a.index >= b.index ? a : b),
    title: info.title,
    subtitle: info.summary,
    art: ScaleArt(riff.scale),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'El riff: ${riff.title.es}', en: 'The riff: ${riff.title.en}'),
        body: riff.about,
        target: LickLink(riff.id),
      ),
      GuideChapter(
        title: LocalizedText(es: 'El lick: ${lick.title.es}', en: 'The lick: ${lick.title.en}'),
        body: lick.about,
        target: LickLink(lick.id),
      ),
      GuideChapter(
        title: const LocalizedText(es: 'La escala', en: 'The scale'),
        body: const LocalizedText(
          es: 'El riff y el lick salen de esta escala: mírala en el diapasón y tócala antes de las frases.',
          en: 'The riff and the lick come from this scale: look at it on the fretboard and play it before the phrases.',
        ),
        target: ScaleLink(riff.scale),
      ),
    ],
  );
}
