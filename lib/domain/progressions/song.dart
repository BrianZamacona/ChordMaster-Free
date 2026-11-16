/// Canción de "Mi progresión" (decisión del usuario tras revisar Pocket
/// Composer): hasta [songMaxSections] secciones (A, B, C, D), cada una con sus
/// acordes y duraciones, y el orden en que se tocan, hasta [songMaxParts]
/// partes (A A B A). La teoría y los diagramas siguen a la sección que se
/// edita; la canción entera solo se escucha.
library;

/// Secciones como mucho: A, B, C y D.
const songMaxSections = 4;

/// Partes del orden como mucho.
const songMaxParts = 8;

/// La letra de la sección [index] (0 = A).
String sectionLetter(int index) => String.fromCharCode(0x41 + index);

/// El orden escrito con letras: «A A B A».
String songOrderLabel(List<int> order) => [for (final s in order) sectionLetter(s)].join(' ');

/// Cada acorde de la canción en el orden en que suena: la parte del orden, su
/// sección y el acorde dentro de ella. [sectionLengths] = acordes de cada
/// sección; una sección vacía no suena.
List<({int part, int section, int chord})> songTimeline(List<int> sectionLengths, List<int> order) => [
  for (final (part, section) in order.indexed)
    if (section >= 0 && section < sectionLengths.length)
      for (var chord = 0; chord < sectionLengths[section]; chord++) (part: part, section: section, chord: chord),
];

/// El orden sin la sección [removed]: sus partes se van y las de las
/// secciones de después bajan una letra. Si se queda vacío, vuelve a «A».
List<int> orderWithoutSection(List<int> order, int removed) {
  final next = [
    for (final s in order)
      if (s < removed) s else if (s > removed) s - 1,
  ];
  return next.isEmpty ? const [0] : next;
}
