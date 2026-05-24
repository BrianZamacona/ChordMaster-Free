class NoteCoordinate {
  const NoteCoordinate({
    required this.string,
    required this.fret,
    required this.isRoot,
    this.note = '',
    this.interval = '',
    this.finger,
  });

  /// String number: 1 = low E, 6 = high e.
  final int string;

  /// Absolute fret number (0 = open string).
  final int fret;

  /// true if this note is the tonic/root.
  final bool isRoot;

  /// Note name: "C", "D#", "A#", etc.
  final String note;

  /// Interval name: "1", "b3", "5", "b7", etc.
  final String interval;

  /// Suggested fretting finger (1=index … 4=pinky). null if not specified.
  final int? finger;

  factory NoteCoordinate.fromJson(Map<String, dynamic> json) {
    final stringNum = (json['string'] as num?)?.toInt();
    final fret = (json['fret'] as num?)?.toInt();

    if (stringNum == null || stringNum < 1 || stringNum > 6) {
      throw const FormatException('string must be 1..6');
    }
    if (fret == null || fret < 0 || fret > 24) {
      throw const FormatException('fret must be 0..24');
    }

    final finger = (json['finger'] as num?)?.toInt();
    if (finger != null && (finger < 1 || finger > 4)) {
      throw const FormatException('finger must be 1..4');
    }

    return NoteCoordinate(
      string: stringNum,
      fret: fret,
      isRoot: json['is_root'] as bool? ?? false,
      note: json['note'] as String? ?? '',
      interval: json['interval'] as String? ?? '',
      finger: finger,
    );
  }

  Map<String, dynamic> toJson() => {
        'string': string,
        'fret': fret,
        'is_root': isRoot,
        if (note.isNotEmpty) 'note': note,
        if (interval.isNotEmpty) 'interval': interval,
        if (finger != null) 'finger': finger,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteCoordinate && other.string == string && other.fret == fret;

  @override
  int get hashCode => Object.hash(string, fret);

  @override
  String toString() =>
      'NoteCoordinate(s:$string f:$fret note:$note interval:$interval root:$isRoot)';
}
