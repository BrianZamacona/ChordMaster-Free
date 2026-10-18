import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La app no se conecta a internet (la política de privacidad lo afirma):
  // google_fonts solo usa las fuentes de assets/google_fonts, nunca descarga.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Fuentes empaquetadas: se cargan antes del primer frame para que los
  // diagramas (CustomPainter) no se pinten con la fuente de respaldo.
  await GoogleFonts.pendingFonts([
    darkTheme.textTheme.titleLarge,
    lightTheme.textTheme.bodyMedium,
    musicMono(),
    musicMono(fontWeight: FontWeight.w600),
  ]);
  await Hive.initFlutter();
  final storage = StorageService();
  await storage.openBoxes();
  await NotificationService.instance.initialize();
  runApp(const ProviderScope(child: ChordMasterApp()));
}
