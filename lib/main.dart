import 'package:befit_fitness_app/core/di/injection_container.dart';
import 'package:befit_fitness_app/core/routes/app_router.dart';
import 'package:befit_fitness_app/core/config/app_config.dart';
import 'package:befit_fitness_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/providers/language_provider.dart';
import 'src/home/data/services/meal_alarm_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await _initializeFirebaseServices();
  await SharedPreferences.getInstance();
  await initDependencyInjection();
  await getIt<MealAlarmService>().init();

  runApp(const MyApp());
}

Future<void> _initializeFirebaseServices() async {
  try {
    if (AppConfig.enableCrashReporting) {}
    if (AppConfig.enableAnalytics) {}
  } catch (_) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ChangeNotifierProvider(
          create: (context) => LanguageProvider(),
          child: Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return MaterialApp.router(
                title: 'BeFit Fitness App',
                debugShowCheckedModeBanner: false,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en', ''),
                  Locale('es', ''),
                ],
                locale: languageProvider.locale,
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                  useMaterial3: true,
                ),
                routerConfig: AppRouter.router,
              );
            },
          ),
        );
      },
    );
  }
}