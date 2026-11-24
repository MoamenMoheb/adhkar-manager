import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/constants.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'screens/main_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  await SupabaseService.instance.init();
  await NotificationService.instance.init();

  runApp(const AdhkarApp());
}

class AdhkarApp extends StatelessWidget {
  const AdhkarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkTextTheme = GoogleFonts.ibmPlexSansArabicTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: const Color(0xFFF3F4F6),
      displayColor: const Color(0xFFF3F4F6),
    );

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: AppConstants.primary,
        scaffoldBackgroundColor: AppConstants.surfaceLight,
        textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(ThemeData.light().textTheme),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppConstants.surfaceDark,
        cardColor: AppConstants.cardDark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE5E7EB),
          secondary: Color(0xFF9CA3AF),
          surface: Color(0xFF161B22),
          onPrimary: Color(0xFF111827),
          onSecondary: Color(0xFF111827),
          onSurface: Color(0xFFF3F4F6),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.surfaceDark,
          foregroundColor: Color(0xFFF3F4F6),
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppConstants.cardDark,
          indicatorColor: Colors.white.withOpacity(0.14),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            final selected = states.contains(MaterialState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? const Color(0xFFF3F4F6) : const Color(0xFF9CA3AF),
            );
          }),
        ),
        textTheme: darkTextTheme,
      ),
      home: const MainShell(),
    );
  }
}
