class NoteCoordinate {
  const NoteCoordinate({
    required this.string,
    required this.fret,
    required this.isRoot,
    this.note = '',
    this.interval = '',
    this.finger,
  });

  final int string;
  final int fret;
  final bool isRoot;
  final String note;
  final String interval;
  final int? finger;

  factory NoteCoordinate.fromJson(Map<String, dynamic> json) => NoteCoordinate(
    string:   (json['string'] as num).toInt(),
    fret:     (json['fret']   as num).toInt(),
    isRoot:   json['is_root'] as bool? ?? false,
    note:     json['note']     as String? ?? '',
    interval: json['interval'] as String? ?? '',
    finger:   (json['finger'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'string': string, 'fret': fret, 'is_root': isRoot,
    if (note.isNotEmpty)     'note': note,
    if (interval.isNotEmpty) 'interval': interval,
    if (finger != null)      'finger': finger,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteCoordinate && other.string == string && other.fret == fret;

  @override
  int get hashCode => Object.hash(string, fret);
}
